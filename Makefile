
dev:
	nix develop

ops:
	nix develop .#ops

demo:
	cd ./demos && ./run-all.sh

image:
	docker load < $(nix build .#docker --print-out-paths --no-link)
	docker push e-nikolov:mpyc-demo:v0.0.1
