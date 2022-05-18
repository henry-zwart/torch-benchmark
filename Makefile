REPO_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')
HAS_DOCKER ?= $(shell which docker)
RUN ?= $(if $(HAS_DOCKER), docker run $(DOCKER_ARGS) --platform linux/amd64 --shm-size 12G --rm -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) -v $$(pwd):/code -w /code -u $(UID):$(GID) $(IMAGE))
IMAGE := coprosmo/$(REPO_NAME)
UID ?= kaimahi
GID ?= kaimahi
DOCKER_ARGS ?=
PYTHON ?= python3.10


.PHONY: docker docker-push docker-pull enter jupyter

docker:
	docker build --platform linux/amd64 --tag $(IMAGE):$(GIT_TAG) . -f Dockerfile
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

enter:
	docker run --platform linux/amd64 -it --rm -v $$(pwd):/code -w /code -u $(UID):$(GID) $(IMAGE) bash
	
experiment:
	docker run --platform linux/amd64 -it --rm -v $$(pwd):/code -w /code -u $(UID):$(GID) $(IMAGE) python3.10 main.py

JUPYTER_PASSWORD ?= jupyter
JUPYTER_PORT ?= 8888
jupyter: DOCKER_ARGS=-u $(UID):$(GID) --rm -it -p $(JUPYTER_PORT):$(JUPYTER_PORT) -e NB_USER=$$USER -e NB_UID=$(UID) -e NB_GID=$(GID)
jupyter:
	$(RUN) $(PYTHON) -m jupyter lab \
		--port $(JUPYTER_PORT) \
		--ip 0.0.0.0 \
		--NotebookApp.password="$(shell $(RUN) \
			$(PYTHON) -c \
			"from notebook.auth import passwd; print(passwd('$(JUPYTER_PASSWORD)', 'sha1'))")"
