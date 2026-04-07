.PHONY: build run test clean

build:
	go build -o server ./cmd/server

run: build
	./server

test:
	go test -v ./...

clean:
	rm -f server
