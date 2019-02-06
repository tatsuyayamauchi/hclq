# Version and linker flags
VERSION=$(shell echo $$(ver=$$(git tag -l --points-at HEAD) && [ -z $$ver ] && ver=$$(git describe --always --dirty); printf $$ver))
LDFLAGS=-s -w -X github.com/mattolenik/hclq/cmd.version=${VERSION}
GOOS=darwin linux windows
GOARCH=amd64
GOPATH=$(HOME)/go
IS_PUBLISH=$(APPVEYOR_REPO_TAG)

default: test build

build:
	go build -i -ldflags="${LDFLAGS}" -gcflags='-N -l' -o dist/hclq

clean:
	rm -rf dist/ vendor/

dist: get
	set -v; for goos in ${GOOS}; do GOOS=$$goos GOARCH=${GOARCH} go build -ldflags="${LDFLAGS}" -o dist/hclq-$$goos-${GOARCH}; done
	# Remove binary used for testing
	rm -f dist/hclq

get:
	go get -u github.com/golang/dep/cmd/dep
	$(GOPATH)/bin/dep ensure
	# GitHub release tool
	go get -u github.com/tcnksm/ghr

install: get
	go install -ldflags="${LDFLAGS}"

publish: test dist
	( \
		VERSION=${VERSION}; \
		LINUX_FILENAME="hclq-linux-amd64"; \
		DARWIN_FILENAME="hclq-darwin-amd64"; \
		LINUX_HASH=$$(shasum -a 256 dist/$$LINUX_FILENAME | awk '{print $$1}'); \
		DARWIN_HASH=$$(shasum -a 256 dist/$$DARWIN_FILENAME | awk '{print $$1}'); \
		shasum -a 256 dist/* > dist/hclq-shasums; \
		if [ -n "$(IS_PUBLISH)" ]; then \
			ghr -u "$$GITHUB_USER" ${VERSION} dist/; \
		fi; \
	)

test: get build
	HCLQ_BIN=$$(pwd)/dist/hclq go test -v "./..."


.PHONY: get dist publish build install test clean
