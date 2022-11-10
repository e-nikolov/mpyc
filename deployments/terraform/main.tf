provider "digitalocean" {}

provider "tailscale" {}

# locals {
#   ssh_key_paths = toset(flatten([
#     for pattern in var.SSH_KEY_PATHS :
#     formatlist("/%s", fileset("/", abspath(pathexpand(pattern))))
#   ]))
# }

locals {
  node_definitions = var.DESTROY_NODES != "" ? [
    { region = "ams3", num = 0 },
    { region = "sfo3", num = 0 },
    { region = "nyc3", num = 0 },
    { region = "sgp1", num = 0 },
    ] : [
    { region = "ams3", num = 3 },
    { region = "sfo3", num = 1 },
    { region = "nyc3", num = 1 },
    { region = "sgp1", num = 1 },
  ]

  nodes_expanded = flatten([
    for node in local.node_definitions : [
      for i in range(node.num) :
      merge(node, {
        name = "mpyc-demo--${node.region}-${i}"
      })
    ]
  ])

  nodes = {
    for node in local.nodes_expanded :
    node.name => merge(node, {
      hostname = "${node.name}-${random_id.mpyc-node-hostname[node.name].hex}"
    })
  }

  all_regions = distinct(local.node_definitions[*].region)

  generation = 1
}

resource "random_id" "mpyc-node-hostname" {
  for_each = { for node in local.nodes_expanded : node.name => node }

  keepers = {
    # Generate a new id each time we switch to a new AMI id
    hostname = each.key
  }

  byte_length = 4
}


output "node" {
  value = local.nodes_expanded
}
output "node-hostnames" {
  value = { for i, node in local.nodes_expanded : node.name => merge(node, { hostname = "${node.name}-${random_id.mpyc-node-hostname[node.name].hex}" }) }
}

resource "digitalocean_droplet" "mpyc-node" {
  for_each = local.nodes

  image    = digitalocean_custom_image.nixos-image.id
  name     = each.value.hostname
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

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "tailscale logout"
    ]
  }

  lifecycle {
    replace_triggered_by = [
      tailscale_tailnet_key.keys
    ]
  }
}


# resource "null_resource" "upload-mpyc" {
#   for_each = local.nodes

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
#   for_each = local.nodes

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

output "hosts-colmena" {
  value = { for node in local.nodes : node.hostname => {} }
}

output "hosts-pssh" {
  value = join("", [for node in local.nodes : "root@${node.hostname}\n"])
}

output "nixos-id" {
  value = digitalocean_custom_image.nixos-image.image_id
}

output "nixos-id2" {
  value = digitalocean_custom_image.nixos-image.id
}
