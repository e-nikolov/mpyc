terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
    ssh = {
      source = "loafoe/ssh"
    }
  }
}
