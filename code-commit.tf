resource "aws_codecommit_repository" "codecommit" {
  repository_name = "codecommit"
}

resource "aws_codecommit_trigger" "codecommit" {
  repository_name = aws_codecommit_repository.codecommit.repository_name

  trigger {
    name            = "all"
    events          = ["all"]
    destination_arn = "${aws_sns_topic.user_updates.arn}"
  }
}

#############################################################################################

resource "aws_sns_topic" "user_updates" {
  name = "user-updates-topic"
}


#############################################################################################

data "aws_iam_policy_document" "assume_by_codecommit" {
  statement {
    sid     = "AllowAssumeByCodecommit"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codecommit.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codecommit-role" {
  name               = "${var.service_name}-codecommit-role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_codecommit.json
}

data "aws_iam_policy_document" "codecommit" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowECR"
    effect = "Allow"

    actions = [
      "ecr:*"
    ]

    resources = ["*"]
  }

statement {
    sid    = "AWSKMSUse"
    effect = "Allow"

    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]

    resources = ["*"]
  }

  statement {
    sid       = "AllowECSDescribeTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }


statement {
    sid    = "AllowCloudwatch"
    effect = "Allow"

    actions = [
      "cloudwatch:ListDashboards",
      "cloudwatch:ListMetrics",
      "cloudwatch:ListMetricStreams",
      "cloudwatch:ListTagsForResource",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAnomalyDetectors",
      "cloudwatch:DescribeInsightRules",
      "cloudwatch:GetDashboard",
      "cloudwatch:GetInsightRuleReport",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricStream",
      "cloudwatch:GetMetricWidgetImage",
      "cloudwatch:*"
    ]
    resources = ["*"]
  }


  statement {
    sid    = "AllowCodedepoloy"
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }

statement {
    sid    = "AllowResources"
    effect = "Allow"

    actions = [
      "elasticbeanstalk:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*",
      "opsworks:*",
      "devicefarm:*",
      "servicecatalog:*",
      "codepipeline:StartPipelineExecution",
      "iam:PassRole"
    ]
    resources = ["*"]
  }


}

resource "aws_iam_role_policy" "codecommit" {
  role   = aws_iam_role.codecommit-role.name
  policy = data.aws_iam_policy_document.codecommit.json
}


