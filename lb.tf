locals {
  target_groups = ["primary", "secondary"]
  hosts_name = ["aws_instance.ECS-Instance.id"] #example : fill your information
}

resource "aws_security_group" "alb" {
  name   = "${var.service_name}-allow-http"
  vpc_id = "${aws_vpc.ecs-vpc.id}"

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.service_name}-allow-http"
  }
}

resource "aws_lb" "this" {
  name               = "${var.service_name}-service-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb.id}"]
  subnets            = "${aws_subnet.public.*.id}"

  tags = {
    Name = "${var.service_name}-service-alb"
  }
}

resource "aws_lb_target_group" "this" {
  count = "${length(local.target_groups)}"
  name  = "${var.service_name}-tg-${element(local.target_groups, count.index)}"

  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.ecs-vpc.id}"
  target_type = "instance"

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.this.0.arn}"
  }
}

resource "aws_lb_listener_rule" "this" {
  count        = 2
  listener_arn = "${aws_lb_listener.this.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.this.*.arn[count.index]}"
  }



condition {
   path_pattern {
      values = ["/static/*"]
    }
  }

  condition {
    host_header {
      values = ["index.html"]
    }
  }

 # condition {
   # field  = "host-header"
  #  values = "${local.hosts_name}"
 # }
}
