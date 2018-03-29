variable region {
  description = "Digital Ocean region"
  default     = "nyc3"
}

variable "token" {
  description = "Digital Ocean API Token"
}

variable pub_key_path {
  description = "Path to bastion ssh public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable ssh_key_path {
  description = "Path to bastion ssh private key"
  default     = "~/.ssh/id_rsa"
}

variable web_server_params {
  default = {
    "count" = "2"
  }
}