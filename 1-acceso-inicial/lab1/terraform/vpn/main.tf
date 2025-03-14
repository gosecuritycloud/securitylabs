

module "vpn" {
  source = "./module/vpn"
  aws_region = "us-east-1"
  security_groups = "sg-07b4a39a7258c0516,"
  port = "22,443"
}
