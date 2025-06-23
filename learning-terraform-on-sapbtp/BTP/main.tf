resource "random_uuid" "uuid" {}
data "btp_globalaccount" "this" {}

locals {
  subaccount_name      = "${var.subaccount_stage} ${var.project_name}"
  subaccount_subdomain = join("-", [lower(replace("${var.subaccount_stage}-${var.project_name}", " ", "-")), random_uuid.uuid.result])
  beta_enabled         = var.subaccount_stage == "PROD" ? false : true
  subaccount_cf_org    = local.subaccount_subdomain
  service_name__connectivity    = "connectivity"
  service_name__destination     = "destination"
}

resource "btp_subaccount" "project_subaccount" {
  name         = local.subaccount_name
  subdomain    = local.subaccount_subdomain
  region       = var.subaccount_region
  beta_enabled = local.beta_enabled
  labels = {
    "stage"      = [var.subaccount_stage]
    "costcenter" = [var.project_costcenter]
  }
}

module "srvc_baseline" {
  source        = "./modules/srvc-baseline"
  subaccount_id = btp_subaccount.project_subaccount.id
  project_name  = var.project_name
  project_stage = var.subaccount_stage
}

data "btp_subaccount_environments" "all" {
  subaccount_id = btp_subaccount.project_subaccount.id
}

resource "terraform_data" "cf_landscape_label" {
  input = length(var.cf_landscape_label) > 0 ? var.cf_landscape_label : [for env in data.btp_subaccount_environments.all.values : env if env.service_name == "cloudfoundry" && env.environment_type == "cloudfoundry"][0].landscape_label
}

resource "btp_subaccount_environment_instance" "cloudfoundry" {
  subaccount_id    = btp_subaccount.project_subaccount.id
  name             = local.subaccount_cf_org
  environment_type = "cloudfoundry"
  service_name     = "cloudfoundry"
  plan_name        = "trial"
  landscape_label  = terraform_data.cf_landscape_label.output
  parameters = jsonencode({
    instance_name = local.subaccount_cf_org
  })
}

resource "btp_subaccount_role_collection_assignment" "emergency_adminitrators" {
  for_each             = toset(var.subaccount_emergency_admins)
  subaccount_id        = btp_subaccount.project_subaccount.id
  role_collection_name = "Subaccount Administrator"
  user_name            = each.value
}

# ------------------------------------------------------------------------------------------------------
# Setup SAP Build Code
# ------------------------------------------------------------------------------------------------------
module "build_code" {
  source = "./modules/build_code/"

  subaccount_id = btp_subaccount.project_subaccount.id

  application_studio_admins             = var.application_studio_admins
  application_studio_developers         = var.application_studio_developers
  application_studio_extension_deployer = var.application_studio_extension_deployer

  build_code_admins     = var.build_code_admins
  build_code_developers = var.build_code_developers
}

# ------------------------------------------------------------------------------------------------------
# Setup SAP Build Process Automation
# ------------------------------------------------------------------------------------------------------
module "build_process_automation" {
  source = "./modules/build_process_automation"

  subaccount_id = btp_subaccount.project_subaccount.id

  process_automation_admins       = var.process_automation_admins
  process_automation_developers   = var.process_automation_developers
  process_automation_participants = var.process_automation_participants
}

# ------------------------------------------------------------------------------------------------------
# Setup connectivity (Connectivity Service)
# ------------------------------------------------------------------------------------------------------
# Entitle
resource "btp_subaccount_entitlement" "connectivity" {
  subaccount_id = btp_subaccount.project_subaccount.id
  service_name  = local.service_name__connectivity
  plan_name     = var.service_plan__connectivity
}

# ------------------------------------------------------------------------------------------------------
# Setup destination (Destination Service)
# ------------------------------------------------------------------------------------------------------
# Entitle
resource "btp_subaccount_entitlement" "destination" {
  subaccount_id = btp_subaccount.project_subaccount.id
  service_name  = local.service_name__destination
  plan_name     = var.service_plan__destination
}

# ------------------------------------------------------------------------------------------------------
# Setup SAP Integration Suite
# ------------------------------------------------------------------------------------------------------
module "integration_suite" {
  source                         = "./modules/integration_suite"
  subaccount_id                  = btp_subaccount.project_subaccount.id
  service_plan__integrationsuite = var.service_plan__integrationsuite
  cloud_connector_admins         = var.cloud_connector_admins
  cpi_admins                     = var.cpi_admins
  cpi_developers                 = var.cpi_developers
  integration_provisioners       = var.integration_provisioners
}
