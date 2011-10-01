
import json
import logging
import datetime
import traceback
import tempfile
import binascii
import os
from uuid import UUID

from .include.smbfields import *
from .rpcservices import __shares__
from .include.packet import Raw

from evnet import later, listenplain, connectplain
from evnet.promise import Promise

smblog = logging.getLogger('SMB')
smblog.setLevel(logging.CRITICAL)

MAX_BUF = 16000

STATE_START = 0
STATE_SESSIONSETUP = 1
STATE_TREECONNECT = 2
STATE_NTCREATE = 3
STATE_NTWRITE = 4
STATE_NTREAD = 5

registered_services = {}

def register_rpc_service(service):
	uuid = service.uuid
	global registered_calls
	registered_services[uuid] = service


class mbconn(object):
	def __init__(self, conn, addr, srv):
                self.conn = conn
                self.addr = addr
                self.srv = srv
		self.state = {
			'lastcmd': None,
			'readcount': 0,
			'stop': False,
		}
		self.buf = b''
		self.outbuf = None
		self.fids = {}
		self.printer = b'' # spoolss file "queue"

		conn._on('read', self.io_in)
		conn._on('close', self.closed)

	def send(self, data):
		self.conn.write(data)

	def io_in(self, data):
		try:
			p = NBTSession(data, _ctx=self)
		except:
			t = traceback.format_exc()
			smblog.critical(t)
			return len(data)

		if len(data) < (p.LENGTH+4):
			#we probably do not have the whole packet yet -> return 0
			smblog.critical('=== SMB did not get enough data')
			return 0

		if p.TYPE == 0x81:
			self.send(NBTSession(TYPE=0x82).build())
			return len(data)
		elif p.TYPE != 0:
			# we currently do not handle anything else
			return len(data)

		if p.haslayer(SMB_Header) and p[SMB_Header].Start != b'\xffSMB':
			# not really SMB Header -> bail out
			smblog.critical('=== not really SMB')
			self.close()
			return len(data)

		p.show()
		r = None

		# this is one of the things you have to love, it violates the spec, but has to work ...
		if p.haslayer(SMB_Sessionsetup_ESEC_AndX_Request) and p.getlayer(SMB_Sessionsetup_ESEC_AndX_Request).WordCount == 13: 
			smblog.debug("recoding session setup request!")
			p.getlayer(SMB_Header).decode_payload_as(SMB_Sessionsetup_AndX_Request2) 
			x = p.getlayer(SMB_Sessionsetup_AndX_Request2)
			x.show()

		try:
			r = self.process(p)
		except:
			traceback.print_exc()

		smblog.debug('packet: {0}'.format(p.summary()))

		if p.haslayer(Raw):
			smblog.warning('p.haslayer(Raw): {0}'.format(p.getlayer(Raw).build()))
			p.show()

		if self.state['stop']:
			smblog.info("faint death.")
			return len(data)

		if r != None:
			smblog.debug('response: {0}'.format(r.summary()))
			r.show()

			self.send(r.build())

		if p.haslayer(Raw):
			smblog.warning('p.haslayer(Raw): {0}'.format(p.getlayer(Raw).build()))
			p.show()
			# some rest seems to be not parsed correctly
			# could be start of some other packet, junk, or failed packet dissection
			# TODO: recover from this...
			return len(data) - len(p.getlayer(Raw).load)

		return len(data)

	def process(self, p):
		r = ''
		rp = None
