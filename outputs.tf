output account_details {
	value = [
		for v in aws_organizations_account.this: { "name": v.name, "id": v.id }
	]
}
