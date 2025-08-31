#!/bin/bash
set -e

# Configuration
ECR_REGISTRY="484745417699.dkr.ecr.us-west-2.amazonaws.com"
REPOSITORY_NAME="ae-redgiant"
REGION="us-west-2"
IMAGE_TAG="latest"

echo "Building After Effects Docker image..."

# Step 1: Create ECR repository (ignore if exists)
echo "Creating ECR repository..."
aws ecr create-repository --repository-name $REPOSITORY_NAME --region $REGION || echo "Repository already exists"

# Step 2: Build Docker image
echo "Building Docker image (this will take 15-20 minutes)..."
docker build -t ae-redgiant-windows .

# Step 3: Get ECR login
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Step 4: Tag image
echo "Tagging image..."
docker tag ae-redgiant-windows:$IMAGE_TAG $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG

# Step 5: Push image
echo "Pushing image to ECR..."
docker push $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG

# Step 6: Verify image
echo "Verifying image in ECR..."
aws ecr describe-images --repository-name $REPOSITORY_NAME --region $REGION

echo "Build complete! Image available at: $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG"