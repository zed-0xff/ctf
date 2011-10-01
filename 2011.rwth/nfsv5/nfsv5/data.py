
import os
import struct
import hashlib
import logging
logging.basicConfig(level=logging.CRITICAL)

from evnet.mongodb import MongoConn
from evnet.promise import Promise
from evnet import unloop

DBHOST = '127.0.0.1'
DBPORT = 27017
DBUSER = 'nfs'
DBPASSWD = 'rwth'

def randtok():
	return os.urandom(4).encode('hex')

def checkresponse(secret, challenge, response):
	should = hashlib.md5(challenge + secret).hexdigest()[:32]
	if response == should: return True
	return False

class nfsmongo(object):
	def __init__(self):
		self.ready = False
		self.pending_blobs = {}

		self.db = MongoConn(DBHOST, DBPORT)
		self.db._on('ready', self._dbready)
		self.db._on('close', self._dbclose)

	def _dbready(self):
		self.ready = True
		logging.info('Database ready.')
		self._dbauth()

	def _dbauth(self):
		def authed(r):
			print 'authed', r
		p = self.db.auth('nfsv5', DBUSER, DBPASSWD)
		p._when(authed)
		p._except(self._dbexc)

	def _dbclose(self, e):
		logging.critical('Database connection closed ({0}). Exiting.'.format(e))
		unloop()

	def _dbexc(self, e, p=None):
		logging.critical('Database query exception. {0}'.format(e))
		#unloop()
		if p: p._smash('Error querying database.')

	def newtok(self, p=None):
		t = randtok()
		if p == None: p = Promise()
		existp = self.db.query('nfsv5.keys', {'key': t})
		existp._except(self._dbexc, p)
		existp._when(self.existtok, t, p)
		return p

	def newbid(self, p=None):
		t = randtok()
		if p == None: p = Promise()
		existp = self.db.query('nfsv5.blobs', {'bid': t})
		existp._except(self._dbexc, p)
		existp._when(self.existbid, t, p)
		return p

        def existtok(self, r, t, p):
                if r: return self.newtok(p=p)
                p._resolve(t)

        def existbid(self, r, t, p):
                if r: return self.newbid(p=p)
                p._resolve(t)

	def register(self):
		def gotnewtok(tok, p):
			v = randtok()
			self.db.insert('nfsv5.keys', [{'key': tok, 'verify': v, 'bids': []},])
			p._resolve((tok, v))

		p = Promise()
		p2 = self.newtok()
		p2._when(gotnewtok, p)
		return p

	def auth(self, key, ch, resp):
		def gotcreds(r, p):
			if not r: return p._smash('Auth failed.')
			v = r[0]['verify']
			if not checkresponse(v, ch, resp): return p._smash('Response invalid.')
			p._resolve(True)

		p = Promise()
		p2 = self.db.query('nfsv5.keys', {'key': key})
		p2._except(self._dbexc, p)
		p2._when(gotcreds, p)
		return p

	def prepareblob(self, upper):
		t = randtok()
		self.pending_blobs[t] = (upper, None)
		return t

	def addlower(self, token, lower):
		eupper, elower = self.pending_blobs.get(token, (None, None))
		self.pending_blobs[token] = (eupper, lower)
		return 'OK'

	def checkpending(self, token):
		pair = self.pending_blobs.get(token, None)
		if pair == None: return False
		upper, lower = pair
		return lower

	def finalize(self, token, authkey):
		pair = self.pending_blobs.get(token, None)
		p = Promise()
		if pair == None: p._resolve('ERR')
		upper, lower = pair
		upper, lower = str(upper), str(lower)
		authkey = str(authkey)
			
		def gotnewbid(bid, p):
			self.db.insert('nfsv5.blobs', [{'bid': bid, 'data':upper+lower, 'owner': authkey},])
			p._resolve(bid)

		p2 = self.newbid()
		p2._when(gotnewbid, p)
		return p

	def listblobs(self, authkey, q={}):
		#q.update({'owner': authkey})
		p = self.db.query('nfsv5.blobs', q)
		return p

	def getblob(self, bid):
		p = Promise()
		p2 = self.db.query('nfsv5.blobs', {'bid': bid})
		p2._except(self._dbexc, p)
		p2._when(self.gotblob, p)
		return p

	def gotblob(self, r, p):
		if len(r) == 0: return p._smash('Not found.')
		row = r[0]
		p._resolve(row['data'])


