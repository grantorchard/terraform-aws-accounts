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

# resource "aws_iam_group" "this" {
#   name = "account_config"
#   path = "/users/"
# }

# data "aws_iam_user" "this" {
# 	user_name = "hcp_vault_user"
# }

# resource "aws_iam_group_membership" "this" {
#   name = "account_config"

#   users = [
#     data.aws_iam_user.this.user_name
#   ]

#   group = aws_iam_group.this.name
# }

# data "aws_iam_policy" "this" {
#   name = "AdministratorAccess"
# }

# resource "aws_iam_group_policy_attachment" "this" {
#   group      = aws_iam_group.this.name
#   policy_arn = data.aws_iam_policy.this.arn
# }

data "vault_aws_access_credentials" "this" {
	backend = "aws"
	type = "sts"
	role = "account_management"
	ttl = "15m"
}

resource "aws_organizations_account" "this" {
	for_each = { for v in var.aws_account_details: v.account_name => v }
  name  = each.value.account_name
  email = each.value.email
}

resource "vault_aws_secret_backend_role" "terraform" {
	backend = "aws"
	credential_type = "assumed_role"
	max_sts_ttl = 1800 # number in seconds
	name = "terraform"
	role_arns = [
		for account in aws_organizations_account.this: "arn:aws:iam::${account.id}:role/OrganizationAccountAccessRole"
	]
}

