terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.31"
    }
		vault = {
      source = "hashicorp/vault"
      version = "2.21.0"
    }
		github = {
			source = "integrations/github"
      version = "4.16.0"
		}
  }
}