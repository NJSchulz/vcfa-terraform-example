# VCFA Terraform Deployment

This **example repository** deploys **VCF Automation templates (blueprints in the API)** from the catalog using **Terraform**. It integrates with **VMware Cloud Foundation Automation (VCFA)** and is designed to work with a **self-hosted GitHub Actions runner** for streamlined on-premises automation.

> **Which VCF Automation org?** This example targets a **VCF 9 VM Apps organization** and uses the [`vmware/vra`](https://registry.terraform.io/providers/vmware/vra/latest) provider (catalog items, templates, deployments). **All Apps organizations** use the [`vmware/vcfa`](https://registry.terraform.io/providers/vmware/vcfa/latest) provider instead, which this repo does not cover.

## Features

- Terraform-based provisioning of VCF Automation templates via catalog items
- Dynamic input configuration via GitHub workflow dispatch
- Per-deployment state management for easy apply and destroy operations
- Plan output that matches the action (`terraform plan -destroy` on destroy runs)
- One run at a time per deployment name (`concurrency` group)
- Hostname validation before it is used in the state file path
- Cloud-init and Ansible integration to configure VMs post-deployment

## Requirements

- VMware Cloud Foundation Automation (VCF 9) with a **VM Apps** organization
- Terraform (>= 1.2.0, matching `required_version` in `tf/provider.tf`)
- `vmware/vra` provider `~> 0.11.0` (pinned in `tf/provider.tf`; see [Provider version](#provider-version))
- A VCFA **refresh token** for the VM Apps org, created in the VCFA UI under **My Account > API Tokens** (90-day lifetime by default, so plan to rotate the `VCFA_REFRESH_TOKEN` secret)
- GitHub repository with:
  - Workflow file (`.github/workflows/deploy-vcfa.yml`)
  - Terraform files (`tf/main.tf`, `tf/variables.tf`, etc.)
- Self-hosted GitHub Actions runner with systemd service configured and running (runner v2.327.1 or newer, for Node 24 actions)
- Backend directory for per-deployment `tfstate` files (e.g., `/home/user/tfstate/`)

## Configuration

### Secrets (required)

| Secret | Purpose |
| --- | --- |
| `VCFA_URL` | VCF Automation URL |
| `VCFA_REFRESH_TOKEN` | Refresh token from **My Account > API Tokens** |
| `VCFA_ORG` | VM Apps organization name |
| `VCFA_INSECURE` | `true` to skip TLS verification (lab only), otherwise `false` |

### Deployment defaults (optional)

Used when a workflow input is left blank. Each is read from a **repository variable** first (Settings > Secrets and variables > Actions > Variables), then from a **secret** of the same name, so existing secret-based setups keep working. Repository variables are recommended for these non-sensitive values, because secret values are masked as `***` in logs (including the state file path).

`HOSTNAME`, `IPADDRESS`, `GATEWAY`, `DNS`, `PREFIXLENGTH`

`DNS` has no workflow input and always comes from the variable or secret.

### Project and catalog item

`tf/variables.tf` defines `project_name` (default `Default`) and `catalog_item_name` (default `NSX Ubuntu Webserver (AWX)`). Change the defaults, or set `TF_VAR_project_name` / `TF_VAR_catalog_item_name`, to match your VCFA project and released template.

## Deployment Variables

The following inputs are accepted by the GitHub workflow:

- `action`: `apply` or `destroy`
- `hostname`: Hostname of the VM (also the deployment name and state file name). Must match `^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$`; the run fails fast otherwise.
- `ipAddress`: Static IP address
- `gateway`: Default gateway
- `prefixLength`: Subnet mask prefix length
- `dns`: not an input; DNS servers come from the `DNS` variable or secret

All variables are automatically passed into Terraform using the `TF_VAR_` environment variable convention.

> **Blank hostname = one shared state file.** If `hostname` is left blank, the workflow falls back to the `HOSTNAME` variable/secret, so every such run uses the same deployment name and the same `tfstate` file. A second `apply` with different IP inputs **updates the existing deployment** instead of creating a new one. Pass a unique `hostname` for each deployment you want to keep separate.

## Backend Configuration

A local backend is used with a dynamic path, based on the deployment name. This enables isolated state tracking per deployment.

Example backend config:

```hcl
terraform {
  backend "local" {}
}
```

In practice, the path is set during the workflow using:

```bash
terraform init -backend-config="path=$HOME/tfstate/${DEPLOYMENT_NAME}.tfstate"
```

State is written directly to `$HOME/tfstate/` on the runner. It is plaintext, lives only on that runner, and is not backed up by this workflow; consider a remote backend for anything beyond a lab.

## GitHub Workflow Overview

The workflow does the following:

1. Checks out the repository
2. Validates the hostname / deployment name
3. Initializes Terraform with a per-deployment `tfstate` file under `$HOME/tfstate/`
4. Validates and plans the configuration (`plan -destroy` for destroy runs)
5. Applies or destroys the deployment based on input
6. Shows the resulting state

Runs for the same deployment name are queued, not run in parallel (`concurrency` with `cancel-in-progress: false`). The workflow does not upload logs as artifacts; on a public repo artifacts are readable by anyone, and Terraform debug logs can contain credentials.

## Provider version

`tf/provider.tf` pins `vmware/vra` to `~> 0.11.0` (resolves to 0.11.x), which is the version this example was tested with. Newer releases changed how deployment inputs are handled (0.16.0 switched to sending deployment inputs as strings, and 0.17.x changed drift detection and updates for array/object inputs), so re-test inputs such as `dns` before bumping the pin.

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
sudo systemctl restart actions.runner.<USERNAME>-<REPO>.runner-name.service

# example
# sudo systemctl restart actions.runner.NJSchulz-vcfa-terraform.terraform.service
```

You can run **multiple runners** on the same VM by placing each in its own directory and registering with a unique name.

> GitHub recommends self-hosted runners only for private repositories. This workflow only runs on `workflow_dispatch`, which limits exposure, but if you fork this as a public repo, restrict which workflows and repositories can use the runner.

## Why Use This?

- Full GitOps control of VCF Automation template deployments
- Repeatable infrastructure via Terraform
- Easy rollback and teardown
- GitHub UI and API integration
- Developer-friendly and auditable

## License

MIT
