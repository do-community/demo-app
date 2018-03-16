variable region {
  description = "Digital Ocean region"
  default     = "nyc3"
}

variable "token" {
  description = "Digital Ocean API Token"
}

variable pub_key_path {
  description = "Path to bastion ssh-key"
  default     = "~/.ssh/id_rsa.pub"
}