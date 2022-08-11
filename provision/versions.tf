terraform {
  cloud {
    organization = "statgen"
    workspaces {
      name = "bravo-ci-staging"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }

  required_version = ">= 1.1.0"
}
