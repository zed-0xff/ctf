
import os
import re
import urlparse
import json
import logging
logging.basicConfig(level=logging.CRITICAL)

from evnet import later, listenplain, connectplain
from evnet.promise import Promise

MAX_BUF = 4096

HTTP_OK = 200
HTTP_BADREQUEST = 400
HTTP_NOTFOUND = 404
HTTP_ERROR = 500

HTTP_CODEMAP = {
	HTTP_OK: 'OK',
	HTTP_BADREQUEST: 'Bad request',
	HTTP_NOTFOUND: 'Not found',
	HTTP_ERROR: 'Internal Server Error',
}

REGEX_PATH = re.compile('^(GET|POST) (.+) HTTP/1.[01]$')
REGEX_LENGTH = re.compile('^Content-Length: (\d+)$')

def randtok():
	return os.urandom(4).encode('hex')

def parse_request(buf):
	method, path, length = None, None, 0
	for l in buf.splitlines():
		t = REGEX_PATH.match(l)
		if t:
			method, path = t.groups()
			continue
		else:
			u = REGEX_LENGTH.match(l)
			if u:
				try: length = int(u.groups()[0])
				except: return False
				continue

	if not method or not path:
		return False
	return str(method), str(path), length

def response_header(statuscode, length, ct='text/html', headers={}):
	headers.update({'Connection': 'keep-alive'})
	return '''HTTP/1.1 {0} {1}
Server: nfsv5 httpd
Content-Type: {2}; charset=utf-8
Content-Length: {3}
{4}

'''.format(
	statuscode, HTTP_CODEMAP[statuscode], ct, length,
	'\n'.join(['{0}: {1}'.format(key, value) for key,value in headers.items()])
	)

def page400():
	data = '<h1>Bad request</h1>'
	return response_header(400, len(data)) + data
def page401():
	data = '<h1>Unauthorized</h1>'
	return response_header(401, len(data)) + data
def page404():
	data = '<h1>Not found</h1>'
	return response_header(404, len(data)) + data
def page500(msg=''):
	data = '<h1>Internal Server Error</h1>{0}'.format(msg)
	return response_header(500, len(data)) + data

def page200(payload):
	return response_header(200, len(payload)) + payload

def content_type(filename):
	front, ext = os.path.splitext(filename)
	return {'.js': 'application/javascript', '.css': 'text/css', '.html': 'text/html'}.get(ext, 'text/plain')


class Chanhandler(object):
	def __init__(self, conn, wc):
		self.conn = conn
		self.wc = wc
		self.closed = False
		self.buf = ''
		conn._on('close', self.connclosed)
		conn._on('read', self.read)

	def connclosed(self, e):
		self.closed = True

	def read(self, data):
		self.buf += data

	def getdata(self):
		tmp = str(self.buf)
		self.buf = ''
		return tmp

class WebConn(object):
	def __init__(self, conn, addr, srv):
                self.conn = conn
                self.addr = addr
                self.srv = srv
		self.buf = bytearray()
		self.state = 0
		self.method = None
		self.path = None
		self.length = None
		self.authed = False
		self.pendingauth = None
		self.channels = {}
		self.chanctr = 1

		conn._on('read', self.io_in)
		conn._on('close', self.closed)
	
	def closed(self, e):
		for k, v in self.channels.items():
			v.conn.close()
			del v.wc
			del self.channels[k]

	def io_in(self, data):
		self.buf.extend(data)
		if len(self.buf) > MAX_BUF:
			self.conn.write(page400())
			self.conn.close()

		if self.state == 0:
			if '\n\n' in self.buf:
				head, self.buf = self.buf.split('\n\n', 1)
			elif '\r\n\r\n' in self.buf:
				head, self.buf = self.buf.split('\r\n\r\n', 1)
			else:
				return
			r = parse_request(head)
			if r == False:
				self.conn.write(page400())
				self.conn.close()
			else:
				self.method, self.path, self.length = r
				self.state = 1
				later(0.0, self.io_in, b'')

		elif self.state == 1:
			if len(self.buf) >= self.length:
				self.dispatch()

	def dispatch(self):
		logging.debug('request: {0} {1} (length {2})'.format(self.method, self.path, self.length))
		path = urlparse.urlparse(self.path).path.lstrip('/')

		if path.startswith('static/'):
			self.send_staticfile(path[7:])
		else:
			fn = getattr(self.srv, self.method + '_' + path, None)
			if fn: fn(self, self.buf)
			else:
				fn = getattr(self.srv, self.method, None)
				fn(self, path, self.buf)

		self.buf = bytearray()
		self.state = 0

	def send_staticfile(self, filename):
		sfiles = os.listdir(STATICDIR)
		fp = os.path.join(STATICDIR, filename)
		if os.path.exists(fp) and os.path.isfile(fp):
			fl = os.stat(fp).st_size
			fd = open(fp, 'rb')
			self.conn.write(response_header(200, fl, ct=content_type(filename)))
			for chunk in fd:
				self.conn.write(chunk)
		else:
			self.conn.write(page404())

	def openchannel(self, host, port):
		c = connectplain(host, port)
		p = Promise()
		def chanready():
			i = self.chanctr
			self.chanctr += 1
			self.channels[i] = Chanhandler(c, self)
			p._resolve(i)
		def chanclosed(e):
			if not p._result: p._smash('Connection failed.')
		c._on('ready', chanready)
		c._on('close', chanclosed)
		return p

