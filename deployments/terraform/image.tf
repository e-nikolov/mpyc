resource "digitalocean_spaces_bucket_object" "nixos-image" {
  region = digitalocean_spaces_bucket.tf-state.region
  bucket = digitalocean_spaces_bucket.tf-state.name
  key    = "nixos-22.11.qcow2.gz"
  source = "../../bin/image/nixos.qcow2.gz"
  acl    = "public-read"
}

resource "digitalocean_custom_image" "nixos-image" {
  name    = "nixos-22.11"
  url     = "https://${digitalocean_spaces_bucket.tf-state.bucket_domain_name}/${digitalocean_spaces_bucket_object.nixos-image.key}"
  regions = ["ams3", "nyc3"]
  tags    = ["nixos"]
}
