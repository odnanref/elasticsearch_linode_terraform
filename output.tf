output "ips" {
  value = linode_instance.terraform.*.ipv4
}