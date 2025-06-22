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
  cpu                      = 256
  memory                   = 512

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
		    value = var.apigw_dns_name
	      },
		  {
        name  = "API_URL"
        value = "https://${var.apigw_dns_name}/api"
		  },
		  {
        name  = "SOCKET_URL"
        value = "ws://${var.lb_dns_name}/socket/websocket"
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
  desired_count   = each.value.count

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group]
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = var.target_groups[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }

}