resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_address" "external_ip" {
  name         = "${var.instance_name}-external-ip"
  address_type = "EXTERNAL"
  
}


// A single Compute Engine instance
resource "google_compute_instance" "instance" {

  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.location
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20210223"
      size = var.disk_size
    }
  }

  metadata = {
    sshKeys = "root:${tls_private_key.ssh-key.public_key_openssh}"
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.external_ip.address
    }
  }

  // for allowing http(s) traffic
  tags = ["http-server","https-server"]

  provisioner "remote-exec" {

   connection {
    host = google_compute_address.external_ip.address
    type = "ssh"
    user = "root"
    private_key = tls_private_key.ssh-key.private_key_pem
  }

  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
    "sudo apt-get update",
    "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
    "sudo docker swarm init",
    "sudo mkdir -p /opt/traefik",
    "sudo touch /opt/traefik/acme.json",
    "sudo chmod 600 /opt/traefik/acme.json",
    "sudo mkdir -p ${var.AZ_DATABASE}",
    "sudo adduser --disabled-password --gecos '' deployment",
    "sudo usermod -a -G sudo deployment",
    "echo 'deployment ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers",
    "cd /home/deployment/",
    "mkdir git",
    "sudo chmod 777 git",
    "sudo usermod -aG syslog deployment"
  ]
}

}

output "ip" {
  value = google_compute_instance.instance.network_interface.0.access_config.0.nat_ip
}
