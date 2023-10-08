#!/bin/bash


# Initialize PostgreSQL
service postgresql start
#sudo -u postgres createuser renderer
sudo -u postgres createuser renderer
sudo -u postgres createdb -E UTF8 -O renderer gis
#sudo -u postgres psql -c "ALTER USER renderer PASSWORD '${PGPASSWORD:-renderer}'"
sudo -u postgres psql -c "ALTER USER renderer PASSWORD '${PGPASSWORD:-renderer}'"
sudo -u postgres psql -d gis -c "CREATE EXTENSION postgis;"
sudo -u postgres psql -d gis -c "CREATE EXTENSION hstore;"
# sudo -u postgres psql -d gis -c "ALTER TABLE geometry_columns OWNER TO renderer;"
# sudo -u postgres psql -d gis -c "ALTER TABLE spatial_ref_sys OWNER TO renderer;"

sudo -u postgres psql -d gis -c "GRANT ALL PRIVILEGES ON SCHEMA public TO renderer;"



function split_pbf_file () {
	# Extract region out of Finland OSM file
	osmosis --read-pbf file=${7} --bounding-box left=$1 bottom=$2 right=$3 top=$4 --write-pbf ${8}

	# echo "splitteri ajossa ........................................."


	# # Split the osm file to smaller pieces
	# java -Xmx4000m -jar splitter.jar region.osm.pbf\
	# --description="$5"\
	# --precomp-sea=sea.zip\
	# --geonames-file=cities.zip\
	# --max-areas=4096\
	# --max-nodes=1000000\
	# --mapid=${6}\
	# --status-freq=2\
	# --keep-complete=true

}

cd /renderer

echo ">>>>>>>>>>>>>>>> SPLITTING TAMPERE REGION FROM FINLAND FILE"
#split_pbf_file 22.80 61.00 25.00 62.20 "Tampere region" 88950008 "/osm-data/finland-latest.osm.pbf" "/osm-data/tampere.osm.pbf"
echo "<<<<<<<<<<<<<<<  SPLITTING TAMPERE DONE..."

echo ">>>>>>>>>>>>>>>> DUMPING TAMPERE REGION TO POSTGIS"

# Import data

#exec sudo -u renderer osm2pgsql -d gis --create -G --hstore -C ${NODEMEM:-2048} --number-processes ${THREADS:-4} -S /renderer/src/summer_map/tk_mtb.style /osm-data/tampere.osm.pbf
exec sudo -u renderer osm2pgsql -d gis --create -G --hstore -C ${NODEMEM:-2048} --number-processes ${THREADS:-4} -S /renderer/src/summer_map/tk_mtb.style /osm-data/finland-latest.osm.pbf


# AKTIVOIDAAN RENDERD PROSESSI
sudo -u renderer renderd -f -c /usr/local/etc/renderd.conf
#  renderd -c /usr/local/etc/renderd.conf