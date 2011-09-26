#!/usr/pkg/bin/python2.4
import os
import socket
import subprocess
import sys

HOST = '10.0.2.15'
PORT = 1079

def serve_client():
	data = conn.recv(512).rstrip()
	os.chdir("/home/user");

	print 'New connection from: %s, Input: %s' % ( addr, data )
	cmd = "/usr/bin/finger " + data
	proc = os.popen(cmd)

	for line in proc.readlines():
		if not line:
			return
		conn.sendall(line)
	proc.close()

if __name__ == '__main__':

	try:
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
		s.bind((HOST, PORT))
		s.listen(50)

		while True:
			conn, addr = s.accept()

			newpid = os.fork()
			if newpid:
				conn.close()
				os.waitpid(0, os.WNOHANG)
			else:
				serve_client()
				conn.shutdown(1)
				conn.close()
				sys.exit(0)
			os.waitpid(0, os.WNOHANG)
	except socket.error, msg:
		sys.stderr.write("[ERROR] %s" % msg[1])
	except (KeyboardInterrupt):
		sys.stderr.write("[ERROR] %s" % msg[1])
