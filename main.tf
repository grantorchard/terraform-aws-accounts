provider "aws" {
	access_key = data.vault_aws_access_credentials.this.access_key
	secret_key = data.vault_aws_access_credentials.this.secret_key
	token = data.vault_aws_access_credentials.this.security_token
}
provider "vault" {
	address = locals.vault_url
	namespace = "admin"
}

locals {
	vault_url = data.terraform_remote_state.terraform-hcp-core.vault_url
}

data "vault_aws_access_credentials" "this" {
	backend = aws
	type = "sts"
	role = "personal"
	ttl = "15m"
}



