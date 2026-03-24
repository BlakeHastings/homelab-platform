terraform {
  # State stored on the terraform-runner VM at a fixed path.
  # All provisioning workflows run on that VM (label: self-hosted-infra),
  # so state is always co-located with execution — no external state service needed.
  #
  # REPLACE: my-vm with your VM name
  backend "local" {
    path = "/home/ubuntu/terraform-state/my-vm/terraform.tfstate"
  }
}
