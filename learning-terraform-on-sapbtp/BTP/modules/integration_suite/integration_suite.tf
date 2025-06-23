# ------------------------------------------------------------------------------------------------------
# Required provider
# ------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.13.0"
    }
  }
}

#
locals {
  service_name__integrationsuite = "integrationsuite-trial"
  custom_idp_tenant = var.custom_idp != "" ? element(split(".", var.custom_idp), 0) : ""
  origin_key        = local.custom_idp_tenant != "" ? "${local.custom_idp_tenant}-platform" : ""
}
# ------------------------------------------------------------------------------------------------------
# Setup integrationsuite (Integration Suite Service)
# ------------------------------------------------------------------------------------------------------
# Entitle
resource "btp_subaccount_entitlement" "integrationsuite-trial" {
  subaccount_id = var.subaccount_id
  service_name  = local.service_name__integrationsuite
  plan_name     = var.service_plan__integrationsuite
  amount        = var.service_plan__integrationsuite == "trial" ? 1 : null
}

data "btp_subaccount_subscriptions" "all" {
  subaccount_id = var.subaccount_id
  depends_on    = [btp_subaccount_entitlement.integrationsuite-trial]
}

# Subscribe
resource "btp_subaccount_subscription" "integrationsuite-trial" {
  subaccount_id = var.subaccount_id
  app_name = [
    for subscription in data.btp_subaccount_subscriptions.all.values :
    subscription
    if subscription.commercial_app_name == local.service_name__integrationsuite
  ][0].app_name
  plan_name  = var.service_plan__integrationsuite
  depends_on = [data.btp_subaccount_subscriptions.all]
}

# ------------------------------------------------------------------------------------------------------
#  USERS AND ROLES
# ------------------------------------------------------------------------------------------------------
data "btp_whoami" "me" {}
#
locals {
  integration_provisioners = var.integration_provisioners
  cloud_connector_admins          = var.cloud_connector_admins
}


# ------------------------------------------------------------------------------------------------------
# Assign role collection "Integration_Provisioner"
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_role_collection_assignment" "integration_provisioner" {
  for_each             = toset("${local.integration_provisioners}")
  subaccount_id        = var.subaccount_id
  role_collection_name = "Integration_Provisioner"
  user_name            = each.value
  origin               = "sap.default"
  depends_on           = [btp_subaccount_subscription.integrationsuite-trial]
}