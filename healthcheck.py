#!/usr/bin/python3
# -----------------------------------------------------------------
# Check health of tileserver by retrieving few tiles and checking
# that their size indicates expected data (i.e. complex image rather
# than just grey landarea or coastline)
# -----------------------------------------------------------------

import urllib.request
import urllib.error
import socket
import random

site = 'localhost'
protocol = 'http://'
tile_dir = 'tiles'
zoom_level = '16'
min_x = 36000
max_x = 38000
min_y = 15000
max_y = 18000
image_type = '.png'
min_tile_size = 100
n_tiles_to_check = 4

def random_tiles(nbr, site, image_type):
	tiles = []
	for i in range(nbr):
		tiles.append((random_tile(site, image_type), min_tile_size))
	return tiles

def random_tile(site, image_type):
	url = protocol + site + '/' + tile_dir + '/' + zoom_level
	x = random.randrange(min_x, max_x)
	y = random.randrange(min_y, max_y)
	return url + '/' + str(x) + '/' + str(y) + image_type

health_check = [
	(protocol + site + '/tiles/15/18376/9243.png', 7000),
	(protocol + site + '/tiles/14/9187/4625.png', 20000),
	(protocol + site + '/tiles_winter/14/9272/4618.png', 30000)
]

tile_test_set = random_tiles(n_tiles_to_check, site, image_type)
tile_test_set = tile_test_set + (health_check)

health_status = True

exit

for tile_url in tile_test_set:
	try:
		res = urllib.request.urlopen(tile_url[0], None, 10)
		len = int(res.getheader('Content-Length'))
		if res.getheader('Content-Type') != 'image/png' or len < tile_url[1]:
			health_status = False
	except urllib.error.HTTPError as e:
		health_status = False
	except urllib.error.URLError as e:
		health_status = False
	except socket.error as e:
		health_status = False

if health_status:
	print('Content-Type: text/plain;charset=utf-8')
	print()
	print('OK')
else:
	print('Status: 500 Internal Server Error')
	print('Content-Type: text/plain;charset=utf-8')
	print()
	print('ERROR')


		

