# Proyecto: Hosting seguro de sitio web estático en AWS con Terraform

# Proveedor AWS configurado para us-east-1
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.4.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

# Crear bucket S3 para alojar el sitio web
resource "aws_s3_bucket" "website_bucket" {
  bucket = "isabel-portfolio-bucket"

  tags = {
    Name = "SitioWebIsabel"
  }
}

# Bloquear el acceso público al bucket
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Política del bucket para permitir acceso desde CloudFront solamente
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

# Configuración de sitio web en el bucket
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# Crear Origin Access Control (OAC) para CloudFront
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "OAC-Isabel"
  description                       = "Control de acceso entre CloudFront y S3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  origin_access_control_origin_type = "s3"
}

# Crear la distribución de CloudFront para servir el sitio
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "CloudFront-Isabel"
  }
}

# Output para mostrar la URL final del sitio distribuido
output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
