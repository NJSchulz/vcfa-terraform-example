data "vra_project" "default" {
  name = "Default"
}

data "vra_catalog_item" "blueprint" {
  name = "NSX Ubuntu Webserver (AWX)"  # Adjust if needed
}

resource "vra_deployment" "vcfa_deployment" {
  name            = var.hostname  # or a custom var like var.deployment_name
  description     = "TF Deployment into VCFA"
  project_id      = data.vra_project.default.id
  catalog_item_id = data.vra_catalog_item.blueprint.id

  inputs = {
    hostname     = var.hostname
    ipAddress    = var.ipAddress
    gateway      = var.gateway
    dns          = var.dns
    prefixLength = var.prefixLength
  }
}
