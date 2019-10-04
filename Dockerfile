FROM ubuntu:18.04

# Based on
# https://switch2osm.org/manually-building-a-tile-server-18-04-lts/

# Set up environment and renderer user
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN adduser --disabled-password --gecos "" renderer

# Install dependencies
RUN apt-get update && apt-get install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev \ 
	libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev \ 
	libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 \
	liblua5.1-dev libgeotiff-epsg sudo \
	make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libgeos-dev \
	libgeos++-dev libproj-dev lua5.2 liblua5.2-dev \
	autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libmapnik-dev mapnik-utils python-mapnik \
	fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted ttf-unifont \
	postgresql postgresql-contrib postgis postgresql-10-postgis-2.4 \
	npm nodejs curl \
	&& apt-get clean autoclean \
	&& apt-get autoremove --yes \
	&& rm -rf /var/lib/{apt,dpkg,cache,log}/
USER renderer

# Kubernetes hack, because emptydir-volume does not copy existing data from image
USER root
RUN mv /var/lib/postgresql/10/main /var/lib/postgresql/10/main2
RUN mkdir /var/lib/postgresql/10/main

# Configure Postgres
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/10/main/pg_hba.conf
RUN echo "listen_addresses = '*'" >> /etc/postgresql/10/main/postgresql.conf
USER renderer

# Install latest osm2pgsql
RUN mkdir /home/renderer/src
WORKDIR /home/renderer/src
RUN git clone https://github.com/openstreetmap/osm2pgsql.git
WORKDIR /home/renderer/src/osm2pgsql
USER renderer
RUN mkdir build
WORKDIR /home/renderer/src/osm2pgsql/build
RUN cmake ..
RUN make
USER root
RUN make install
USER renderer

# Test Mapnik
RUN python -c 'import mapnik'

# Install mod_tile and renderd
WORKDIR /home/renderer/src
RUN git clone -b switch2osm https://github.com/SomeoneElseOSM/mod_tile.git
WORKDIR /home/renderer/src/mod_tile
RUN ./autogen.sh
RUN ./configure
RUN make
USER root
RUN make install
RUN make install-mod_tile
RUN ldconfig
USER renderer

# Configure Apache
USER root
RUN mkdir /var/lib/mod_tile
RUN chown renderer /var/lib/mod_tile
RUN mkdir /var/run/renderd
RUN chown renderer /var/run/renderd
RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf
RUN a2enconf mod_tile
COPY apache.conf /etc/apache2/sites-available/000-default.conf
USER renderer

# Install Carto
USER root
RUN npm install -g carto
USER renderer

# Configure stylesheets
ARG NOCACHE=0
WORKDIR /home/renderer/src
RUN git clone -b pkk_summer https://github.com/MaRaSu/openstreetmap-carto.git pkk_summer
RUN git clone https://github.com/myrtillus/pkk_winter_2014.git pkk_winter
WORKDIR /home/renderer/src/pkk_summer
RUN wget -nv https://raw.githubusercontent.com/MaRaSu/osm2pgsql_style/master/pkk_maps.style
RUN carto -v
RUN carto project.mml > mapnik.xml
WORKDIR /home/renderer/src/pkk_winter
RUN wget -nv https://raw.githubusercontent.com/Myrtillus/osm2pgsql_style/master/pkk_maps.style
RUN carto -v
RUN carto project.mml > mapnik.xml

# Load shapefiles
WORKDIR /home/renderer/src/pkk_summer
RUN ./get-shapefiles.sh
WORKDIR /home/renderer/src/pkk_winter
RUN cp /home/renderer/src/pkk_summer/get-shapefiles.sh get-shapefiles-new.sh
#RUN chmod +x get-shapefiles.sh
RUN ./get-shapefiles-new.sh

# Copy config files
USER root
COPY run.sh /
COPY pre_render.py /usr/local/bin/
COPY renderd.conf /usr/local/etc/
RUN chmod a+x /usr/local/bin/pre_render.py
COPY index.html /var/www/html/

# Add healthcheck script to Apache at /health
COPY healthcheck.py /var/www/html/health/
RUN chmod a+x /var/www/html/health/healthcheck.py
COPY apache_enable_cgi.txt /etc/apache2/
RUN cat /etc/apache2/apache_enable_cgi.txt >> /etc/apache2/apache2.conf
WORKDIR /etc/apache2/mods-enabled
RUN ln -s ../mods-available/cgid.conf .
RUN ln -s ../mods-available/cgid.load .

# Entrypoint 
ENTRYPOINT ["/run.sh"]
CMD []
EXPOSE 80
EXPOSE 5432
