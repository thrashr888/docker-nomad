.PHONY: bin image push release clean

TAG=vancluever/nomad
VERSION=0.8.4
ARCH=linux_arm

GO_VERSION=1.10.2

bin:
	rm -rf 0.X/pkg
	mkdir -p 0.X/pkg
	wget -P 0.X/pkg https://releases.hashicorp.com/nomad/$(VERSION)/nomad_$(VERSION)_$(ARCH).zip
	unzip 0.X/pkg/nomad_$(VERSION)_$(ARCH).zip
	
	docker run --rm -v $(shell pwd)/0.X/pkg:/tmp/pkg golang:$(GO_VERSION)-alpine sh -x -c '\
	apk add --no-cache alpine-sdk && \
	go get -d github.com/hashicorp/nomad && \
	cd $$GOPATH/src/github.com/hashicorp/nomad && \
	git checkout v$(VERSION) && \
	go build --ldflags "all= \
		-X github.com/hashicorp/nomad/version.GitCommit=$$(git rev-parse HEAD) \
		" -o /tmp/pkg/nomad'

image: bin
	docker build \
		--tag $(TAG):latest \
		--tag $(TAG):$(VERSION) \
		--build-arg NOMAD_VERSION=$(VERSION) \
		0.X/

push: image
	docker push $(TAG):latest
	docker push $(TAG):$(VERSION)

release: push

clean:
	rm -rf 0.X/pkg
	docker rmi -f $(TAG)
