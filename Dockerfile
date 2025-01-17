#FROM ubuntu:22.04
FROM ubuntu:23.04

# Set up environment and renderer user
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y \
    adduser 

RUN adduser --system --group renderer

# Install dependencies
RUN apt-get update \
    && apt-get install -y \
    wget \
    gnupg2 \
    #lsb-core \
    apt-transport-https \
    ca-certificates \
    curl

# JOTAIN POSTGRESQL:ään liittyvää?!?
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb [ trusted=yes ] https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list


# noden asennus uusiksi verrattuna aikaisempiin
# RUN set -uex; \
#     apt-get update -y; \
#     apt-get install -y ca-certificates curl gnupg; \
#     mkdir -p /etc/apt/keyrings; \
#     curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
#      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
#     NODE_MAJOR=18; \
#     echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
#      > /etc/apt/sources.list.d/nodesource.list; \
#     apt-get update; \
#     apt-get install nodejs -y;

RUN apt-get install -y nodejs


RUN apt-get install -y \
    autoconf \
    build-essential \
    bzip2 \
    cmake \
    cron \
    fonts-unifont \
    fonts-noto-cjk \
    fonts-noto-hinted \
    fonts-noto-unhinted \
    gcc \
    gdal-bin \
    git-core \
    libagg-dev \
    libboost-filesystem-dev \
    libboost-system-dev \
    libbz2-dev \
    libcairo-dev \
    libcairomm-1.0-dev \
    libexpat1-dev \
    libfreetype6-dev \
    libgdal-dev \
    libgeos++-dev \
    libgeos-dev 

RUN apt-get install -y \ 
    #libgeotiff-epsg \   # tätä ei löytynyt 22.04:lle
    libgeotiff-dev \
    libicu-dev \
    liblua5.3-dev \ 
    libpq-dev \
    libproj-dev \
    #libprotobuf-c0-dev \ # alla oleva tilalle
    libprotobuf-c-dev \
    libtiff5-dev \
    libtool \
    libxml2-dev \
	lua5.3 \
	make 


RUN apt-get install -y \	
    #libmapnik-dev \
    libmapnik3.1 \
 	mapnik-utils \
	python3-mapnik \
	#node-gyp \   # ei suostunut asentumaan
	osmium-tool \
	osmosis \
    postgis \
	postgresql-15 \
	postgresql-contrib-15 \
	postgresql-server-dev-15 \
	protobuf-c-compiler \
	python3-lxml \
	python3-psycopg2 \
	python3-shapely 


RUN apt-get install -y \	
    vim \
	sudo \
	tar \
	unzip \
	zlib1g-dev 
	
    # && apt-get clean autoclean \
	# && apt-get autoremove --yes \
	# && rm -rf /var/lib/{apt,dpkg,cache,log}/ 



# # Configure Postgres

# KOKEILLAAN NYT ILMAN TUOTA CUSTOM KONFFAUSTA!!!!!
#COPY --chown=postgres:postgres postgresql.custom.conf /etc/postgresql/15/main/conf.d/

RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/15/main/pg_hba.conf


# ASENNETAAN VALMIS EIKÄ ALETA KÄÄNTÄMÄÄN. JONKUN .H FILEEN KANSSA OLI ONGELMIA
RUN apt-get install -y osm2pgsql

# # Test Mapnik
RUN python3 -c 'import mapnik'



# APACHE 2 ASENNUS
# MOD_TILE JA RENDERD liittyvät renderd deamoniin, jolla saadaan laskettua tiilia valmiiksi
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:osmadmins/ppa
RUN apt-get install -y \
    apache2 \
    apache2-dev \
    libapache2-mod-tile 


# INSTALLOIDAAN RENDERD VALMIISTA, KOSKA ALLA OLEVA KÄÄNNÖS EI TODELLAKAAN MENNY LÄVITSE
RUN apt-get install -y \
    renderd


# # KOKEILLAAN KÄÄNTÄMÄLLÄ HOITAA MOD-TILE JA RENDERD, ei siitä kyllä mitään tullut
# RUN mkdir -p /renderer/src \
# 	&& cd /renderer/src \
# 	&& git clone -b switch2osm https://github.com/SomeoneElseOSM/mod_tile.git \
# 	&& cd mod_tile \
# 	&& ./autogen.sh \
# 	&& ./configure \
#     &&  make \
# 	&& make install \
# 	&& make install-mod_tile \
# 	&& ldconfig \
# 	&& cd ..




