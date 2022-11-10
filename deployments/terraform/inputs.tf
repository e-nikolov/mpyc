variable "nixos-image-path" {
  type    = string
  default = "../../bin/image/nixos.qcow2.gz"
}

variable "SSH_KEY_PATHS" {
  type    = set(string)
  default = ["./ssh/*.pub"]
}

variable "DESTROY_NODES" {
  type    = string
  default = ""
}
