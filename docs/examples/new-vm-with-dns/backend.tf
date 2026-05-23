terraform {
  backend "local" {
    # REPLACE: my-vm with your VM name. State lives on the terraform-runner.
    path = "/home/ubuntu/terraform-state/my-vm/terraform.tfstate"
  }
}
