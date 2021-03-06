# NAME is set to the name of the current directory ($PWD)
NAME := $(notdir $(shell pwd))
DOCKER_PATH := /blinkr/
FULL_NAME := ${DOCKER_REGISTRY}${DOCKER_PATH}${NAME}
FROM_IMAGE := $(shell cat Dockerfile |grep "^FROM " | awk '{print $$2}')

default: dep build push

dep:
	@if test -z ${DOCKER_REGISTRY}; then echo "Error: Missing 'DOCKER_REGISTRY' ENV variable"; exit 1; fi;

build:
	sudo docker build --pull -t ${FULL_NAME} -f Dockerfile .

push:
	sudo docker push ${FULL_NAME}

run:
	sudo docker run --rm --name ${NAME} -it ${FULL_NAME}

test:
	@echo ${FULL_NAME}
	@echo ${FROM_IMAGE}

squash:
	sudo ~/.local/bin/docker-scripts squash -t ${FULL_NAME} -f ${FROM_IMAGE} ${FULL_NAME}:tmp
