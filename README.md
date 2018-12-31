# openstreetmap-tile-server

This container image allows you to easily set up an OpenStreetMap PNG tile server given a `.osm.pbf` file. Default OSM-file is Finland-latest from [geofabrik.de](https://www.geofabrik.de).
Image is based on the [latest Ubuntu 18.04 LTS guide](https://switch2osm.org/manually-building-a-tile-server-18-04-lts/) from [switch2osm.org](https://switch2osm.org/) and uses 
a [custom CartoCSS style](https://github.com/Myrtillus/openstreetmap-carto) developed for mapping of mountain bike trails in Finland.

## Setting up the server

Unless you want to use Finland-latest OSM-data then first download an .osm.pbf extract from geofabrik.de for the region that you're interested in. You can then start importing it into PostgreSQL by running a container and mounting the file as `/data.osm.pbf`. For example:

    docker run -v /absolute/path/to/luxembourg.osm.pbf:/data.osm.pbf -v openstreetmap-data:/var/lib/postgresql/10/main marasu/openstreetmap-tile-server import

If the container exits without errors, then your data has been successfully imported to PostGIS database and you are now ready to run the tile server. A Docker volume `openstreetmap-data` is created
in the import process.

## Running the tile server

Run the server like this:

    docker run -p 80:80 -v openstreetmap-data:/var/lib/postgresql/10/main -d marasu/openstreetmap-tile-server run

Your tiles will now be available at http://localhost:80/tiles/{z}/{x}/{y}.png and winter version at http://localhost:80/tiles_winter/{z}/{x}/{y}.png. If you open `leaflet-demo.html` in your browser, you should be able to see the tiles served by your own machine. Note that it will initially quite a bit of time to render the larger tiles at low zoom level for the first time.

## Preserving rendered tiles

Tiles that have already been rendered will be stored in `/var/lib/mod_tile`. To make sure that this data survives container restarts, you can run the server instead with command:

    docker run -p 80:80 -v openstreetmap-data:/var/lib/postgresql/10/main -v openstreetmap-rendered-tiles:/var/lib/mod_tile -d marasu/openstreetmap-tile-server run

A Docker volume `openstreetmap-rendered-tiles` is created and used for storing of rendered tiles.

## Performance tuning

The import and tile serving processes use 4 threads by default, but this number can be changed by setting the `THREADS` environment variable. Node memory for optimising OSM-data import can be set with
`NODEMEM` enviroment variable, default is 2048 (MB). For example:

    docker run -p 80:80 -e THREADS=24 -e NODEMEM=8192 -v openstreetmap-data:/var/lib/postgresql/10/main -d marasu/openstreetmap-tile-server run

Server can be started with `run-fresh` command instead of `run` to enable pre-rendering a set of tiles defined in `pre_render.py` script. Pre-rendering is done as a background task allowing server to accept incoming tile requests immediately after starting the container.

## Updating OSM-data

Updating OSM-data with current version of this container image is easiest done by first stopping the running container, deleting both docker volumes `openstreetmap-data` and `openstreetmap-rendered-tiles` and then running the server setup (OSM-data import to PostGIS database) again and starting the tile server.

Updating can be done also automatically with `deployment.py` script which does a healthcheck for the new data (and container) before launching it to replace the old container.

## Healthcheck

URI /health will return `OK` if tileserver is responding to a healthcheck which is currently a few tile requests to server.

## To be done

- [ ] Separate all `apt install`s in Dockerfile for better documentation for what is needed for which server component

## License

Original work in https://github.com/Overv/openstreetmap-tile-server, this fork is heavily modified and extended.

Original copyright:

```
Copyright 2018 Alexander Overvoorde

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
