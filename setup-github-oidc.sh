#!/bin/bash

# Create OIDC identity provider for GitHub Actions
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com

# Create role for GitHub Actions
aws iam create-role \
  --role-name GitHubActionsRole-lobechat \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::467522932754:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:cnkang/lobe-chat:ref:refs/heads/dev-codebuild"
          }
        }
      }
    ]
  }'

# Attach ECR permissions
aws iam attach-role-policy \
  --role-name GitHubActionsRole-lobechat \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

echo "Role ARN: arn:aws:iam::467522932754:role/GitHubActionsRole-lobechat"
echo "Add this to GitHub secrets as AWS_ROLE_ARN"