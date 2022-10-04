#locals { #example : fill your information
# github_token = ""
#github_owner = "gnokoheat"
#github_repo = "ecs-nodejs-app-example"
#github_branch = "master"
#}

resource "aws_s3_bucket" "ft-pipeline-28-09" {
  bucket = "tf-pipeline-28-09"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "${var.service_name}Codepipeline",
  "Statement": [
        {
            "Sid": "DenyUnEncryptedObjectUploads",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::tf-pipeline-28-09/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": "aws:kms"
                }
            }
        },
        {
            "Sid": "DenyInsecureConnections",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::tf-pipeline-28-09/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

data "aws_iam_policy_document" "assume_by_pipeline" {
  statement {
    sid     = "AllowAssumeByPipeline"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "tf-pipeline-role" {
  name               = "tf-pipeline-ecs-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_pipeline.json
}

data "aws_iam_policy_document" "pipeline" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowECR"
    effect = "Allow"

    actions   = ["ecr:DescribeImages"]
    resources = ["*"]
  }

statement {
    sid    = "AllowCodecommit"
    effect = "Allow"

    actions = [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetRepository",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive",
    ]
    resources = ["*"]
  }


  statement {
    sid    = "AllowCodebuild"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
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
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "pipeline" {
  role   = aws_iam_role.tf-pipeline-role.name
  policy = data.aws_iam_policy_document.pipeline.json
}

resource "aws_codepipeline" "ecs-ecr-tf-pipeline" {
  name     = "ecs-ecr-tf-pipeline"
  role_arn = aws_iam_role.tf-pipeline-role.arn

  artifact_store {
    location = "tf-pipeline-28-09"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CODECOMMIT"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        #OAuthToken = "${local.github_token}"
        #Owner = "${local.github_owner}"
        RepositoryName = "${aws_codecommit_repository.codecommit.arn}"
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = "${aws_codebuild_project.tf-codebuild-project.name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "ExternalDeploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        ApplicationName                = "tf-application"
        DeploymentGroupName            = "tf-deployment-group"
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "BuildArtifact"
        AppSpecTemplatePath            = "appspec.yml"
      }
    }
  }
}
