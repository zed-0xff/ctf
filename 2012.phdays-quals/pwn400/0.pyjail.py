#!/usr/bin/env python
from secure_reader import Reader

while True:
    try:
	inp = raw_input('>>> ')
	a = None
	exec 'a=' + inp
	print a
    except Exception, e:
	print  e.__class__.__name__, ':', e 

