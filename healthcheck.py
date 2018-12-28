#!/usr/bin/python
# -----------------------------------------------------------------
# Check health of tileserver by retrieving few tiles and checking
# that their size indicates expected data (i.e. complex image rather
# than just grey landarea or coastline)
# -----------------------------------------------------------------

import urllib2
import socket

health_check = [
	('tiles/8/146/66.png', 15000),
	('tiles/14/9272/4618.png', 30000),
	('tiles_winter/14/9272/4618.png', 30000)
]
HOST = 'localhost'
health_status = True

for tile_url in health_check:
	try:
		url = 'http://' + HOST + '/' + tile_url[0]
		res = urllib2.urlopen(url, None, 10)
		len = int(res.info().getheader('Content-Length'))
		if res.info().gettype() != 'image/png' or len < tile_url[1]:
			health_status = False
	except urllib2.HTTPError as e:
		health_status = False
	except urllib2.URLError as e:
		health_status = False
	except socket.error as e:
		health_status = False

print "Content-Type: text/plain;charset=utf-8"
print

if health_status:
	print 'OK'
else:
	print 'ERROR'


		

