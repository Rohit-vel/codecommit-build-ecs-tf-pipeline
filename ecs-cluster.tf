data "aws_iam_policy_document" "assume_by_ecs" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecr-execution_role-doc" {
  statement {
    sid    = "AllowECRLogging"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "task_role_policy_doc" {
  statement {
    sid    = "AllowDescribeCluster"
    effect = "Allow"

    actions = ["ecs:DescribeClusters"]

    resources = ["${aws_ecs_cluster.tf-cluster.arn}"]
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.service_name}_ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_by_ecs.json
}

resource "aws_iam_role_policy" "execution_role-policy" {
  role   = aws_iam_role.execution_role.name
  policy = data.aws_iam_policy_document.ecr-execution_role-doc.json
}

resource "aws_iam_role" "ecs-task-role" {
  name               = "ecs-Task-Role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_ecs.json
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  role   = aws_iam_role.ecs-task-role.name
  policy = data.aws_iam_policy_document.task_role_policy_doc.json
}

resource "aws_ecs_cluster" "tf-cluster" {
  name = "tf_cluster"
}

resource "aws_security_group" "ecs" {
  name = "${var.service_name}-allow-ecs"
   vpc_id = "${aws_vpc.ecs-vpc.id}"

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    #  security_groups = ["${aws_security_group.alb.id}"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
