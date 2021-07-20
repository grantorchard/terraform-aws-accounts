provider "aws" {
	access_key = data.vault_aws_access_credentials.this.access_key
	secret_key = data.vault_aws_access_credentials.this.secret_key
	token = data.vault_aws_access_credentials.this.security_token
}
provider "vault" {
	address = local.vault_url
	namespace = "admin"
}

locals {
	vault_url = data.terraform_remote_state.terraform-hcp-core.outputs.vault_url
}

data "vault_aws_access_credentials" "this" {
	backend = "aws"
	type = "sts"
	role = "account_management"
	ttl = "15m"
}

resource "aws_organizations_account" "this" {
	for_each = toset(var.aws_account_names)
  name  = each.value
  email = "go@hashicorp.com"
	role_name = "sudo"
}

resource "vault_aws_secret_backend_role" "terraform" {
	backend = "aws"
	name = "terraform"
	role_arns = [
		for account in aws_organizations_account.this: "arn:aws:organizations::${account.id}:role/${account.role_name}"
	]
}

