#!/bin/bash

# Submit After Effects Docker render job
echo "Submitting After Effects Docker render job..."

deadline bundle submit . \
  -p ProjectFile="/Users/viknith/Downloads/titleFlip (converted).aep" \
  -p RenderQueueIndex=1 \
  -p StartFrame=96 \
  -p EndFrame=215 \
  -p OutputDir="./output" \
  -p ECR_REGISTRY="484745417699.dkr.ecr.us-west-2.amazonaws.com"

echo "Job submitted"