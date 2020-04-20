.PHONY: build push test

build: 
	docker build -t registry.finomena.fi/c/openstreetmap-tile-server:latest --build-arg NOCACHE=$$(date +%s) .
	docker tag registry.finomena.fi/c/openstreetmap-tile-server:latest registry.finomena.fi/c/openstreetmap-tile-server:0.4.14

build_min:
	docker build -t registry.finomena.fi/c/openstreetmap-tile-server:latest --build-arg NOCACHE=0 .
	docker tag registry.finomena.fi/c/openstreetmap-tile-server:latest registry.finomena.fi/c/openstreetmap-tile-server:0.4.14

push: build
	docker push registry.finomena.fi/c/openstreetmap-tile-server:0.4.12

test:
	-docker volume rm openstreetmap-data
	-docker volume rm openstreetmap-rendered-tiles
	docker run -e THREADS=10 -e NODEMEM=10000 -v $$(pwd):/osm-data -v openstreetmap-data:/var/lib/postgresql/10/main registry.finomena.fi/c/openstreetmap-tile-server:latest import
	docker run --name mtb-tileserver -p 8880:80 -v $$(pwd):/osm-data -v openstreetmap-data:/var/lib/postgresql/10/main -v openstreetmap-rendered-tiles:/var/lib/mod_tile registry.finomena.fi/c/openstreetmap-tile-server:latest pre-render
	echo $?
