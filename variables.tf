variable "profile" { default = "<ADD_REAL_AWS_PROFILE_HERE>" }

variable "target_instance_type" {
  default = "m6i.large"
}

variable "source_instance_type" {
  default = "m6i.4xlarge"
}

variable "ssh_public_key" {
  default = "ssh-rsa ADD_REAL_KEY_HERE"
}

variable "username" {
  default = "efagerho"
}
