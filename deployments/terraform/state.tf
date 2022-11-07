

resource "digitalocean_spaces_bucket" "tf-state" {
  name   = "mpyc-tf-state"
  region = "ams3"
}
