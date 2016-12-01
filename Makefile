BRANCH ?= "master"
VERSION ?= $(shell cat ./VERSION)
REPONAME ?= "assume-role"

DEFAULT: run

build-image:
	@docker build -t vidsyhq/${REPONAME} .

build-image-local:
	@docker build -t vidsyhq/${REPONAME}:local .

check-version:
	@echo "=> Checking if VERSION exists as Git tag..."
	(! git rev-list ${VERSION})

deploy:
	@docker login -e ${DOCKER_EMAIL} -u ${DOCKER_USER} -p ${DOCKER_PASS}
	@docker tag vidsyhq/${REPONAME}:latest vidsyhq/${REPONAME}:${CIRCLE_TAG}
	@docker push vidsyhq/${REPONAME}:${CIRCLE_TAG}
	@docker push vidsyhq/${REPONAME}

push-tag:
	@echo "=> New tag version: ${VERSION}"
	git checkout ${BRANCH}
	git pull origin ${BRANCH}
	git tag ${VERSION}
	git push origin ${BRANCH} --tags

test:
	@echo "No tests :("
