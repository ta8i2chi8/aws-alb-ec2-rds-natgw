data "http" "my_ip" {
  url = "https://ifconfig.me"
}

locals {
  alb_security_group_ingress_rules = [
    {
      cidr      = "0.0.0.0/0"
      from_port = "80"
      to_port   = "80"
    }
  ]
  web_security_group_ingress_rules = [
    {
      referenced_security_group_id = aws_security_group.eic_endpoint.id
      from_port                    = "22"
      to_port                      = "22"
    },
    {
      referenced_security_group_id = aws_security_group.alb.id
      from_port                    = "80"
      to_port                      = "80"
    }
  ]
}

# ALB
resource "aws_lb" "main" {
  name               = "${var.pj_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.pj_name}-alb"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "main" {
  name             = "${var.pj_name}-tg"
  target_type      = "instance"
  protocol_version = "HTTP1"
  port             = 80
  protocol         = "HTTP"
  vpc_id           = var.vpc_id

  health_check {
    # WordPressの初期画面のパスは"/wp-admin/setup-config"になるためヘルスチェックパスは以下で設定。
    # "/"だと、unhealthyとなりエラーになる。
    path                = "/wp-admin/setup-config.php"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.pj_name}-tg"
  }
}

# ターゲットグループへのターゲット登録
resource "aws_lb_target_group_attachment" "wordpress_server" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.wordpress_server.id
}

# リスナー（HTTP）
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ALB用セキュリティグループ
resource "aws_security_group" "alb" {
  name        = "${var.pj_name}-alb-sg"
  description = "${var.pj_name} alb sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.pj_name}-alb-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "alb" {
  count = length(local.alb_security_group_ingress_rules)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = local.alb_security_group_ingress_rules[count.index].cidr
  ip_protocol       = "TCP"
  from_port         = local.alb_security_group_ingress_rules[count.index].from_port
  to_port           = local.alb_security_group_ingress_rules[count.index].to_port
}
resource "aws_vpc_security_group_egress_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# EC2のAMI取得用SSM
data "aws_ssm_parameter" "amzn2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# EC2
resource "aws_instance" "wordpress_server" {
  ami                         = data.aws_ssm_parameter.amzn2.value
  instance_type               = "t2.micro"
  subnet_id                   = var.web_private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.wordpress_server.id]
  key_name                    = "nginx-web-server-key"
  associate_public_ip_address = false

  tags = {
    Name = "${var.pj_name}-ec2"
  }

  # WordPress
  user_data = <<-EOF
                  #!/bin/bash
                  yum update -y
                  amazon-linux-extras install php7.4 -y
                  yum -y install mysql httpd php-mbstring php-xml

                  wget http://ja.wordpress.org/latest-ja.tar.gz -P /tmp/
                  tar zxvf /tmp/latest-ja.tar.gz -C /tmp
                  cp -r /tmp/wordpress/* /var/www/html/
                  chown apache:apache -R /var/www/html

                  systemctl enable httpd.service
                  systemctl start httpd.service
                EOF
}

# EC2用セキュリティグループ
resource "aws_security_group" "wordpress_server" {
  name        = "${var.pj_name}-wordpress-server-sg"
  description = "${var.pj_name} wordpress server sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.pj_name}-wordpress-server-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "wordpress_server" {
  count = length(local.web_security_group_ingress_rules)

  security_group_id            = aws_security_group.wordpress_server.id
  referenced_security_group_id = local.web_security_group_ingress_rules[count.index].referenced_security_group_id
  ip_protocol                  = "TCP"
  from_port                    = local.web_security_group_ingress_rules[count.index].from_port
  to_port                      = local.web_security_group_ingress_rules[count.index].to_port
}
resource "aws_vpc_security_group_egress_rule" "wordpress_server" {
  security_group_id = aws_security_group.wordpress_server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# EIC Endpoint
resource "aws_ec2_instance_connect_endpoint" "wordpress_server" {
  subnet_id          = var.web_private_subnet_ids[0]
  security_group_ids = [aws_security_group.eic_endpoint.id]
  preserve_client_ip = false

  tags = {
    Name = "${var.pj_name}-eic-endpoint"
  }
}

# EIC Endpoint用セキュリティグループ
resource "aws_security_group" "eic_endpoint" {
  name        = "${var.pj_name}-eic-endpoint-sg"
  description = "${var.pj_name} eic endpoint sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.pj_name}-eic-endpoint-sg"
  }
}
resource "aws_vpc_security_group_egress_rule" "eic_endpoint" {
  security_group_id = aws_security_group.eic_endpoint.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "TCP"
  from_port         = "22"
  to_port           = "22"
}
