resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "pipeline-artifacts-sheng"
  acl    = "private"
}

variable "root_domain_name" {
  default = "shengni.click"
}

data "aws_iam_policy_document" "cf_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.www.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3-bucket.iam_arn]
    }
  }
}
resource "aws_s3_bucket_policy" "cf_s3_bucket_policy" {
  bucket = aws_s3_bucket.www.id
  policy = data.aws_iam_policy_document.cf_s3_policy.json
}


resource "aws_s3_bucket" "www" {
  bucket = var.root_domain_name
  # acl    = "public-read"
  acl = "private"
  #   policy = <<POLICY
  # {
  #   "Version":"2012-10-17",
  #   "Statement":[
  #     {
  #       "Sid":"AddPerm",
  #       "Effect":"Allow",
  #       "Principal": "*",
  #       "Action":["s3:GetObject"],
  #       "Resource":["arn:aws:s3:::${var.root_domain_name}/*"]
  #     }
  #   ]
  # }
  # POLICY
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.www.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_acm_certificate" "cert" {
  provider = aws.us-east-1

  domain_name       = var.root_domain_name
  validation_method = "DNS"
}

data "aws_route53_zone" "zone" {
  name         = var.root_domain_name
  private_zone = false
}

resource "aws_route53_record" "www" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.www : record.fqdn]
}


resource "aws_cloudfront_distribution" "www_distribution" {
  // origin is where CloudFront gets its content from.
  origin {
    // We need to set up a "custom" origin because otherwise CloudFront won't
    // redirect traffic from the root domain to the www domain, that is from
    // runatlantis.io to www.runatlantis.io.
    # custom_origin_config {
    #   // These are all the defaults.
    #   http_port              = "80"
    #   https_port             = "443"
    #   origin_protocol_policy = "http-only"
    #   origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    # }

    // Here we're using our S3 bucket's URL!
    # domain_name = "${aws_s3_bucket.www.website_endpoint}"
    domain_name = aws_s3_bucket.www.bucket_regional_domain_name
    // This can be any name to identify this origin.
    origin_id = var.root_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3-bucket.cloudfront_access_identity_path
    }

  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl  = 10
  }
  enabled             = true
  default_root_object = "index.html"

  // All values are defaults from the AWS console.
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    // This needs to match the `origin_id` above.
    target_origin_id = var.root_domain_name
    min_ttl          = 0
    default_ttl      = 300
    max_ttl          = 3600

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }




  }

  aliases = ["${var.root_domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
  ordered_cache_behavior {
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    # lambda_function_association {
    #   event_type = "origin-request"
    #   lambda_arn = aws_lambda_function.lambda_edge.qualified_arn
    # }
    path_pattern = "*"

    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = var.root_domain_name
  }
}



// This Route53 record will point at our CloudFront distribution.
resource "aws_route53_record" "record_a" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.root_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.www_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_identity" "s3-bucket" {
  comment = "35front"
}