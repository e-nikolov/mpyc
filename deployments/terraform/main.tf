provider "digitalocean" {}

resource "digitalocean_droplet" "mpyc-node" {
  image    = digitalocean_custom_image.nixos-image.id
  name     = "mpyc-node-${count.index + 1}"
  region   = "ams3"
  size     = "s-1vcpu-1gb"
  ssh_keys = [for key in digitalocean_ssh_key.ssh-keys : key.fingerprint]

  count = 5
}

module "deploy_nixos" {
  source = "github.com/tweag/terraform-nixos//deploy_nixos?ref=646cacb12439ca477c05315a7bfd49e9832bc4e3"

  for_each = toset([for node in digitalocean_droplet.mpyc-node : node.ipv4_address])

  nixos_config = "doHost"
  flake        = true
  target_user  = "root"
  target_host  = each.value
  ssh_agent    = true
}

output "hosts" {
  value = jsonencode([for node in digitalocean_droplet.mpyc-node : { "${node.name}" : node.ipv4_address }])
}

output "hosts2" {
  value = [for node in digitalocean_droplet.mpyc-node : { "${node.name}" : node.ipv4_address }]
}

output "nixos-id" {
  value = digitalocean_custom_image.nixos-image.image_id
}

output "nixos-id2" {
  value = digitalocean_custom_image.nixos-image.id
}
