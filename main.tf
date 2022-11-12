
# Define and Initialize provider

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.81.0"
    }
  }
}

provider "yandex" {
  zone = "ru-central1-a"
}


# Create network and subnetwork in it, add external ipv4 address

resource "yandex_vpc_network" "foo" {}

resource "yandex_vpc_subnet" "foo" {
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["10.2.0.0/16"]
  network_id     = yandex_vpc_network.foo.id
}

resource "yandex_vpc_address" "addr" {
  name = "otus-vm-address"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

# Get OS Image UUID

data "yandex_compute_image" "my_image" {
  family = var.vmimage
}

# Ansible inventory file

resource "local_file" "ansible_inventory" {
    content = "otus-vm ansible_host=${yandex_vpc_address.addr.external_ipv4_address[0].address} ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_user=ubuntu"
    filename = "./inventory"
}

# Create VM

resource "yandex_compute_instance" "otus-vm" {
  name                      = var.vmname
  platform_id               = "standard-v1"
  allow_stopping_for_update = true
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
    }
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.foo.id
    nat_ip_address = yandex_vpc_address.addr.external_ipv4_address[0].address
    nat            = true
  }

  # Place our ssh key in VM 
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  # Skip image ID changes in order not to reinstall entire VM
  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image_id]
  }

  # Provision VM With ansible
  provisioner "local-exec" {
    command = "ansible-playbook -i ./inventory nginx-install.yml"
  }

}


# Output public ipv4

output "ipv4_address" {
  description = "IP Address of created VM"
  value       = yandex_vpc_address.addr.external_ipv4_address[0].address
}