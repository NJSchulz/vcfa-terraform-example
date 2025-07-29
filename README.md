# VCFA Terraform Deployment

This repository facilitates **VMware Cloud Foundation Automation (VCFA)** blueprint deployments using **Terraform**. It integrates with **Aria Automation (vRA)** and is designed to work with a **self-hosted GitHub Actions runner** for streamlined on-premises automation.

## Features

- Terraform-based provisioning of Aria Automation blueprints
- Dynamic input configuration via GitHub workflow dispatch
- Per-deployment state management for easy apply and destroy operations
- Integrated debugging and log artifact upload
- Cloud-init and Ansible integration to configure VMs post-deployment

## Requirements

- VMware Aria Automation / VCFA environment
- Terraform (>= 1.6)
- GitHub repository with:
  - Workflow file (`.github/workflows/deploy-vcfa.yml`)
  - Terraform files (`tf/main.tf`, `tf/variables.tf`, etc.)
- Self-hosted GitHub Actions runner with systemd service configured and running
- Backend directory for per-deployment `tfstate` files (e.g., `/home/user/tfstate/`)

## Deployment Variables

The following inputs are accepted by the GitHub workflow:

- `action`: `apply` or `destroy`
- `hostname`: Hostname of the VM
- `ipAddress`: Static IP address
- `gateway`: Default gateway
- `prefixLength`: Subnet mask prefix length
- `dns`: (optional) DNS servers (can be pulled from secrets)

All variables are automatically passed into Terraform using the `TF_VAR_` environment variable convention.

## Backend Configuration

A local backend is used with a dynamic path, based on the deployment name. This enables isolated state tracking per deployment.

Example backend config:

```hcl
terraform {
  backend "local" {}
}
```

In practice, this path is overridden dynamically during the workflow using:

```bash
terraform init -backend-config="path=$HOME/tfstate/${DEPLOYMENT_NAME}.tfstate" -backend-config="path=/home/schulz/tfstate/${DEPLOYMENT_NAME}.tfstate"
```

## GitHub Workflow Overview

The workflow does the following:

1. Checks out the repository
2. Initializes Terraform with a dynamic `tfstate` file
3. Validates and plans the configuration
4. Applies or destroys the deployment based on input
5. Uploads debug logs on failure
6. Moves `tfstate` to a permanent directory per deployment name

## Local Development

You can run the Terraform workflow manually on your runner:

```bash
export TF_VAR_hostname=<hostname>
export TF_VAR_ipAddress=<ipAddress>
export TF_VAR_gateway=<gateway>
export TF_VAR_dns='["<dnsServerIP>"]'
export TF_VAR_prefixLength=<prefixLength>
export DEPLOYMENT_NAME=$TF_VAR_hostname

terraform init -backend-config="path=$HOME/tfstate/${DEPLOYMENT_NAME}.tfstate"
terraform apply -auto-approve
```

To destroy the deployment:

```bash
terraform init -backend-config="path=$HOME/tfstate/${DEPLOYMENT_NAME}.tfstate"
terraform destroy -auto-approve
```

## Self-hosted Runner Setup

To ensure your runner is always listening:

```bash
sudo systemctl status actions.runner.<USERNAME>-<REPO>.runner-name.service

# example
# sudo systemctl status actions.runner.NJSchulz-vcfa-terraform.terraform.service
```

To restart if needed:

```bash
sudo systemctl restart actions.runner.<USRENAME>-<REPO>.runner-name.service

# example
# sudo systemctl restart actions.runner.NJSchulz-vcfa-terraform.terraform.service
```

You can run **multiple runners** on the same VM by placing each in its own directory and registering with a unique name.

## Why Use This?

- Full GitOps control of VCFA blueprint deployments
- Repeatable infrastructure via Terraform
- Easy rollback and teardown
- GitHub UI and API integration
- Developer-friendly and auditable

## License

MIT