#		self.state['readcount'] = 0
		#if self.state == STATE_START and p.getlayer(SMB_Header).Command == 0x72:
		rstatus = 0
		smbh = p.getlayer(SMB_Header)
		Command = smbh.Command
		if Command == SMB_COM_NEGOTIATE:
			# Negociate Protocol -> Send response that supports minimal features in NT LM 0.12 dialect
			# (could be randomized later to avoid detection - but we need more dialects/options support)
			r = SMB_Negociate_Protocol_Response()
			# we have to select dialect
			c = 0
			tmp = p.getlayer(SMB_Negociate_Protocol_Request_Counts)
			while c < len(tmp.Requests):
				request = tmp.Requests[c]
				if request.BufferData.decode('ascii').find('NT LM 0.12') != -1:
					break
				c += 1

			r.DialectIndex = c

			r.Capabilities = r.Capabilities & ~CAP_EXTENDED_SECURITY
			r.KeyLength = 8
			r.EncryptionKey = 'DEADBEEFDEADBEEF'.decode('hex')
			#if not p.Flags2 & SMB_FLAGS2_EXT_SEC:
		#		r.Capabilities = r.Capabilities & ~CAP_EXTENDED_SECURITY

		#elif self.state == STATE_SESSIONSETUP and p.getlayer(SMB_Header).Command == 0x73:
		elif Command == SMB_COM_SESSION_SETUP_ANDX:
			if p.haslayer(SMB_Sessionsetup_ESEC_AndX_Request):
				r = SMB_Sessionsetup_ESEC_AndX_Response()
				ntlmssp = None
				sb = p.getlayer(SMB_Sessionsetup_ESEC_AndX_Request).SecurityBlob
				smblog.debug('securityblob ' + sb)
			elif p.haslayer(SMB_Sessionsetup_AndX_Request2):
				r = SMB_Sessionsetup_AndX_Response2()
			else:
				smblog.warn("Unknown Session Setup Type used")

		elif Command == SMB_COM_TREE_CONNECT_ANDX:
			r = SMB_Treeconnect_AndX_Response()
			h = p.getlayer(SMB_Treeconnect_AndX_Request)
#			print ("Service : %s" % h.Path)
			
			# for SMB_Treeconnect_AndX_Request.Flags = 0x0008
			if h.Flags & 0x08:
				r = SMB_Treeconnect_AndX_Response_Extended()

			# get Path as ascii string 
			f,v = h.getfield_and_val('Path')
			Service = f.i2repr(h,v)

			# compile Service from the last part of path
			# remove \\
			if Service.startswith('\\\\'):
				Service = Service[1:] 
			Service = Service.split('\\')[-1]
			if Service and Service[-1] == '$':
				Service = Service[:-1]
			r.Service = Service + '\x00'
			
			# specific for NMAP smb-enum-shares.nse support
			if h.Path == b'nmap-share-test\0':
				r = SMB_Treeconnect_AndX_Response2()
				rstatus = 0xc00000cc #STATUS_BAD_NETWORK_NAME
			elif h.Path == b'ADMIN$\0' or h.Path == b'C$\0':
				r = SMB_Treeconnect_AndX_Response2()
				rstatus = 0xc0000022 #STATUS_ACCESS_DENIED
		elif Command == SMB_COM_TREE_DISCONNECT:
			r = SMB_Treedisconnect()
		elif Command == SMB_COM_CLOSE:
			r = p.getlayer(SMB_Close)
			if p.FID in self.fids and self.fids[p.FID] is not None:
				self.fids[p.FID].close()
				fileobj = self.fids[p.FID]
				# download complete, fileobj.name, self.remote.host, self
				rwthrwthgotfile(fileobj.name, self.conn.addr[0], self)
				self.fids[p.FID].unlink(self.fids[p.FID].name)
				del self.fids[p.FID]
		elif Command == SMB_COM_LOGOFF_ANDX:
			r = SMB_Logoff_AndX()
		elif Command == SMB_COM_NT_CREATE_ANDX:
			# FIXME return NT_STATUS_OBJECT_NAME_NOT_FOUND=0xc0000034
			# for writes on IPC$
			# this is used to distinguish between file shares and devices by nmap smb-enum-shares
			# requires mapping of TreeConnect ids to names/objects
			r = SMB_NTcreate_AndX_Response()
			h = p.getlayer(SMB_NTcreate_AndX_Request)
			r.FID = 0x4000
			while r.FID in self.fids:
				r.FID += 0x200
			if h.FileAttributes & (SMB_FA_HIDDEN|SMB_FA_SYSTEM|SMB_FA_ARCHIVE|SMB_FA_NORMAL):
				# if a normal file is requested, provide a file
				self.fids[r.FID] = tempfile.NamedTemporaryFile(delete=False, prefix="smb-", suffix=".tmp", dir='/tmp/')

				# get pretty filename
				f,v = h.getfield_and_val('Filename')
				filename = f.i2repr(h,v)
				for j in range(len(filename)):
					if filename[j] != '\\' and filename[j] != '/':
						break
				filename = filename[j:]

				# download offer, filename, self.remote.host, self
				smblog.info("OPEN FILE! %s" % filename)

			elif h.FileAttributes & SMB_FA_DIRECTORY:
				pass
			else:
				self.fids[r.FID] = None
		elif Command == SMB_COM_OPEN_ANDX:
			h = p.getlayer(SMB_Open_AndX_Request)
			r = SMB_Open_AndX_Response()
			r.FID = 0x4000
			while r.FID in self.fids:
				r.FID += 0x200
			
			self.fids[r.FID] = tempfile.NamedTemporaryFile(delete=False, prefix="smb-", suffix=".tmp", dir='/tmp/')

			# get pretty filename
			f,v = h.getfield_and_val('FileName')
			filename = f.i2repr(h,v)
			for j in range(len(filename)):
				if filename[j] != '\\' and filename[j] != '/':
					break
			filename = filename[j:]

			# download offer, filename, self.remote.host, self
			smblog.info("OPEN FILE! %s" % filename)

		elif Command == SMB_COM_ECHO:
			r = p.getlayer(SMB_Header).payload
		elif Command == SMB_COM_WRITE_ANDX:
			r = SMB_Write_AndX_Response()
			h = p.getlayer(SMB_Write_AndX_Request)
			r.CountLow = h.DataLenLow
			if h.FID in self.fids and self.fids[h.FID] is not None:
				smblog.warn("WRITE FILE!")
				self.fids[h.FID].write(h.Data)
			else:
				self.buf += h.Data
