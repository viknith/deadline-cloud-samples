#!/bin/bash

# Submit After Effects Docker render job
echo "Submitting After Effects Docker render job..."

deadline bundle submit . \
  -p ProjectFile="/Users/viknith/Downloads/Frame_CounterRedGiant(1).aep" \
  -p RenderQueueIndex=1 \
  -p StartFrame=0 \
  -p EndFrame=299 \
  -p OutputDir="./output" \
  -p OutputFilename="FrameCounter_[#####].png" \
  -p ECR_REGISTRY="484745417699.dkr.ecr.us-west-2.amazonaws.com"

echo "Job submitted"