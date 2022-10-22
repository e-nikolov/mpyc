DEFAULT_SHELL = $(shell getent passwd ${USER} | awk -F: '{print $$NF}' )

dev:
	nix develop --command "${DEFAULT_SHELL}"

ops:
	nix develop .#ops --command "${DEFAULT_SHELL}"

demo:
	cd ./demos && ./run-all.sh

image:
	docker load < $(shell nix build --print-out-paths --no-link)
	docker push enikolov/mpyc-demo:0.0.1

image-arm:
	docker load < $(shell nix build .#arm --print-out-paths --no-link)
	docker push enikolov/mpyc-demo-arm:0.0.1

run-image:
	docker run enikolov/mpyc-demo:0.0.1