#				self.process_dcerpc_packet(p.getlayer(SMB_Write_AndX_Request).Data)
				if len(self.buf) >= 10:
					# we got the dcerpc header
					inpacket = DCERPC_Header(self.buf[:10])
					smblog.info("got header")
					inpacket = DCERPC_Header(self.buf)
					smblog.info("FragLen %i len(self.buf) %i" % (inpacket.FragLen, len(self.buf)))
					if inpacket.FragLen == len(self.buf):
						outpacket = self.process_dcerpc_packet(self.buf)
						if outpacket is not None:
							outpacket.show()
							self.outbuf = outpacket.build()
						self.buf = b''
		elif Command == SMB_COM_WRITE:
			h = p.getlayer(SMB_Write_Request)
			if h.FID in self.fids and self.fids[h.FID] is not None:
				smblog.warn("WRITE FILE!")
				self.fids[h.FID].write(h.Data)
			r = SMB_Write_Response(CountOfBytesWritten = h.CountOfBytesToWrite)
		elif Command == SMB_COM_READ_ANDX:
			r = SMB_Read_AndX_Response()
			h = p.getlayer(SMB_Read_AndX_Request)
			# self.outbuf should contain response buffer now
			if not self.outbuf:
				if self.state['stop']:
					smblog.debug('drop dead!')
				else:
					smblog.critical('dcerpc processing failed. bailing out.')
				return rp

			rdata = SMB_Data()
			outbuf = self.outbuf
			outbuflen = len(outbuf)
			smblog.info("MaxCountLow %i len(outbuf) %i readcount %i" %(h.MaxCountLow, outbuflen, self.state['readcount']) )
			if h.MaxCountLow < outbuflen-self.state['readcount']:
				rdata.ByteCount = h.MaxCountLow
				newreadcount = self.state['readcount']+h.MaxCountLow
			else:
				newreadcount = 0
				self.outbuf = None

			rdata.Bytes = outbuf[ self.state['readcount'] : self.state['readcount'] + h.MaxCountLow ]
			rdata.ByteCount = len(rdata.Bytes)+1
			r.DataLenLow = len(rdata.Bytes)
			smblog.info("readcount %i len(rdata.Bytes) %i" %(self.state['readcount'], len(rdata.Bytes)) )
			r /= rdata
			
			self.state['readcount'] = newreadcount

		elif Command == SMB_COM_TRANSACTION:
			h = p.getlayer(SMB_Trans_Request)
			r = SMB_Trans_Response()
			rdata = SMB_Data()

			TransactionName = h.TransactionName
			if type(TransactionName) == bytes:
				if smbh.Flags2 & SMB_FLAGS2_UNICODE:
					TransactionName = TransactionName.decode('utf-16')
				else:
					TransactionName = TransactionName.decode('latin1')

			if TransactionName[-1] == '\0':
				TransactionName = TransactionName[:-1]

