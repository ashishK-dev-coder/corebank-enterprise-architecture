terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "google" {
  project = "your-gcp-project-id" # Replace with your actual GCP project ID from your billing console
  region  = "asia-south1"         # Deploying close to target user base for low latency
}

provider "aws" {
  region = "ap-south-1"
}
