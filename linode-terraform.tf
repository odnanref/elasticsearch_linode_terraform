terraform {
  required_providers {
      linode = {
        source = "linode/linode"
        version = "1.25.1"
      }
  }
}

# Linode Provider definition

provider  "linode" {
  token = var.token
}

locals {
    linode_ids = linode_instance.terraform[*].id
}

resource  "linode_instance"  "terraform" {
  count = 3
  image = "linode/debian11"
  label = "elasticsearch-${count.index + 1}"
  group = "elasticsearch"
  region = "us-southeast"
  type = "g6-nanode-1"
  authorized_keys = [ var.authorized_keys ]
  root_pass = var.root_pass

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vlan"
    label = "my-vlan"
    ipam_address = "10.0.0.${count.index + 1}/24"
  }

  provisioner "local-exec" {
    command = <<EOF
    sleep 120 && export ANSIBLE_HOST_KEY_CHECKING=False && \
    ansible-playbook -u root -i '${self.ip_address},' -e nodeip="10.0.0.${count.index + 1}" -e node="elasticsearch-${count.index + 1}" -e clustername=batch1  elasticsearch.yml
    EOF
  }
}

resource "linode_firewall" "ssh_inbound" {
  label = "firewall"
  tags  = ["ssh"]
  inbound_policy = "DROP"
  outbound_policy= "ACCEPT"
  inbound {
    label = "ssh"
    action = "ACCEPT"
    protocol = "TCP"
    ports = "22"
    ipv4 = ["77.54.135.43/32"]
  }

  linodes = local.linode_ids
}