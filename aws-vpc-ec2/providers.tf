provider "aws" {
  region = "eu-central-1" 

  default_tags {
    tags = {
      TerraformManaged = "true"
      Project          = "aws-vpc-ec2-ubuntu" 
      Owner            = "SebastianRiede"  
    }
  }
}