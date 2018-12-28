#!/usr/bin/python
# -----------------------------------------------------------------
# Canary deployment of Tileserver
# -----------------------------------------------------------------

import time
import subprocess
from datetime import date
import urllib2
import socket
import time

PG_VOLUME_NAME = 'mtb-tileserver-pg'
RENDERED_VOLUME_NAME = 'mtb-tileserver-rendered-tiles'
TILESERVER_NAME = 'mtb-tileserver'
TILESERVER_PORT = '8880'
TEST_TILESERVER_NAME = 'mtb-tileserver-new'
TEST_TILESERVER_PORT = '8881'
TEST_HEALTHCHECK = 'http://localhost:' + TEST_TILESERVER_PORT + '/health/'

def shell_cmd(cmd):
	print cmd
	try:
		output = subprocess.check_output(cmd, shell=True)
	except subprocess.CalledProcessError as e:
		output = e
	except Exception as e:
		output = e

	return output

# -----------------------------------------------------------------
# Main program
# -----------------------------------------------------------------

old_pg_volume_names = shell_cmd('docker volume ls -q | grep ' + PG_VOLUME_NAME).split()

new_pg_volume_name = PG_VOLUME_NAME + '-' + date.today().isoformat()
#new_pg_volume_name = PG_VOLUME_NAME + '-' + date(2018, 12, 26).isoformat()

# Import OSM-data to PostGIS and start new container in "run" mode
print 'RUN IMPORT ' + shell_cmd('docker run --rm -e THREADS=10 -e NODEMEM=10000 -v ' + new_pg_volume_name + ':/var/lib/postgresql/10/main marasu/openstreetmap-tile-server import')
#print 'RUN IMPORT ' + shell_cmd('docker run --rm -e THREADS=10 -e NODEMEM=10000 -v /home/suomimar/Dropbox/projects/openstreetmap-tile-server/finland-latest.osm.pbf:/data.osm.pbf -v ' +
#                                new_pg_volume_name + ':/var/lib/postgresql/10/main marasu/openstreetmap-tile-server import')
print 'RUN TEST ' + shell_cmd('docker run --name ' + TEST_TILESERVER_NAME + ' -p ' + TEST_TILESERVER_PORT + ':80 -v ' + new_pg_volume_name + ':/var/lib/postgresql/10/main ' +
                              '-v ' + RENDERED_VOLUME_NAME + ':/var/lib/mod_tile -d marasu/openstreetmap-tile-server run')

# Health check for new container
time.sleep(40)
for i in range(5):
	time.sleep(20)
	try:
			for line in urllib2.urlopen(TEST_HEALTHCHECK, None, 10):
				if line.find('OK') != -1:
					new_server_ok = True
					break
				else:
					new_server_ok = False
	except (urllib2.HTTPError, urllib2.URLError, socket.error):
		new_server_ok = False

# If Health ok re-start new container and remove old
if new_server_ok:
	print 'STOP ' + shell_cmd('docker stop ' + TEST_TILESERVER_NAME)
	print 'RM ' + shell_cmd('docker rm ' + TEST_TILESERVER_NAME)
	print 'STOP ' + shell_cmd('docker stop ' + TILESERVER_NAME)
	print 'RM ' + shell_cmd('docker rm ' + TILESERVER_NAME)
	for volume in old_pg_volume_names:
		print 'RM VOLUME ' + shell_cmd('docker volume rm ' + volume)
	print 'RUN ' + shell_cmd('docker run --name ' + TILESERVER_NAME + ' -e THREADS=10 -p ' + TILESERVER_PORT + ':80 -v ' + new_pg_volume_name + ':/var/lib/postgresql/10/main ' +
                           '-v ' + RENDERED_VOLUME_NAME + ':/var/lib/mod_tile -d marasu/openstreetmap-tile-server run-fresh')
else:
	print 'ERROR: Container healthcheck failed'
