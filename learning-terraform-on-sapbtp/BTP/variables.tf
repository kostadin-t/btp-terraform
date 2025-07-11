variable "globalaccount" {
  description = "Subdomain of the global account"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "Terraform"
}

variable "subaccount_region" {
  description = "Region of the subaccount"
  type        = string
  default     = "us10"
  validation {
    condition     = contains(["us10", "ap21"], var.subaccount_region)
    error_message = "Region must be one of us10 or ap21"
  }
}

variable "subaccount_stage" {
  description = "Stage of the subaccount"
  type        = string
  default     = "DEV"
  validation {
    condition     = contains(["DEV", "TEST", "PROD"], var.subaccount_stage)
    error_message = "Stage must be one of DEV, TEST or PROD"
  }
}

variable "project_costcenter" {
  description = "Cost center of the project"
  type        = string
  default     = "12345"
  validation {
    condition     = can(regex("^[0-9]{5}$", var.project_costcenter))
    error_message = "Cost center must be a 5 digit number"
  }
}

variable "cf_landscape_label" {
  type        = string
  description = "The Cloud Foundry landscape (format example us10-001)."
  default     = ""
}

variable "subaccount_emergency_admins" {
  type        = list(string)
  description = "List of emergency admins for the SAP BTP subaccount"
  default     = []
}

variable "build_code_admins" {
  type        = list(string)
  description = "Defines the colleagues who are admins for SAP Build Code."
}

variable "build_code_developers" {
  type        = list(string)
  description = "Defines the colleagues who are developers for SAP Build Code."
}

variable "application_studio_admins" {
  type        = list(string)
  description = "Defines the colleagues who are admins for SAP Business Application Studio"
}

variable "application_studio_developers" {
  type        = list(string)
  description = "Defines the colleagues who are developers for SAP Business Application Studio"
}

variable "application_studio_extension_deployer" {
  type        = list(string)
  description = "Defines the colleagues who are extension deployers for SAP Business Application Studio"
}

variable "process_automation_admins" {
  type        = list(string)
  description = "Defines the users who have the role of ProcessAutomationAdmin in SAP Build Process Automation"
}

variable "process_automation_developers" {
  type        = list(string)
  description = "Defines the users who have the role of ProcessAutomationDeveloper in SAP Build Process Automation"
}

variable "process_automation_participants" {
  type        = list(string)
  description = "Defines the users who have the role of ProcessAutomationParticipant in SAP Build Process Automation"
}

variable "service_plan__connectivity" {
  type        = string
  description = "The plan for service 'Connectivity Service' with technical name 'connectivity'"
  default     = "lite"
}

variable "service_plan__destination" {
  type        = string
  description = "The plan for service 'Destination Service' with technical name 'destination'"
  default     = "lite"
}


variable "service_plan__html5_apps_repo" {
  type        = string
  description = "The plan for service 'HTML5 Application Repository Service' with technical name 'html5-apps-repo'"
  default     = "app-host"
}

variable "service_plan__xsuaa" {
  type        = string
  description = "The plan for service 'Authorization and Trust Management Service' with technical name 'xsuaa'"
  default     = "application"
}

variable "connectivity_destination_admins" {
  type        = list(string)
  description = "Defines the colleagues who are administrators for Connectivity and Destinations"
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

variable "custom_idp" {
  type        = string
  description = "The custom identity provider for the subaccount."
  default     = ""
}

variable "custom_idp_apps_origin_key" {
  type        = string
  description = "The custom identity provider for the subaccount."
  default     = "sap.custom"
}

variable "origin" {
  type        = string
  description = "Defines the origin key of the identity provider"
  default     = "sap.ids"
  # The value for the origin_key can be defined
  # but are normally set to "sap.ids", "sap.default" or "sap.custom"
}

variable "origin_key" {
  type        = string
  description = "Defines the origin key of the identity provider"
  default     = ""
  # The value for the origin_key can be defined, set to "sap.ids", "sap.default" or "sap.custom"
}

# app subscription plans
# ------------------------------------------------------------------------------------------------------
variable "service_plan__sap_identity_services_onboarding" {
  type        = string
  description = "The plan for service 'Cloud Identity Services' with technical name 'sap-identity-services-onboarding'"
  default     = "default"
  validation {
    condition     = contains(["default"], var.service_plan__sap_identity_services_onboarding)
    error_message = "Invalid value for service_plan__sap_identity_services_onboarding. Only 'default' is allowed."
  }
}

variable "service_plan__sap_build_apps" {
  type        = string
  description = "The plan for SAP Build Apps subscription"
  default     = "free"
  validation {
    condition     = contains(["free", "standard", "partner"], var.service_plan__sap_build_apps)
    error_message = "Invalid value for service_plan__sap_build_apps. Only 'free', 'standard' and 'partner' are allowed."
  }
}

variable "service_plan__sap_launchpad" {
  type        = string
  description = "The plan for service 'SAP Build Work Zone, standard edition' with technical name 'SAPLaunchpad'"
  default     = "standard"
  validation {
    condition     = contains(["free", "standard"], var.service_plan__sap_launchpad)
    error_message = "Invalid value for service_plan__sap_launchpad. Only 'free' and 'standard' are allowed."
  }
}

variable "service_plan__sap_launchpad_app" {
  type = string
  description = "The plan for service 'SAP Launchpad Service' with technical name 'SAPLaunchpadApp'"
  default = "standard"
  validation {
    condition     = contains(["free", "standard"], var.service_plan__sap_launchpad_app)
    error_message = "Invalid value for service_plan__sap_launchpad_app. Only 'free' and 'standard' are allowed."
  }
}

# ------------------------------------------------------------------------------------------------------
# User lists
# ------------------------------------------------------------------------------------------------------

variable "launchpad_admins" {
  type        = list(string)
  description = "Defines the users who have the role of 'Launchpad_Admin'."

  # add validation to check if admins contains a list of valid email addresses
  validation {
    condition     = length([for email in var.launchpad_admins : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))]) == length(var.launchpad_admins)
    error_message = "Please enter a valid email address for the launchpad admins."
  }
}

variable "build_apps_admins" {
  type        = list(string)
  description = "Defines the users who have the role of 'BuildAppsAdmin' in SAP Build Apps."
}

variable "build_apps_developers" {
  type        = list(string)
  description = "Defines the users who have the role of 'BuildAppsDeveloper' in SAP Build Apps."
}

variable "build_apps_registry_admin" {
  type        = list(string)
  description = "Defines the users who have the role of 'RegistryAdmin' in SAP Build Apps."
}

variable "build_apps_registry_developer" {
  type        = list(string)
  description = "Defines the users who have the role of RegistryDeveloper' in SAP Build Apps."
}