# Configure Apache
#RUN mkdir /var/lib/mod_tile 
#&& chown renderer /var/lib/mod_tile
#RUN mkdir /var/run/renderd 
#&& chown renderer /var/run/renderd
RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf \
 && echo "LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so" >> /etc/apache2/conf-available/mod_headers.conf \
 #&& a2enconf tile \
 && a2enconf mod_tile \ 
 && a2enconf mod_headers

COPY apache.conf /etc/apache2/sites-available/000-default.conf


RUN apt-get install -y \
    npm

# # Install Carto
RUN npm install -g carto


# # Configure stylesheets
RUN mkdir -p  /renderer/src
WORKDIR /renderer/src

RUN git clone https://github.com/Myrtillus/MTB-kartta_full-from_Tapio.git summer_map

WORKDIR /renderer/src/summer_map
RUN carto project.mml > mapnik.xml



# # Copy shapefiles from disk

WORKDIR /renderer/src/summer_map
RUN mkdir -p /renderer/src/summer_map/data \
    && mkdir -p /renderer/src/summer_map/data/simplified-land-polygons-complete-3857 \
    && mkdir -p /renderer/src/summer_map/data/land-polygons-split-3857


COPY shape-files/land-polygons-split-3857.zip /renderer/src/summer_map/data/land-polygons-split-3857.zip
COPY shape-files/simplified-land-polygons-complete-3857.zip /renderer/src/summer_map/data/simplified-land-polygons-complete-3857.zip


RUN chmod a+x extract_and_index_shapefiles.sh
RUN ./extract_and_index_shapefiles.sh \
     && rm data/*.zip

# ASENTAA bsdtar softan
RUN apt-get install --yes libarchive-tools


# Install SPLITTER, JOTTA VOIDAAN PILKKO SUOMI FILE PIENEMMÄKSI
RUN mkdir /renderer/download_splitter
WORKDIR /renderer/download_splitter
RUN wget -nv http://www.mkgmap.org.uk/download/splitter-r653.zip

# puretaan zip paketti siten, että yksi kerros hakemistorakenteesta tiputetaan pois
# niin ei tule ongelmia tuon hakemiston nimen kanssa.
# Alkuperäinen dockerfile ei toiminut ubuntu 22.04 kanssa
RUN bsdtar --strip-components=1 -xvf splitter*.zip
RUN cp splitter.jar ..
RUN cp -r lib ../splitter_lib
RUN rm -rf *

# TARVITAAN PBF FILEEN PILKKOMISEEN
#COPY shape_files/bounds.zip /renderer/
COPY shape-files/sea.zip /renderer/
COPY shape-files/cities.zip /renderer/

COPY populate_postgis.sh /populate_postgis.sh
RUN chmod a+x /populate_postgis.sh

COPY generate_tiles.py /generate_tiles.py
COPY generate_tiles_python.py /generate_tiles_python.py

COPY renderd.conf /usr/local/etc/renderd.conf

WORKDIR /


# # Add healthcheck script to Apache at /health
# COPY healthcheck.py /var/www/html/health/
# RUN chmod a+x /var/www/html/health/healthcheck.py
# COPY apache_enable_cgi.txt /etc/apache2/
# RUN cat /etc/apache2/apache_enable_cgi.txt >> /etc/apache2/apache2.conf
# WORKDIR /etc/apache2/mods-enabled
# RUN ln -s ../mods-available/cgid.conf .
# RUN ln -s ../mods-available/cgid.load .

# WORKDIR /

##### TILANNE 7.10 JÄLKEEN
# POSTGRESQL SERVICE PITÄÄ AJAA KÄYNTIIN, KUN KONTTI KÄYNNISTETÄÄN
# PSQL KÄYTTÄJÄ AUTENTIKAATIO MENEE PIELEEN







# # Entrypoint 
# ENTRYPOINT ["/run.sh"]
# CMD []
# EXPOSE 80
# EXPOSE 5432
