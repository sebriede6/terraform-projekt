
provider "aws" {
  region = "eu-central-1" # Wähle deine bevorzugte AWS Region
  default_tags {
    tags = {
      TerraformManaged = "true"
      Project          = "aws-s3-research-exercise"
    }
  }
}

provider "random" {}