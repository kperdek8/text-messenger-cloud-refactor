resource "aws_lb" "app" {
  name               = "text-messenger-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group]
  subnets            = var.subnet_ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }	
}

resource "aws_lb_target_group" "tg" {
  for_each = {
	frontend = 8888
    auth-service = 4000
    user-service = 4001
    chat-service = 4002
	file-service = 4003
	notification-service = 4004
  }

  name        = "tg-${each.key}"
  port        = each.value
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["auth-service"].arn
  }

  condition {
    path_pattern {
      values = ["/api/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "user" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["user-service"].arn
  }

  condition {
    path_pattern {
      values = ["/api/users/*"]
    }
  }
}

resource "aws_lb_listener_rule" "socket" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 25

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["chat-service"].arn
  }

  condition {
    path_pattern {
      values = ["/socket/websocket"]
    }
  }
}

resource "aws_lb_listener_rule" "chat" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["chat-service"].arn
  }

  condition {
    path_pattern {
      values = ["/api/chats/*"]
    }
  }
}

resource "aws_lb_listener_rule" "file" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["file-service"].arn
  }

  condition {
    path_pattern {
      values = ["/api/files/*"]
    }
  }
}

resource "aws_lb_listener_rule" "notification" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["notification-service"].arn
  }

  condition {
    path_pattern {
      values = ["/api/notifications/*"]
    }
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["frontend"].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_cloudwatch_log_group" "log_group" {
  for_each = { for svc in var.services : svc.name => svc }

  name              = "/ecs/${each.key}"
  retention_in_days = 7
}


resource "aws_ecs_task_definition" "tasks" {
  for_each = { for svc in var.services : svc.name => svc }

  family                   = each.key
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024

  execution_role_arn = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      portMappings = [{
        containerPort = each.value.container_port
        protocol      = "tcp"
      }]
      environment = concat([
        for pair in each.value.env_vars : {
          name  = pair.name
          value = pair.value
        }],
	    [
		  {
		    name  = "PHX_HOST"
		    value = aws_lb.app.dns_name
	      },
		  {
        name  = "API_URL"
        value = "http://${aws_lb.app.dns_name}/api"
		  },
		  {
        name  = "SOCKET_URL"
        value = "ws://${aws_lb.app.dns_name}/socket/websocket"
		  }
		]
	  )
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${each.key}"
          awslogs-region        = var.region
          awslogs-stream-prefix = each.key
        }
      }
    }
  ])
}

resource "aws_ecs_service" "services" {
  for_each = { for svc in var.services : svc.name => svc }

  name            = each.key
  cluster         = aws_ecs_cluster.cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.tasks[each.key].arn
  desired_count   = 2

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group]
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.tg[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }

}