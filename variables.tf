variable "aws_account_details" {
	type = list(object({
		account_name = string
		email = string
	}))
}

variable "github_token" {
	type = string
}

