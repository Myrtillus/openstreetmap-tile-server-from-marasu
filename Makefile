.PHONY: build push test

build:
	docker build -t marasu/openstreetmap-tile-server .

push: build
	docker push marasu/openstreetmap-tile-server:latest

test: build
	docker volume create openstreetmap-data
	docker run -e THREADS=10 -e NODEMEM=10000 -v openstreetmap-data:/var/lib/postgresql/10/main marasu/openstreetmap-tile-server import
	docker run -p 8580:80 -v openstreetmap-data:/var/lib/postgresql/10/main -v openstreetmap-rendered-tiles:/var/lib/mod_tile -d marasu/openstreetmap-tile-server run