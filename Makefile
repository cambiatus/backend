.PHONY: help build

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`
BUILD ?= `git rev-parse --short HEAD`
IMAGE_NAME ?= "bespiral/backend"

help:
	@echo "$(APP_NAME):$(APP_VSN)-$(BUILD)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	docker build --build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		-t $(IMAGE_NAME):$(APP_VSN)-$(BUILD) \
		-t $(IMAGE_NAME):latest .

push: ## Push the image to docker repository
	docker push $(IMAGE_NAME):$(APP_VSN)-$(BUILD)
	docker push $(IMAGE_NAME):latest
	echo $(IMAGE_NAME):$(APP_VSN)-$(BUILD) pushed

run: ## Run the app in Docker
	docker run --env-file config/docker.env \
		--expose 4000 -p 4000:4000 \
		--name bespiral-api \
		--rm -it $(IMAGE_NAME):latest
