
import sys
import os
import traceback

from .pwrweb import pwrweb
from .msgblock import server as blockserver
from .dynamicnoncesystem import server as nsserver
from .data import nfsmongo
from evnet import loop

IP = '0.0.0.0'
WEBPORT = 13371
CMBPORT = 13372
DNSPORT = 13373

def main():
	data = nfsmongo()
	web = pwrweb(ip=IP, port=WEBPORT)
	web.store = data
	block = blockserver(ip=IP, port=CMBPORT)
	block.store = data
	ns = nsserver(ip=IP, port=DNSPORT)
	ns.store = data
	try:
		loop()
	except:
		pass

	traceback.print_exc()
	return 0