#			print("'{}' == '{}' => {} {} {}".format(TransactionName, '\\PIPE\\',TransactionName == '\\PIPE\\', type(TransactionName) == type('\\PIPE\\'), len(TransactionName)) )


			if TransactionName == '\\PIPE\\LANMAN':
				# [MS-RAP].pdf - Remote Administration Protocol
				rapbuf = bytes(h.Param)
				rap = RAP_Request(rapbuf)
				rap.show()
				rout = RAP_Response()
				if rap.Opcode == RAP_OP_NETSHAREENUM:
					(InfoLevel,ReceiveBufferSize) = struct.unpack("<HH",rap.Params)
					print("InfoLevel {} ReceiveBufferSize {}".format(InfoLevel, ReceiveBufferSize) )
					if InfoLevel == 1:
						l = len(__shares__)
						rout.OutParams = struct.pack("<HH", l, l)
					rout.OutData = b""
					comments = []
					coff = 0
					for i in __shares__:
						rout.OutData += struct.pack("<13sxHHH", 
							i, # NetworkName
							# Pad
							__shares__[i]['type'] & 0xff, # Type
							coff + len(__shares__)*20, # RemarkOffsetLow
							0x0101) # RemarkOffsetHigh
						comments.append(__shares__[i]['comment'])
						coff += len(__shares__[i]['comment']) + 1
					rout.show()
				outpacket = rout
				self.outbuf = outpacket.build()
				dceplen = len(self.outbuf) + coff

				r.TotalParamCount = 8 # Status|Convert|Count|Available
				r.TotalDataCount = dceplen

				r.ParamCount = 8 # Status|Convert|Count|Available
				r.ParamOffset = 56

				r.DataCount = dceplen
				r.DataOffset = 64

				rdata.ByteCount = dceplen
				rdata.Bytes = self.outbuf + b''.join(c.encode('ascii') + b'\x00' for c in comments)


			elif TransactionName == '\\PIPE\\':
				if socket.htons(h.Setup[0]) == TRANS_NMPIPE_TRANSACT:
					outpacket = self.process_dcerpc_packet(p.getlayer(DCERPC_Header))
	
					if type(outpacket) == Promise:
						outpacket._when(self.delayed_rpc_response, p)
						return None

					if not outpacket:
						if self.state['stop']:
							smblog.debug('drop dead!')
						else:
							smblog.critical('dcerpc processing failed. bailing out.')
						return rp
					self.outbuf = outpacket.build()
					dceplen = len(self.outbuf)
					
					r.TotalDataCount = dceplen
					r.DataCount = dceplen
	
					rdata.ByteCount = dceplen
					rdata.Bytes = self.outbuf
			
			r /= rdata
		elif p.getlayer(SMB_Header).Command == SMB_COM_TRANSACTION2:
			r = SMB_Trans2_Response()
		elif Command == SMB_COM_DELETE:
			# specific for NMAP smb-enum-shares.nse support
			h = p.getlayer(SMB_Delete_Request)
			if h.FileName == b'nmap-test-file\0':
				r = SMB_Delete_Response()
		else:
			smblog.critical('...unknown SMB Command. bailing out.')
			p.show()

		if r != '' and r != None:
			smbh = SMB_Header(Status=rstatus)
			smbh.Command = r.smb_cmd
			smbh.Flags2 = p.getlayer(SMB_Header).Flags2
#			smbh.Flags2 = p.getlayer(SMB_Header).Flags2 & ~SMB_FLAGS2_EXT_SEC
			smbh.MID = p.getlayer(SMB_Header).MID
			smbh.PID = p.getlayer(SMB_Header).PID
			rp = NBTSession()/smbh/r

		if Command in SMB_Commands:
			self.state['lastcmd'] = SMB_Commands[p.getlayer(SMB_Header).Command]
		else:
			self.state['lastcmd'] = "UNKNOWN"
		return rp

	def delayed_rpc_response(self, outpacket, p):
		r = SMB_Trans_Response()
		rdata = SMB_Data()
		outbuf = outpacket.build()
		dceplen = len(self.outbuf)
		
		r.TotalDataCount = dceplen
		r.DataCount = dceplen

		rdata.ByteCount = dceplen
		rdata.Bytes = outbuf
		r /= rdata

		smbh = SMB_Header(Status=0)
		smbh.Command = r.smb_cmd
		smbh.Flags2 = p.getlayer(SMB_Header).Flags2
		smbh.MID = p.getlayer(SMB_Header).MID
		smbh.PID = p.getlayer(SMB_Header).PID
		rp = NBTSession()/smbh/r

		if p.getlayer(SMB_Header).Command in SMB_Commands:
			self.state['lastcmd'] = SMB_Commands[p.getlayer(SMB_Header).Command]
		else:
			self.state['lastcmd'] = "UNKNOWN"
		self.send(rp.build())

	def process_dcerpc_packet(self, buf):
		if not isinstance(buf, DCERPC_Header):
			smblog.debug("got buf, make DCERPC_Header")
			dcep = DCERPC_Header(buf)
		else:
			dcep = buf

		global registered_calls

		outbuf = None

		smblog.debug("data")
		try:
			dcep.show()
		except:
			return None
		if dcep.AuthLen > 0:
