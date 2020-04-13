.PHONY: build push test

build: 
	docker build -t registry.finomena.fi/c/openstreetmap-tile-server:0.4.11 --build-arg NOCACHE=$$(date +%s) .

push: build
	docker push registry.finomena.fi/c/openstreetmap-tile-server:0.4.11

test: build
	-docker volume rm openstreetmap-data
	-docker volume rm openstreetmap-rendered-tiles
	docker run -e THREADS=10 -e NODEMEM=10000 -v openstreetmap-data:/var/lib/postgresql/10/main marasu/openstreetmap-tile-server import
	docker run --name mtb-tileserver -p 8880:80 -v openstreetmap-data:/var/lib/postgresql/10/main -v openstreetmap-rendered-tiles:/var/lib/mod_tile -d marasu/openstreetmap-tile-server run