
import os
import struct
import traceback
import logging
logging.basicConfig(level=logging.CRITICAL)

from scapy.all import DNS, DNSQR, DNSRR

from evnet import later, listenplain, connectplain
from evnet.promise import Promise

import querymod

DEBUG = False

def randtok():
	return os.urandom(4).encode('hex')

class nsconn(object):
	def __init__(self, conn, addr, srv):
                self.conn = conn
                self.addr = addr
                self.srv = srv
		self.authed = False
		self.pendingauth = None

		conn._on('read', self.io_in)
		conn._on('close', self.closed)

	def send(self, data):
		self.conn.write(struct.pack('!H', len(data)) + data)

	def io_in(self, data):
		a = DNS()
		try:
			a.dissect(data[2:])
			if DEBUG: a.show()
			if not a.qd: return self.err(a, 1)
			self.answer(a)
		except:
			traceback.print_exc()
			self.err(a, 1)

	def answer(self, dnsp):
		logging.info("Request for %s (%s,%s) from %s"%(dnsp.qd.qname[:-1],dnsp.qd.qclass,dnsp.qd.qtype,str(self.addr)))
		if (not (dnsp.qd.qtype == 1 and dnsp.qd.qclass == 1)):
			return self.err(dnsp)

		entry = '10.11.0.0'
		n = self.buildp(dnsp, payload=entry)
		n.rcode = 0

		if (dnsp.qd.qname.endswith("auth.dyn.ctf.itsec.")):
			self.auth(dnsp, n)
		elif (dnsp.qd.qname.endswith("verify.dyn.ctf.itsec.")):
			if self.srv.store == None: return self.err(dnsp, code=2)
			self.verify(dnsp, n)
		elif (dnsp.qd.qname.endswith("blob.dyn.ctf.itsec.")):
			if self.srv.store == None: return self.err(dnsp, code=2)
			self.blob(dnsp, n)
		elif (dnsp.qd.qname.endswith(".dyn.ctf.itsec.")):
			if self.srv.store == None: return self.err(dnsp, code=2)
			self.query(dnsp, n)
		else:
			logging.debug("Answering %s (ttl: %d)" % (entry,60))
			self.send(n.build())

	def err(self, dnsp, code=4):
		n = self.buildp(dnsp)
		n.rcode = code
		logging.debug("Rejecting with error code {0}".format(code))
		self.send(n.build())

	def auth(self, dnsp, a):
		challenge = randtok()
		self.pendingauth = (dnsp.qd.qname[:dnsp.qd.qname.find('.auth.dyn')], challenge)
		ad = DNSRR(rrname='challenge.dyn.ctf.itsec.', type=5, rclass=1,
			ttl=60, rdata = challenge)
		a.ar = ad
		a.arcount = 1
		self.send(a.build())

	def blob(self, dnsp, a):
		bid = dnsp.qd.qname[:dnsp.qd.qname.find('.blob.dyn')]
		p = self.srv.store.getblob(bid)
		p._when(self.blobresult, dnsp, a)
		p._except(self.blobexcept, dnsp)

	def query(self, dnsp, a):
		try: key, challenge = self.pendingauth
		except: return self.err(dnsp, code=5)
		
		front = dnsp.qd.qname[:dnsp.qd.qname.find('.dyn')]
		q = querymod.query(front)
		p = self.srv.store.listblobs(key, q)
		p._when(self.qresult, dnsp, a)
		p._except(self.blobexcept, dnsp)

	def qresult(self, r, dnsp, a):
		ad = None
		a.arcount = 0
		for row in r:
			tmp = DNSRR(rrname='dyn.ctf.itsec.', type=5, rclass=1, ttl=60, rdata=row['data'])
			if ad == None: ad = tmp
			else: ad = ad / tmp
			a.arcount += 1
		a.ar = ad
		self.send(a.build())

	def blobresult(self, r, dnsp, a):
		ad = DNSRR(rrname='blob.dyn.ctf.itsec.', type=5, rclass=1,
			ttl=60, rdata = r)
		a.ar = ad
		a.arcount = 1
		self.send(a.build())
		
	def blobexcept(self, e, dnsp):
		logging.debug('blobexcept {0}'.format(e))
		self.err(dnsp, 2)

	def verify(self, dnsp, a):
		solution = dnsp.qd.qname[:dnsp.qd.qname.find('.verify.dyn')]
		try: key, challenge = self.pendingauth
		except: return self.err(dnsp, 5)
		else:
			p = self.srv.store.auth(key, challenge, str(solution))
			p._when(self.verifyresult, dnsp, a)
			p._except(self.verifyexcept, dnsp)

	def verifyresult(self, r, dnsp, a):
		if r == True:
			self.authed = self.pendingauth[0]
			ad = DNSRR(rrname='verify.dyn.ctf.itsec.', type=5, rclass=1,
				ttl=60, rdata = 'OK')
			a.ar = ad
			a.arcount = 1
			self.send(a.build())
		else:
			self.err(dnsp, 5)

	def verifyexcept(self, e, dnsp):
		logging.debug('authexcept {0}'.format(e))
		self.err(dnsp, 2)

	def buildp(self, dnsp, payload=None):
		n = DNS(id=dnsp.id,qr=1,opcode=0,aa=1,tc=0,rd=dnsp.rd,ra=0,qdcount=dnsp.qdcount,nscount=0,arcount=0,qd=dnsp.qd)
		if payload:
			a = DNSRR(rrname=dnsp.qd.qname,type=1,rclass=1,ttl=60,rdlen=4,rdata=payload)
			n.an = a
			n.ancount = 1
		return n

	def closed(self, e):
		return 0
	

class server(object):
	def __init__(self, ip='0.0.0.0', port=80):
		self.store = None
		self.listener = listenplain(host=ip, port=port)
		self.listener._on('close', self._lclose)
		self.listener._on('connection', self._newconn)

	def _newconn(self, c, addr):
		logging.debug('Connection from {0}.'.format(addr))
		tc = nsconn(c, addr, self)

	def _lclose(self, e):
		logging.critical('Listener closed ({0}). Exiting.'.format(e))
		unloop()

