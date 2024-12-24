#!/bin/bash

if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
    echo "Error: AWS_ACCOUNT_ID and AWS_REGION must be set as environment variables."
    exit 1
fi

REPO_NAME="orbit-api"
IMAGE_TAG="latest"

ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME"

echo "Building Docker image..."
docker build -t $REPO_NAME .

if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting."
    exit 1
fi

echo "Tagging the Docker image for ECR..."
docker tag $REPO_NAME:$IMAGE_TAG $ECR_URI:$IMAGE_TAG

echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

if [ $? -ne 0 ]; then
    echo "Failed to authenticate with ECR. Exiting."
    exit 1
fi

echo "Pushing the Docker image to ECR..."
docker push $ECR_URI:$IMAGE_TAG

if [ $? -ne 0 ]; then
    echo "Failed to push the image to ECR. Exiting."
    exit 1
fi

echo "Docker image successfully pushed to $ECR_URI:$IMAGE_TAG"
