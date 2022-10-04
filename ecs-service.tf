resource "aws_ecs_service" "tf-ecs-service" {
  name            = "tf-ecs-service"
  task_definition = aws_ecs_task_definition.tf-task-def.id
  cluster         = aws_ecs_cluster.tf-cluster.arn

  load_balancer {
   target_group_arn = "${aws_lb_target_group.this.0.arn}"
  container_name   = "${var.service_name}"
  container_port   = "${var.container_port}"
  }

  launch_type                        = "EC2"
  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [aws_lb_listener.this]
}
