output "cf_api_url" {
  value       = jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels)["API Endpoint"]
  description = "The Cloud Foundry API URL"
}

output "cf_org_id" {
  value       = jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels)["Org ID"]
  description = "The Cloud Foundry organization ID"
}

output "cf_landscape_label" {
  value       = btp_subaccount_environment_instance.cloudfoundry.landscape_label
  description = "The Cloud Foundry landscape label"
}

output "subaccount_url" {
  value       = "https://account.hanatrial.ondemand.com/trial/#/globalaccount/${data.btp_globalaccount.this.id}/subaccount/${btp_subaccount.project_subaccount.id}"
  description = "The SAP BTP subaccount URL"
}

output "url_sap_build_code" {
  value = module.build_code.url_sap_build_code
}

output "url_sap_biz_app_studio" {
  value = module.build_code.url_sap_biz_app_studio
}

output "url_sap_build_process_automation" {
  value = module.build_process_automation.url_build_process_automation
}