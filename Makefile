CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := empty
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

init:
	helm init --client-only

setup: init
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io

build: clean setup
	helm dependency build empty
	helm lint empty

install: clean build
	helm upgrade ${NAME} empty --install

upgrade: clean build
	helm upgrade ${NAME} empty --install

delete:
	helm delete --purge ${NAME} empty

clean:
	rm -rf empty/charts
	rm -rf empty/${NAME}*.tgz
	rm -rf empty/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" empty/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" empty/Chart.yaml
else
	exit -1
endif
	helm package empty
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
