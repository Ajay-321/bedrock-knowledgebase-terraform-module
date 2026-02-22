terraform {
  backend "s3" {
    bucket = "terraform-backend-bucket-us-east-1-dev"
    key    = "dev/us-east1/us-east1.tfstate" #updated as per your standard naming convention
    region = "us-east-1"                     #region
  }
}