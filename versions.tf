terraform {
  cloud {
    organization = "statgen"
    workspaces {
      tags = ["bravo", "api"]
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }

  required_version = ">= 1.1.0"
}
