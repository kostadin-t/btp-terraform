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