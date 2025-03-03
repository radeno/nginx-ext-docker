#! /bin/sh

curl -o Dockerfile.alpine https://raw.githubusercontent.com/nginxinc/docker-nginx/master/modules/Dockerfile.alpine

docker build --platform linux/amd64 --build-arg ENABLED_MODULES="brotli" -t "smikino/nginx-ext:stable" -f Dockerfile.alpine .

rm Dockerfile.alpine