class pwrweb(object):
	def __init__(self, ip='0.0.0.0', port=80):
		self.store = None
		self.listener = listenplain(host=ip, port=port)
		self.listener._on('close', self._lclose)
		self.listener._on('connection', self._newconn)
		self.connections = set()

	def _newconn(self, c, addr):
		logging.debug('Connection from {0}.'.format(addr))
		tc = WebConn(c, addr, self)
		self.connections.add(tc)
		def connclosed(e):
			self.connections.remove(tc)
		c._on('close', connclosed)

	def _lclose(self, e):
		logging.critical('Listener closed ({0}). Exiting.'.format(e))
		unloop()

	def GET_foo(self, wc, data):
		wc.conn.write(page200('foo'))

	def GET_(self, wc, data):
		wc.conn.write(page200('nfsv5 http transport.'))

	def GET_register(self, wc, data):
		p = self.store.register()
		p._when(self.regresult, wc)
		p._except(self.regexcept, wc)

	def POST_auth(self, wc, data):
		challenge = randtok()
		wc.pendingauth = (str(data), challenge)
		wc.conn.write(page200(challenge))

	def POST_verify(self, wc, data):
		try: key, challenge = wc.pendingauth
		except: wc.conn.write(page401())
		else:
			p = self.store.auth(key, challenge, str(data))
			p._when(self.verifyresult, wc)
			p._except(self.verifyexcept, wc)

	def POST_channel(self, wc, data):
		try:
			ip, port = json.loads(str(data))
			port = int(port)
		except:
			wc.conn.write(page500())
		else:
			p = wc.openchannel(ip, port)
			p._when(self.chanresult, wc)
			p._except(self.chanexcept, wc)

	def POST_newblob(self, wc, data):
		t = self.store.prepareblob(data)
		wc.conn.write(page200(t))

	def POST_check(self, wc, data):
		r = self.store.checkpending(str(data))
		wc.conn.write(page200(str(r)))

	def POST_finalize(self, wc, data):
		p = self.store.finalize(str(data), wc.authed)
		p._when(self.finalized, wc)

	def POST(self, wc, path, data):
		if path.startswith('chanwrite/'):
			if self.store == None:
				wc.conn.write(page500())
			elif wc.authed == False:
				wc.conn.write(page401())
			else:
				try: num = int(path[10:])
				except: wc.conn.write(page500())
				else:
					ch = wc.channels.get(num, None)
					if not ch: wc.conn.write(page500('Channel not found.'))
					else:
						ch.conn.write(data)
						wc.conn.write(page200('OK'))

		else:
			wc.conn.write(page404())
		

	def GET(self, wc, path, data):
		if path.startswith('bid/'):
			if self.store == None:
				wc.conn.write(page500())
			elif wc.authed == False:
				wc.conn.write(page401())
			else:
				bid = path[4:]
				p = self.store.getblob(bid)
				p._when(self.blobresult, wc)
				p._except(self.blobexcept, wc)
		elif path.startswith('chanread/'):
			if self.store == None:
				wc.conn.write(page500())
			elif wc.authed == False:
				wc.conn.write(page401())
			else:
				try: num = int(path[9:])
				except: wc.conn.write(page500())
				else:
					ch = wc.channels.get(num, None)
					if not ch: wc.conn.write(page500('Channel not found.'))
					else:
						wc.conn.write(page200(ch.getdata()))

		else:
			wc.conn.write(page404())

	def blobresult(self, r, wc):
		wc.conn.write(page200(r))
		
	def blobexcept(self, e, wc):
		logging.debug('blobexcept {0}'.format(e))
		wc.conn.write(page500())

	def chanresult(self, r, wc):
		wc.conn.write(page200(str(r)))
		
	def chanexcept(self, e, wc):
		logging.debug('chanexcept {0}'.format(e))
		wc.conn.write(page500(e))

	def verifyresult(self, r, wc):
		if r == True:
			wc.authed = wc.pendingauth[0]
			wc.conn.write(page200('Auth OK.'))
		else:
			wc.conn.write(page200('Auth Failed.'))

	def verifyexcept(self, e, wc):
		logging.debug('authexcept {0}'.format(e))
		wc.conn.write(page500())

	def regresult(self, r, wc):
		wc.conn.write(page200(json.dumps(r)))

	def regexcept(self, e, wc):
		wc.conn.write(page500())

	def finalized(self, r, wc):
		wc.conn.write(page200(r))
	
