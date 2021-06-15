// Configure the Google Cloud provider
provider "google" {
 credentials = file("mercury-development-311316-4d258182aab4.json")
 project     = "mercury-development-311316"
 region      = "us-west1"
}


module "gce-instance" {
    source         = "./modules/instance"
    
    instance_name = var.instance_name
    machine_type = var.machine_type
    location = var.location
    disk_size = var.disk_size
    AZ_DATABASE = var.AZ_DATABASE
}

output "instance-external-ip" {
    value = module.gce-instance.ip
}
