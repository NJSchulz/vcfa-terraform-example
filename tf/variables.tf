variable "url"            { type = string }
variable "refresh_token"  { type = string }
variable "organization"   { type = string }
variable "insecure"       { type = bool }

variable "hostname" {
  description = "Hostname of the deployed VM"
  type        = string
}

variable "ipAddress" {
  description = "IP address of the deployed VM"
  type        = string
}

variable "gateway" {
  description = "Default gateway"
  type        = string
}

variable "dns" {
  description = "DNS server(s)"
  type        = string # This is string even though it *looks* like an array — it's a JSON-encoded string in Terraform vRA input
}

variable "prefixLength" {
  description = "Network prefix length (e.g. 24 for 255.255.255.0)"
  type        = number
}
