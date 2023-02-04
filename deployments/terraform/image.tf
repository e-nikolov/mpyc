variable "nixos-image-path" {
  type    = string
  default = "../../bin/image/nixos.qcow2.gz"
}

resource "digitalocean_spaces_bucket_object" "nixos-image" {
  region = digitalocean_spaces_bucket.tf-state.region
  bucket = digitalocean_spaces_bucket.tf-state.name
  key    = basename(var.nixos-image-path)
  source = var.nixos-image-path
  acl    = "public-read"
  etag   = filemd5(var.nixos-image-path)
}

resource "digitalocean_custom_image" "nixos-image" {
  name    = "nixos-22.11"
  url     = "https://${digitalocean_spaces_bucket.tf-state.bucket_domain_name}/${digitalocean_spaces_bucket_object.nixos-image.key}"
  regions = local.all_regions
  tags    = ["nixos"]
  distribution = "Arch Linux"

  lifecycle {
    replace_triggered_by = [
      digitalocean_spaces_bucket_object.nixos-image
    ]
  }
}
