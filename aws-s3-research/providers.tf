
provider "aws" {
  region = "eu-central-1" 
  default_tags {
    tags = {
      TerraformManaged = "true"
      Project          = "aws-s3-research-exercise"
    }
  }
}

provider "random" {}