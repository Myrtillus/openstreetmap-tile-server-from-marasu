#!/usr/bin/python
# -----------------------------------------------------------------
# Check health of tileserver
# -----------------------------------------------------------------

import urllib2
import socket

health_check = [
	'tiles/8/150/74.png',
	'tiles/14/9272/4618.png',
	'tiles_winter/14/9272/4618.png'
]
HOST = 'localhost'
health_status = True

for tile_url in health_check:
	try:
		url = 'http://' + HOST + '/' + tile_url
		res = urllib2.urlopen(url, None, 10)
		if res.info().gettype() != 'image/png':
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
	print 'NOK'


		

