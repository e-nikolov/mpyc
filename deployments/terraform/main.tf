provider "digitalocean" {}

provider "tailscale" {}

# locals {
#   ssh_key_paths = toset(flatten([
#     for pattern in var.SSH_KEY_PATHS :
#     formatlist("/%s", fileset("/", abspath(pathexpand(pattern))))
#   ]))
# }

locals {
  nodes = [
    { region = "ams3", num = 3 },
    { region = "sfo3", num = 1 },
    { region = "nyc3", num = 1 },
    { region = "sgp1", num = 1 },
  ]

  nodes_expanded = flatten([
    for node in local.nodes : [
      for i in range(node.num) :
      merge(node, {
        name = "mpyc-demo--${node.region}-${i}"
      })
    ]
  ])

  all_regions = distinct(local.nodes[*].region)

  generation = 1
}

output "node" {
  value = local.nodes_expanded
}

resource "digitalocean_droplet" "mpyc-node" {
  for_each = { for node in local.nodes_expanded : node.name => node }

  image    = digitalocean_custom_image.nixos-image.id
  name     = each.value.name
  region   = each.value.region
  size     = "s-1vcpu-1gb"
  ssh_keys = [for key in digitalocean_ssh_key.ssh-keys : key.fingerprint]

  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
  }

  # provisioner "file" {
  #   content     = tailscale_tailnet_key.keys.key
  #   destination = "/root/keys/tailscale"
  # }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/keys/",
      "echo ${tailscale_tailnet_key.keys.key} > /var/keys/tailscale",
      "tailscale up --auth-key file:/var/keys/tailscale"
    ]
  }

  lifecycle {
    replace_triggered_by = [
      tailscale_tailnet_key.keys
    ]
  }
}


# resource "null_resource" "upload-mpyc" {
#   for_each = { for node in local.nodes_expanded : node.name => node }

#   connection {
#     type  = "ssh"
#     user  = "root"
#     agent = true
#     host  = each.value.ipv4_address
#   }
#   provisioner "file" {
#     # triggers = {

#     # }
#     source      = "../../"
#     destination = "/root/mpyc"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "cd /root/mpyc",
#       "nix develop",
#       "python ./demos/secretsanta.py"
#     ]
#   }
# }

# resource "tailscale_tailnet_key" "keys" {
#   for_each = { for i, node in local.nodes_expanded : node.name => node }

#   # name          = each.value.name
#   reusable      = true
#   ephemeral     = false
#   preauthorized = true
# }
resource "tailscale_tailnet_key" "keys" {
  # name          = each.value.name
  reusable      = true
  ephemeral     = true
  preauthorized = true
  tags          = ["tag:mpyc"]
}

# module "deploy_nixos" {
#   source = "github.com/tweag/terraform-nixos//deploy_nixos?ref=646cacb12439ca477c05315a7bfd49e9832bc4e3"
#   # for_each = { for node in local.nodes_expanded : node.name => node }
#   # for_each = [for i, node in local.nodes_expanded : node]
#   for_each = { for i, node in local.nodes_expanded : node.name => node }
#   # for_each = toset([for node in digitalocean_droplet.mpyc-node : node.ipv4_address])

#   nixos_config = ""
#   # nixos_config    = "doHost"
#   build_on_target = true
#   # flake       = true
#   target_user = "root"
#   target_host = digitalocean_droplet.mpyc-node[each.key].ipv4_address # each.value
#   # target_host  = each.value.ipv4_address
#   ssh_agent = true
#   keys = {
#     # "tailscale" = "${tailscale_tailnet_key.keys}"
#     foo = "bar"
#   }
# }

output "regions" {
  value = local.all_regions
}
output "tailscale" {
  value     = tailscale_tailnet_key.keys
  sensitive = true
}
output "nixos-etag" {
  value = digitalocean_spaces_bucket_object.nixos-image.etag
}

output "hosts" {
  value = jsonencode([for node in digitalocean_droplet.mpyc-node : { "${node.name}" : node.ipv4_address }])
}

output "hosts2" {
  value = { for node in digitalocean_droplet.mpyc-node : node.name => {} }
}

output "nixos-id" {
  value = digitalocean_custom_image.nixos-image.image_id
}

output "nixos-id2" {
  value = digitalocean_custom_image.nixos-image.id
}
