# Remote state backend configuration
# This ensures state persistence across GitHub Actions runs

terraform {
  backend "s3" {
    bucket = "terraform-practice-1505"
    key    = "terraform/cis-benchmark-checker/terraform.tfstate"
    region = "us-east-1"
  }
}
