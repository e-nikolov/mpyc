DEFAULT_SHELL = $(shell getent passwd ${USER} | awk -F: '{print $$NF}' )

TIMESTAMP := $(shell date +"%Y%m%d%H%M%S")

PSSH=pssh --user root --hosts=hosts-dns.pssh --timeout 0 --print --inline --verbose --outdir ./logs/${TIMESTAMP}

dev:
	nix develop --command "${DEFAULT_SHELL}"

ops:
	nix develop .#ops --command "${DEFAULT_SHELL}"

demo:
	cd ./demos && ./run-all.sh

image:
	docker load < $(shell nix build .#dockerImage --print-out-paths --no-link)
	docker push enikolov/mpyc-demo:v0.0.5

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
	terraform -chdir=./deployments/terraform output -json hosts-colmena > hosts.json
	terraform -chdir=./deployments/terraform output -json hosts-colmena-dns > hosts-dns.json
	terraform -chdir=./deployments/terraform output -json hosts-headscale > hosts-headscale.json
	terraform -chdir=./deployments/terraform output -json hosts-headscale-dns > hosts-headscale-dns.json
	terraform -chdir=./deployments/terraform output -raw hosts-pssh > hosts.pssh
	terraform -chdir=./deployments/terraform output -raw hosts-pssh-dns > hosts-dns.pssh

deploy:
	@echo ===================================================
	@echo Deploying with colmena
	@echo ===================================================
	colmena apply

destroy:
	TF_VAR_DESTROY_NODES=1 terraform -chdir=./deployments/terraform apply
	terraform -chdir=./deployments/terraform output -json hosts-colmena > hosts.json
	terraform -chdir=./deployments/terraform output -json hosts-colmena-dns > hosts-dns.json
	terraform -chdir=./deployments/terraform output -raw hosts-pssh > hosts.pssh
	terraform -chdir=./deployments/terraform output -raw hosts-pssh-dns > hosts-dns.pssh
	# ./scripts/destroy-tailscale.sh


destroy-all:
	terraform -chdir=./deployments/terraform destroy
	terraform -chdir=./deployments/terraform output -json hosts-colmena > hosts.json
	terraform -chdir=./deployments/terraform output -json hosts-colmena-dns > hosts-dns.json
	terraform -chdir=./deployments/terraform output -raw hosts-pssh > hosts.pssh
	terraform -chdir=./deployments/terraform output -raw hosts-pssh-dns > hosts-dns.pssh
 
sync:
	prsync --par 4 --user root --hosts hosts-dns.pssh --compress --archive --recursive --verbose --inline ./ /root/mpyc

reboot-nodes:
	$(PSSH) "reboot --force"

ssh-add:
	ssh-add -l | grep -q "no identities" && ssh-add || true

logdir:
	mkdir -p ./logs/${TIMESTAMP}
	rm -rf ./logs/latest
	ln -rs ./logs/${TIMESTAMP} ./logs/latest 

run: logdir
	$(PSSH) "cd /root/mpyc && ./prun.sh ${cmd}"

rund: logdir
	$(PSSH) "cd /root/mpyc && ./prund.sh ${cmd}"

rundns: logdir
	$(PSSH) "cd /root/mpyc && ./prundns.sh ${cmd}"

shuffle:
	shuf hosts-dns.pssh -o hosts-dns.pssh

do-image:
	nix build .#digitalOceanImage -o bin/image

do-image-headscale:
	nix build .#digitalOceanHeadscaleImage -o bin/headscale

natpunch-client:
	sudo natpunch-client natpunch-client 164.90.201.6:12345 diRHFtiG11gbHSatcwViALlZbVBImBE5ufBkLOpj1gI= -c

natpunch-server:
	sudo natpunch-client wg-demo-server 164.90.201.6:12345 diRHFtiG11gbHSatcwViALlZbVBImBE5ufBkLOpj1gI= -c