#			print(dcep.getlayer(Raw).underlayer.load)
#			dcep.getlayer(Raw).underlayer.decode_payload_as(DCERPC_Auth_Verfier) 
			dcep.show()

		if dcep.PacketType == 11: #bind
			outbuf = DCERPC_Header()/DCERPC_Bind_Ack()
			outbuf.CallID = dcep.CallID
			c = 0
			outbuf.CtxItems = [DCERPC_Ack_CtxItem() for i in range(len(dcep.CtxItems))]
			while c < len(dcep.CtxItems): #isinstance(tmp, DCERPC_CtxItem):
				tmp = dcep.CtxItems[c]
				ctxitem = outbuf.CtxItems[c]
				service_uuid = UUID(bytes_le=tmp.UUID)
				transfersyntax_uuid = UUID(bytes_le=tmp.TransferSyntax)
				ctxitem.TransferSyntax = tmp.TransferSyntax #[:16]
				ctxitem.TransferSyntaxVersion = tmp.TransferSyntaxVersion
				if str(transfersyntax_uuid) == '8a885d04-1ceb-11c9-9fe8-08002b104860':
					if service_uuid.hex in registered_services:
						service = registered_services[service_uuid.hex]
						smblog.info('Found a registered UUID (%s). Accepting Bind for %s' % (service_uuid , service.__class__.__name__))
						self.state['uuid'] = service_uuid.hex
						# Copy Transfer Syntax to CtxItem
						ctxitem.AckResult = 0
						ctxitem.AckReason = 0
					else:
						smblog.warn("Attempt to register %s failed, UUID does not exist or is not implemented" % service_uuid)
				else:
					smblog.warn("Attempt to register %s failed, TransferSyntax %s is unknown" % (service_uuid, transfersyntax_uuid) )
				# dcerpc bind, self, str(service_uuid), str(transfersyntax_uuid)
				c += 1
			outbuf.NumCtxItems = c
			outbuf.FragLen = len(outbuf.build())
			smblog.debug("dce reply")
			outbuf.show()
		elif dcep.PacketType == 0: #request
			resp = None
			if 'uuid' in self.state:
				service = registered_services[self.state['uuid']]
				resp = service.processrequest(service, self, dcep.OpNum, dcep)
				# dcerpc request, self, str(UUID(bytes=bytes.fromhex(self.state['uuid']))), dcep.OpNum
			else:
				smblog.info("DCERPC Request without pending action")
				service = registered_services[UUID('4b324fc8-1670-01d3-1278-5a47bf6ee188').hex]
				resp = service.processrequest(service, self, dcep.OpNum, dcep)
			if not resp:
				self.state['stop'] = True
			outbuf = resp
		else:
			# unknown DCERPC packet -> logcrit and bail out.
			smblog.critical('unknown DCERPC packet. bailing out.')
		return outbuf

	def closed(self, e):
		for i in self.fids:
			if self.fids[i] is not None:
				self.fids[i].close()
				self.fids[i].unlink(self.fids[i].name)
		return 0

class server(object):
	def __init__(self, ip='0.0.0.0', port=80):
		self.store = None
		self.listener = listenplain(host=ip, port=port)
		self.listener._on('close', self._lclose)
		self.listener._on('connection', self._newconn)
		self.connections = set()

	def _newconn(self, c, addr):
		smblog.debug('Connection from {0}.'.format(addr))
		tc = mbconn(c, addr, self)
		self.connections.add(tc)
		def connclosed(e):
			self.connections.remove(tc)
		c._on('close', connclosed)

	def _lclose(self, e):
		smblog.critical('Listener closed ({0}). Exiting.'.format(e))
		unloop()

DATADIR = './DATADIR'

from . import rpcservices
import inspect
services = inspect.getmembers(rpcservices, inspect.isclass)
for name, servicecls in services:
	if not name == 'RPCService' and issubclass(servicecls, rpcservices.RPCService):
		register_rpc_service(servicecls())


def rwthrwthgotfile(filename, remote, conn):
	print 'gotfile', filename, remote, conn
	print 'CONTENTS', open(filename, 'r').read()

