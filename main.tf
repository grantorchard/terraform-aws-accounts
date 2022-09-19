provider "aws" {
	access_key = data.vault_aws_access_credentials.this.access_key
	secret_key = data.vault_aws_access_credentials.this.secret_key
	token = data.vault_aws_access_credentials.this.security_token
}
provider "vault" {}

provider "github" {
	token = var.github_token
}

locals {
	vault_url = "https://production.vault.11eb56d6-0f95-3a99-a33c-0242ac110007.aws.hashicorp.cloud:8200"
}

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

resource "aws_iam_policy" "terraform" {
	name = "account_configuration"
	policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
	dynamic statement {
		for_each = toset([ for account in aws_organizations_account.this: account.id ])
		content {
			actions = ["sts:AssumeRole"]
			resources = ["arn:aws:iam::${statement.value}:role/OrganizationAccountAccessRole"]
			effect = "Allow"
		}
	}
}

data "aws_iam_user" "this" {
	user_name = "hcp_vault_user"
}

resource "aws_iam_user_policy_attachment" "this" {
	policy_arn = aws_iam_policy.terraform.arn
	user = data.aws_iam_user.this.user_name
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

data "github_repository" "this" {
	name = "terraform-aws-account-configuration"
}

resource "github_repository_file" "this" {
	for_each = { for account in aws_organizations_account.this: account.id => account }
	repository          = data.github_repository.this.name
	branch              = "main"
  file                = "${each.value.id}.tf"
  content             = templatefile("./provider.tf.tmpl", {
		account_id = each.value.id
	})
  commit_message      = "Initial commit for provider configuration"
  commit_author       = "Grant Orchard"
  commit_email        = "grant.a.orchard@gmail.com"
  overwrite_on_create = true
}

