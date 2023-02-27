DEFAULT_SHELL = $(shell getent passwd ${USER} | awk -F: '{print $$NF}' )

dev:
	nix develop --command "${DEFAULT_SHELL}"

ops:
	nix develop .#ops --command "${DEFAULT_SHELL}"

demo:
	cd ./demos && ./run-all.sh

image:
	docker load < $(shell nix build .#docker --print-out-paths --no-link)
	docker push enikolov/mpyc-demo:nix-v0.0.1

image-nix-arm:
	docker load < $(shell nix build .#arm --print-out-paths --no-link)
	docker push enikolov/mpyc-demo:nix-armv7l-v0.0.1

image-docker:
	docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 . --tag enikolov/mpyc-demo:slim-v0.0.1 --push

run-image:
	docker run enikolov/mpyc-demo:nix-v0.0.1

provision:
	@echo ===================================================
	@echo Provisioning with terraform
	@echo ===================================================
	terraform -chdir=./deployments/terraform apply
	terraform -chdir=./deployments/terraform output -json hosts-colmena> hosts.json
	terraform -chdir=./deployments/terraform output -json hosts-headscale> hosts-headscale.json
	terraform -chdir=./deployments/terraform output -raw hosts-pssh> hosts.pssh

deploy:
	@echo ===================================================
	@echo Deploying with colmena
	@echo ===================================================
	colmena apply

destroy:
	TF_VAR_DESTROY_NODES=1 terraform -chdir=./deployments/terraform apply
	terraform -chdir=./deployments/terraform output -json hosts-colmena> hosts.json
	terraform -chdir=./deployments/terraform output -raw hosts-pssh> hosts.pssh
	# ./scripts/destroy-tailscale.sh


destroy-all:
	terraform -chdir=./deployments/terraform destroy
	terraform -chdir=./deployments/terraform output -json hosts-colmena> hosts.json
	terraform -chdir=./deployments/terraform output -raw hosts-pssh> hosts.pssh
 
sync:
	prsync -p 4 -h hosts.pssh -zarv -p 4 ./ /root/mpyc

t=$(shell date +%s)

ssh-add:
	ssh-add -l | grep -q "no identities" && ssh-add || true

run:
	mkdir -p ./logs/$t
	rm -rf ./logs/latest
	ln -rs ./logs/$t ./logs/latest 
	pssh -t 0 -P -h hosts.pssh -iv -o ./logs/$t "cd /root/mpyc && ./prun.sh ${cmd}"

rund:
	mkdir -p ./logs/$t
	rm -rf ./logs/latest
	ln -rs ./logs/$t ./logs/latest 
	pssh -t 0 -P -h hosts.pssh -iv -o ./logs/$t "cd /root/mpyc && ./prund.sh ${cmd}"

shuffle:
	shuf hosts.pssh -o hosts.pssh

do-image:
	nix build .#digitalOceanImage -o bin/image

do-image-headscale:
	nix build .#digitalOceanHeadscaleImage -o bin/headscale
