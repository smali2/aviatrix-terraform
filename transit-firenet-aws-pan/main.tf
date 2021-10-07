# Provider Information
terraform {
  required_providers {
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = "2.20.0"
    }
  }
}


# Specify Aviatrix as the provider with these parameters:
# controller_ip - public IP address of the controller
# username - login user name, default is admin
# password - password
# version - release version # of Aviatrix Terraform provider

provider "aviatrix" {
    controller_ip = var.controller_ip
    username = var.username
    password = var.password
}

//VPC SECTION

# Create an AWS VPC for Aviatrix Transit FireNet
resource "aviatrix_vpc" "AVX_TR_FNET1_VPC" {
    cloud_type = 1
    account_name = var.aws_account_name
    name = var.firenet_vpc_name
    aviatrix_transit_vpc = false
    aviatrix_firenet_vpc = true
    region = var.aws_region
    cidr = var.transit_firenet_cidr
}

# Create an AWS VPC for SPK Gateway (PROD1)
resource "aviatrix_vpc" "AVX_SPK1_FNET1_VPC" {
    cloud_type = 1
    account_name = var.aws_account_name
    name = var.spoke1_vpc_name
    aviatrix_transit_vpc = false
    aviatrix_firenet_vpc = false
    region = var.aws_region
    cidr = var.spoke1_cidr
}

# Create an AWS VPC for SPK Gateway (DEV1)
resource "aviatrix_vpc" "AVX_DEV1_FNET1_VPC" {
    cloud_type = 1
    account_name = var.aws_account_name
    name = var.spoke2_vpc_name
    aviatrix_transit_vpc = false
    aviatrix_firenet_vpc = false
    region = var.aws_region
    cidr = var.spoke2_cidr
}

//Launch Gateways


# Create an Aviatrix Transit Gateway in AWS
resource "aviatrix_transit_gateway" "TR_FNET1" {
    gw_name = var.transit_firenet_gw_name
    vpc_id = aviatrix_vpc.AVX_TR_FNET1_VPC.vpc_id
    cloud_type = 1
    vpc_reg = aviatrix_vpc.AVX_TR_FNET1_VPC.region
    connected_transit = true
    enable_active_mesh = true
    gw_size = "c5.xlarge"
    account_name = var.aws_account_name
    subnet = aviatrix_vpc.AVX_TR_FNET1_VPC.public_subnets[3].cidr
    enable_gateway_load_balancer = true
    enable_encrypt_volume = true
    enable_transit_firenet = true
    ha_subnet = aviatrix_vpc.AVX_TR_FNET1_VPC.public_subnets[1].cidr
    ha_gw_size = "c5.xlarge"
}

# Create an Spoke Gateway (DEV1) in AWS
resource "aviatrix_spoke_gateway" "DEV1_SPK" {
    gw_name = var.spoke2_gw_name
    vpc_id = aviatrix_vpc.AVX_DEV1_FNET1_VPC.vpc_id
    cloud_type = 1
    vpc_reg = aviatrix_vpc.AVX_DEV1_FNET1_VPC.region
    enable_active_mesh = true
    gw_size = "t3.small"
    account_name = var.aws_account_name
    subnet = aviatrix_vpc.AVX_DEV1_FNET1_VPC.public_subnets[1].cidr
    enable_encrypt_volume = true
    ha_subnet = aviatrix_vpc.AVX_DEV1_FNET1_VPC.public_subnets[1].cidr
    ha_gw_size = "t3.small"
    manage_transit_gateway_attachment = false
}

# Create an Aviatrix Spoke Gateway (PROD1) in AWS
resource "aviatrix_spoke_gateway" "PROD1_SPK" {
    gw_name = var.spoke1_gw_name
    vpc_id = aviatrix_vpc.AVX_SPK1_FNET1_VPC.vpc_id
    cloud_type = 1
    vpc_reg = aviatrix_vpc.AVX_SPK1_FNET1_VPC.region
    enable_active_mesh = true
    gw_size = "t3.small"
    account_name = var.aws_account_name
    subnet = aviatrix_vpc.AVX_SPK1_FNET1_VPC.public_subnets[1].cidr
    enable_encrypt_volume = true
    ha_subnet = aviatrix_vpc.AVX_SPK1_FNET1_VPC.public_subnets[0].cidr
    ha_gw_size = "t3.small"
    manage_transit_gateway_attachment = false
}


//Spokes Attachment

# Attach Spokes with Transit Gateway
resource "aviatrix_spoke_transit_attachment" "spoke1_transit_attachment" {
    spoke_gw_name = aviatrix_spoke_gateway.PROD1_SPK.gw_name
    transit_gw_name = aviatrix_transit_gateway.TR_FNET1.gw_name
}

resource "aviatrix_spoke_transit_attachment" "spoke2_transit_attachment" {
    spoke_gw_name = aviatrix_spoke_gateway.DEV1_SPK.gw_name
    transit_gw_name = aviatrix_transit_gateway.TR_FNET1.gw_name
}


// FireNet Inspection Policy

resource "aviatrix_transit_firenet_policy" "transit_firenet_policy_2" {
    transit_firenet_gateway_name = aviatrix_transit_gateway.TR_FNET1.gw_name
    inspected_resource_name = "SPOKE:${aviatrix_spoke_gateway.DEV1_SPK.gw_name}"

    depends_on = [aviatrix_spoke_transit_attachment.spoke2_transit_attachment]
}

resource "aviatrix_transit_firenet_policy" "transit_firenet_policy_1" {
    transit_firenet_gateway_name = aviatrix_transit_gateway.TR_FNET1.gw_name
    inspected_resource_name = "SPOKE:${aviatrix_spoke_gateway.PROD1_SPK.gw_name}"

    depends_on = [aviatrix_spoke_transit_attachment.spoke1_transit_attachment]
}


// Advanced Firewall Network

resource "aviatrix_firenet" "PAN_firenet" {
    vpc_id = aviatrix_transit_gateway.TR_FNET1.vpc_id
    inspection_enabled = true
    egress_enabled = true
    manage_firewall_instance_association = false
    hashing_algorithm = "5-Tuple"
}

// Firewall Section

resource "aviatrix_firewall_instance" "PAN_firewall" {
    firewall_name = var.PAN_firewall
    firewall_size = "m5.xlarge"
    vpc_id = aviatrix_transit_gateway.TR_FNET1.vpc_id
    firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
    firewall_image_version = "10.0.3"
    egress_subnet = aviatrix_vpc.AVX_TR_FNET1_VPC.public_subnets[3].cidr
    firenet_gw_name = aviatrix_transit_gateway.TR_FNET1.gw_name
    management_subnet = aviatrix_vpc.AVX_TR_FNET1_VPC.public_subnets[2].cidr
}

resource "aviatrix_firewall_instance_association" "PAN_firewall_instance_association" {
    vpc_id = aviatrix_transit_gateway.TR_FNET1.vpc_id
    firenet_gw_name = aviatrix_transit_gateway.TR_FNET1.gw_name
    instance_id = aviatrix_firewall_instance.PAN_firewall.instance_id
    firewall_name = aviatrix_firewall_instance.PAN_firewall.firewall_name
    lan_interface = aviatrix_firewall_instance.PAN_firewall.lan_interface
    management_interface = aviatrix_firewall_instance.PAN_firewall.management_interface
    egress_interface = aviatrix_firewall_instance.PAN_firewall.egress_interface
    attached = true
}

