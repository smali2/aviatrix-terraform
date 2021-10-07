# username, password and controller_ip is configured in terraform cloud variable section
# this will keep these secure and not part of github code

 variable "username" {
  type        = string
  description = "Aviatrix Controller's Username"
  default     = ""
 }

 variable password {
  description = "Aviatrix Controller's Password"
  default = ""
 }

 variable "controller_ip" {
  description = "Aviatrix Controller's IP Address"
  default = ""
 }

variable "aws_account_name" {
  type        = string
  description = "AWS Account Name"
  default = ""
}

variable "aws_region" {
  description = "Pick AWS Region. Default is Oregon"
  default     = "us-west-2"
}

// VPC Variables

variable "firenet_vpc_name" {
  description = "Transit FireNet VPC Name"
  default     = "AVX-TR-FNET1-VPC"
}

variable "transit_firenet_cidr" {
  description = "Transit FireNet CIDR"
  default     = "10.11.0.0/16"
}

variable "spoke1_vpc_name" {
  description = "Spoke 1 VPC Name"
  default     = "AVX-SPK1-FNET1-VPC"
}

variable "spoke1_cidr" {
  description = "Spoke 1 (PROD) CIDR"
  default     = "10.12.0.0/16"
}


variable "spoke2_vpc_name" {
  description = "Spoke 2 VPC Name"
  default     = "AVX-DEV1-FNET1-VPC"
}

variable "spoke2_cidr" {
  description = "Spoke 2 (DEV) CIDR"
  default     = "10.13.0.0/16"
}


//Transit FireNet Variables

variable "transit_firenet_gw_name" {
  description = "Transit FireNet Gateway Name"
  default     = "TR-FNET1-GW"
}


variable "PAN_firewall" {
  description = "Firewall Instance Name"
  default     = "PAN-TRFNET-NGFW1"
}


// Spokes Variables

variable "spoke1_gw_name" {
  description = "Spoke1 Gateway Name"
  default     = "PROD1-SPK-GW"
}


variable "spoke2_gw_name" {
  description = "Spoke 2 Gateway Name"
  default     = "DEV1-SPK-GW"
}
