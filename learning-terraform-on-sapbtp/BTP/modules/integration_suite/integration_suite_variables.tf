variable "subaccount_id" {
  type        = string
  description = "The subaccount ID."
}

variable "cpi_admins" {
  type        = list(string)
  description = "Defines the colleagues who are admins for SAP Build Code."
}

variable "cpi_developers" {
  type        = list(string)
  description = "Defines the colleagues who are developers for SAP Build Code."
}

# ------------------------------------------------------------------------------------------------------
# app subscription plans
# ------------------------------------------------------------------------------------------------------
variable "service_plan__integrationsuite" {
  type        = string
  description = "The plan for service 'Integration Suite' with technical name 'integrationsuite'"
  default     = "trial"
  validation {
    condition     = contains(["enterprise_agreement", "free", "trial"], var.service_plan__integrationsuite)
    error_message = "Invalid value for service_plan__integrationsuite. Only 'enterprise_agreement' and 'free' are allowed."
  }
}

variable "integration_provisioners" {
  type        = list(string)
  description = "Integration Provisioner"
}

variable "cloud_connector_admins" {
  type        = list(string)
  description = "Defines the colleagues who are administrators for Cloud Connector"
}