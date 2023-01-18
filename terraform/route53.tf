data "aws_route53_zone" "valheim_domain" {
  name         = "vikingbonobos.com"
  private_zone = false
}

resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.valheim_domain.zone_id # Replace with your zone ID
  name    = "vikingbonobos.com"
  type    = "A"
  records = ["0.0.0.0"]
  ttl     = 300
}