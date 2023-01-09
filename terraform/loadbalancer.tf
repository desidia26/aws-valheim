resource "aws_lb" "network_load_balancer" {
  name               = "${terraform.workspace}-valheim-lb"
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]
}

resource "aws_lb_target_group" "valheim_target_group" {
  name        = "valheim-target-group"
  port        = 2456
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    protocol = "HTTP"
    port = 80
    path ="/status.json"
    matcher =  "200-299"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.network_load_balancer.arn}"
  port              = "2456"
  protocol          = "UDP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.valheim_target_group.arn}" 
  }
}

resource "aws_lb_target_group" "status_target_group" {
  name        = "status-target-group"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    protocol = "HTTP"
    port = 80
    path ="/status.json"
    matcher =  "200-299"
  }
}

resource "aws_lb_listener" "status_listener" {
  load_balancer_arn = "${aws_lb.network_load_balancer.arn}"
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.status_target_group.arn}" 
  }
}

data "aws_route53_zone" "valheim_domain" {
  name         = "vikingbonobos.com"
  private_zone = false
}

resource "aws_route53_record" "alias_route53_record" {
  zone_id = data.aws_route53_zone.valheim_domain.zone_id # Replace with your zone ID
  name    = "vikingbonobos.com"
  type    = "A"
  alias {
    name                   = aws_lb.network_load_balancer.dns_name
    zone_id                = aws_lb.network_load_balancer.zone_id
    evaluate_target_health = true
  }
}