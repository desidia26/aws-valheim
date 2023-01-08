terraform {
  backend "s3" {
    bucket = "valheim-state"
    key    = "tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  default_tags {
    tags = {
      Workspace = terraform.workspace
    }
  }
}
