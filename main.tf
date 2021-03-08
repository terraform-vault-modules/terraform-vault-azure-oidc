provider azuread {}
provider vault {}
provider random {}

# Retrieve connection context so we can programmatically discover tenant_id later.
data "azuread_client_config" "this" {}

locals {
	azuread_application_display_name = var.azuread_application_display_name != "" ? var.azuread_application_display_name : "${random_pet.this.id}-${random_integer.this.result}"
}

## Random naming function
resource "random_pet" "this" {
  length = 2
}

resource "random_integer" "this" {
	min = 10000
	max = 99999
}

# Set supported special characters per
# https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-sspr-policy#password-policies-that-only-apply-to-cloud-user-accounts
resource "random_password" "this" {
	length = var.azuread_application_password_length
	special = var.azuread_application_password_special_chars
	override_special = "@#$%^&*-_!+=[]{}|\\:',.?/`~\"(); "
}

## Create the AzureAD Enterprise App used by Vault

// Discover the Microsoft Graph service principal so we can pass it to our Enterprise Application.
data "azuread_service_principal" "this" {
	display_name = "Microsoft Graph"
}

resource "azuread_application" "this" {
	display_name = local.azuread_application_display_name
	reply_urls = [
    "http://localhost:8250/oidc/callback",
    "${var.vault_addr}/ui/vault/auth/oidc/oidc/callback"
  ]
	required_resource_access {
    # Add MS Graph GroupMember.Read.All API permissions
    resource_app_id = data.azuread_service_principal.this.application_id

    resource_access {
      type = "Scope"
			id = [ for app_role in data.azuread_service_principal.this.app_roles: app_role.id if app_role.value == "GroupMember.Read.All"][0]
    }
  }
}

resource "azuread_application_password" "this" {
	application_object_id = azuread_application.this.id
  value                 = random_password.this.result
  end_date              = timeadd(timestamp(), "8766h")
}

resource "vault_jwt_auth_backend" "this" {
	type = "oidc"
	path = var.vault_oidc_pathname
}

resource "vault_jwt_auth_backend_role" "this" {
  backend         = vault_jwt_auth_backend.this.path
  role_name       = "default"
  token_policies  = [
    "default"
  ]
  user_claim            = var.user_type
  role_type             = "oidc"
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "${var.vault_addr}/ui/vault/auth/oidc/oidc/callback"
  ]
  groups_claim = var.groups_claim
}
