variable project {
  description = "Project name"
}
variable region {
  description = "Region name"
  default = "europe-west1"
}
variable public_key_path {
  description = "Path to the public key used to connect to instance"
}
variable private_key_path {
  description = "Path to the private key used for ssh access"
  default     = "~/.ssh/mikh_androsov"
}
variable "public_key" {
  description = "Public Key in RSA"
  default     = "mikh_androsov:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3ZGfEhcYLORqG4R8fYssFdXYmSOsw6HjM1rfqc9zS4golKhrCz+OXM0vQ3XCPraA+msD2N0MY88CI9m0LjkN1s+qY4AcEmcepeIg/IMqJXG/IdazVA7tDFD6/TMlgjXO9dDAkrDa/p/MuW113jHWkd89N+T5dGsirsRDnA7yDmJwJB+HFH//mY4ZUwNPqKJE0MilnSBLt+7rACe1jXFbNfrYMgXNoGWybUwnXDv8LusOHnO4+sDnVxy4NN6kKwHT6RDx4SYrGe0LsBwK5xY0ji5RM0jUq+NLTRcXeAOqP2zLfUM4wLn1+Js9vOYLjefQQdHqCPv8ygnyIWjAceLlX mikh_androsov"
}
variable zone {
  description = "Zone"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-docker"
}
variable "machine_type" {
  description = "Standart machine type"
  default     = "f1-micro"
}
variable "source_ranges" {
  description = "Source ranges IP addresses"
  default     = ["0.0.0.0/0"]
}