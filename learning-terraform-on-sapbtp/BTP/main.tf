resource "random_uuid" "uuid" {}
data "btp_globalaccount" "this" {}

locals {
  subaccount_name                 = "${var.subaccount_stage} ${var.project_name}"
  subaccount_subdomain            = join("-", [lower(replace("${var.subaccount_stage}-${var.project_name}", " ", "-")), random_uuid.uuid.result])
  beta_enabled                    = var.subaccount_stage == "PROD" ? false : true
  subaccount_cf_org               = local.subaccount_subdomain
  service_name__connectivity      = "connectivity"
  service_name__destination       = "destination"
  connectivity_destination_admins = var.connectivity_destination_admins
  cloud_connector_admins          = var.cloud_connector_admins
  custom_idp_tenant               = var.custom_idp != "" ? element(split(".", var.custom_idp), 0) : ""
  origin_key                      = local.custom_idp_tenant != "" ? "${local.custom_idp_tenant}-platform" : ""

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

# ------------------------------------------------------------------------------------------------------
# Assign custom IDP to sub account (if custom_idp is set)
# ------------------------------------------------------------------------------------------------------
# resource "btp_subaccount_trust_configuration" "fully_customized" {
#   # Only create trust configuration if custom_idp has been set 
#   count             = var.custom_idp == "" ? 0 : 1
#   subaccount_id     = btp_subaccount.project_subaccount.id
#   identity_provider = var.custom_idp
# }

# IdP trust configuration
resource "btp_subaccount_trust_configuration" "fully_customized" {
  subaccount_id     = btp_subaccount.project_subaccount.id
  identity_provider = var.custom_idp != "" ? var.custom_idp : element(split("/", btp_subaccount_subscription.sap_identity_services_onboarding[0].subscription_url), 2)
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

resource "btp_subaccount_role_collection_assignment" "connectivity_destination_admins" {
  for_each             = toset(local.connectivity_destination_admins)
  subaccount_id        = btp_subaccount.project_subaccount.id
  role_collection_name = "Connectivity and Destination Administrator"
  user_name            = each.value
  depends_on           = [btp_subaccount_entitlement.destination]
}

resource "btp_subaccount_role_collection_assignment" "cloud_connector_admins" {
  for_each             = toset(local.cloud_connector_admins)
  subaccount_id        = btp_subaccount.project_subaccount.id
  role_collection_name = "Cloud Connector Administrator"
  user_name            = each.value
  depends_on           = [btp_subaccount_entitlement.connectivity]
}

# Create destination for Visual Cloud Functions
resource "btp_subaccount_service_instance" "vcf_destination" {
  subaccount_id  = btp_subaccount.project_subaccount.id
  serviceplan_id = btp_subaccount_entitlement.destination.id
  name           = "SAP-Build-Apps-Runtime"
  parameters = jsonencode({
    HTML5Runtime_enabled = true
    init_data = {
      subaccount = {
        existing_destinations_policy = "update"
        destinations = [
          {
            Name                     = "SAP-Build-Apps-Runtime"
            Type                     = "HTTP"
            Description              = "Endpoint to SAP Build Apps runtime"
            URL                      = "https://${btp_subaccount.project_subaccount.subdomain}.cr1.${btp_subaccount.project_subaccount.region}.apps.build.cloud.sap/"
            ProxyType                = "Internet"
            Authentication           = "NoAuthentication"
            "HTML5.ForwardAuthToken" = true
          }
        ]
      }
    }
  })
}

# ------------------------------------------------------------------------------------------------------
# APP SUBSCRIPTIONS
# ------------------------------------------------------------------------------------------------------
#
locals {
  service_name__sap_build_apps = "sap-build-apps"
  # service_name__sap_launchpad  = "build-workzone-standard"
  service_name__sap_launchpad  = "SAPLaunchpad"

  service_name__sap_launchpad_appname="SAPLaunchpad"
  # optional, if custom idp is used
  service_name__sap_identity_services_onboarding = "sap-identity-services-onboarding"
}

# ------------------------------------------------------------------------------------------------------
# Setup sap-identity-services-onboarding (Cloud Identity Services)
# ------------------------------------------------------------------------------------------------------
# Entitle
resource "btp_subaccount_entitlement" "sap_identity_services_onboarding" {
  count = var.custom_idp == "" ? 1 : 0

  subaccount_id = btp_subaccount.project_subaccount.id
  service_name  = local.service_name__sap_identity_services_onboarding
  plan_name     = var.service_plan__sap_identity_services_onboarding
}
# Subscribe
resource "btp_subaccount_subscription" "sap_identity_services_onboarding" {
  count = var.custom_idp == "" ? 1 : 0

  subaccount_id = btp_subaccount.project_subaccount.id
  app_name      = local.service_name__sap_identity_services_onboarding
  plan_name     = var.service_plan__sap_identity_services_onboarding
  depends_on = [ btp_subaccount_entitlement.sap_identity_services_onboarding ]
}



# ------------------------------------------------------------------------------------------------------
# Setup sap-build-apps (SAP Build Apps)
# ------------------------------------------------------------------------------------------------------
# Entitle
resource "btp_subaccount_entitlement" "sap_build_apps" {
  subaccount_id = btp_subaccount.project_subaccount.id
  service_name  = local.service_name__sap_build_apps
  plan_name     = var.service_plan__sap_build_apps
  amount        = 1
  depends_on    = [btp_subaccount_subscription.sap_identity_services_onboarding, btp_subaccount_trust_configuration.fully_customized]
}
# Subscribe
resource "btp_subaccount_subscription" "sap_build_apps" {
  subaccount_id = btp_subaccount.project_subaccount.id
  app_name      = "sap-appgyver-ee"
  plan_name     = var.service_plan__sap_build_apps
  depends_on    = [btp_subaccount_entitlement.sap_build_apps]
}

# ------------------------------------------------------------------------------------------------------
# Setup SAPLaunchpad (SAP Build Work Zone, standard edition)
# ------------------------------------------------------------------------------------------------------
# Entitle
resource "btp_subaccount_entitlement" "sap_launchpad" {
  subaccount_id = btp_subaccount.project_subaccount.id
  service_name  = local.service_name__sap_launchpad
  plan_name     = var.service_plan__sap_launchpad
  amount        = var.service_plan__sap_launchpad == "free" ? 1 : null
}

# Subscribe
resource "btp_subaccount_subscription" "sap_launchpad" {
  subaccount_id = btp_subaccount.project_subaccount.id
  app_name      = local.service_name__sap_launchpad
  plan_name     = var.service_plan__sap_launchpad_app
  depends_on    = [btp_subaccount_entitlement.sap_launchpad]
}

# ------------------------------------------------------------------------------------------------------
#  USERS AND ROLES
# ------------------------------------------------------------------------------------------------------
#
# Get all roles in the subaccount
data "btp_subaccount_roles" "all" {
  subaccount_id = btp_subaccount.project_subaccount.id
  depends_on    = [btp_subaccount_subscription.sap_build_apps]
}
# ------------------------------------------------------------------------------------------------------
# Create/Assign role collection "BuildAppsAdmin"
# ------------------------------------------------------------------------------------------------------
# Create
resource "btp_subaccount_role_collection" "build_apps_admin" {
  subaccount_id = btp_subaccount.project_subaccount.id
  name          = "BuildAppsAdmin"

  roles = [
    for role in data.btp_subaccount_roles.all.values : {
      name                 = role.name
      role_template_app_id = role.app_id
      role_template_name   = role.role_template_name
    } if contains(["BuildAppsAdmin"], role.name)
  ]
}
# Assign users
resource "btp_subaccount_role_collection_assignment" "build_apps_admin" {
  for_each             = toset(var.build_apps_admins)
  subaccount_id        = btp_subaccount.project_subaccount.id
  role_collection_name = "BuildAppsAdmin"
  user_name            = each.value
  origin               = "sap.default"
  depends_on           = [btp_subaccount_role_collection.build_apps_admin]
}

# ------------------------------------------------------------------------------------------------------
# Create/Assign role collection "BuildAppsDeveloper"
# ------------------------------------------------------------------------------------------------------
# Create
resource "btp_subaccount_role_collection" "build_apps_developer" {
  subaccount_id = btp_subaccount.project_subaccount.id
  name          = "BuildAppsDeveloper"

  roles = [
    for role in data.btp_subaccount_roles.all.values : {
      name                 = role.name
      role_template_app_id = role.app_id
      role_template_name   = role.role_template_name
    } if contains(["BuildAppsDeveloper"], role.name)
  ]
}
# Assign users
resource "btp_subaccount_role_collection_assignment" "build_apps_developer" {
  for_each             = toset(var.build_apps_developers)
  subaccount_id        = btp_subaccount.project_subaccount.id
  role_collection_name = "BuildAppsDeveloper"
  user_name            = each.value
  origin               = "sap.default"
  depends_on           = [btp_subaccount_role_collection.build_apps_developer]
}

# ------------------------------------------------------------------------------------------------------
# Create/Assign role collection "RegistryAdmin"
# ------------------------------------------------------------------------------------------------------
# Create
resource "btp_subaccount_role_collection" "build_apps_registry_admin" {
  subaccount_id = btp_subaccount.project_subaccount.id
  name          = "RegistryAdmin"

  roles = [
    for role in data.btp_subaccount_roles.all.values : {
      name                 = role.name
      role_template_app_id = role.app_id
      role_template_name   = role.role_template_name
    } if contains(["RegistryAdmin"], role.name)
  ]
}
# Assign users
resource "btp_subaccount_role_collection_assignment" "build_apps_registry_admin" {
  for_each             = toset(var.build_apps_registry_admin)
  subaccount_id        = btp_subaccount.project_subaccount.id
  role_collection_name = "RegistryAdmin"
  user_name            = each.value
  origin               = "sap.default"
  depends_on           = [btp_subaccount_role_collection.build_apps_registry_admin]
}

# ------------------------------------------------------------------------------------------------------
# Create/Assign role collection "RegistryDeveloper"
# ------------------------------------------------------------------------------------------------------
# Create
resource "btp_subaccount_role_collection" "build_apps_registry_developer" {
  subaccount_id = btp_subaccount.project_subaccount.id
  name          = "RegistryDeveloper"

  roles = [
    for role in data.btp_subaccount_roles.all.values : {
      name                 = role.name
      role_template_app_id = role.app_id
      role_template_name   = role.role_template_name
    } if contains(["RegistryDeveloper"], role.name)
  ]
}
# Assign users to the role collection
resource "btp_subaccount_role_collection_assignment" "build_apps_registry_developer" {
  for_each             = toset(var.build_apps_registry_developer)
  subaccount_id        = btp_subaccount.project_subaccount.id
  role_collection_name = "RegistryDeveloper"
  user_name            = each.value
  origin               = "sap.default"
  depends_on           = [btp_subaccount_role_collection.build_apps_registry_developer]
}

# ------------------------------------------------------------------------------------------------------
# Assign role collection "Launchpad_Admin"
# ------------------------------------------------------------------------------------------------------
# Assign users
resource "btp_subaccount_role_collection_assignment" "launchpad_admin" {
  for_each             = toset("${var.launchpad_admins}")
  subaccount_id        = btp_subaccount.project_subaccount.id
  role_collection_name = "Launchpad_Admin"
  user_name            = each.value
  origin               = "sap.default"
  depends_on           = [btp_subaccount_subscription.sap_launchpad]
}