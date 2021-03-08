variable azuread_application_password_length {
  type        = number
  default     = 128
  description = "Length of the password to be created for the Service Principal. Must be between 8 and 256 characters."
  validation {
    condition     = var.azuread_application_password_length >= 8 && var.azuread_application_password_length <= 256
    error_message = "The password length must be between 8 and 256 characters."
  }
}

variable azuread_application_password_special_chars {
  type        = bool
  default     = true
  description = "Whether to use special characters in the Service Principal password."
}

variable azuread_application_display_name {
  type        = string
  default     = ""
  description = "The name of the Service Principal/Enterprise Application that will be created in Azure Active Directory."
}

variable vault_addr {
  type        = string
  description = "Used to configure reply URLs in Azure AD Enterprise App and the default role for Vault OIDC."
}

variable reset_azuread_application_password {
  type    = bool
  default = false
}

variable vault_oidc_pathname {
  type        = string
  description = "The name of the path where the auth mount will be created."
  default     = "oidc"
}

variable groups_claim {
  type        = string
  description = ""
  default     = "roles"
}

variable user_type {
  type        = string
  description = "The attribute of the JWT to use for user."
  default     = "email"
}