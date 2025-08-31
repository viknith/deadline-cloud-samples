#!/bin/bash

# Test submission script for After Effects Docker render job

set -e

echo "Testing After Effects Docker render job submission..."

# Check if deadline CLI is available
if ! command -v deadline &> /dev/null; then
    echo "ERROR: deadline CLI not found. Please install deadline-cloud CLI."
    exit 1
fi

# Test parameters
PROJECT_FILE="test_project.aep"
OUTPUT_DIR="./test_output"
FRAMES="1-10"
CHUNK_SIZE="5"

echo "Submitting test job with parameters:"
echo "  Project: $PROJECT_FILE"
echo "  Output: $OUTPUT_DIR"
echo "  Frames: $FRAMES"
echo "  Chunk Size: $CHUNK_SIZE"

# Submit the job
deadline bundle submit . \
  -p ProjectFile="$PROJECT_FILE" \
  -p RenderQueueIndex=1 \
  -p OutputDir="$OUTPUT_DIR" \
  -p OutputFileName="test_frame_####.png" \
  -p Frames="$FRAMES" \
  -p ChunkSize=$CHUNK_SIZE \
  -p ECR_REGISTRY="484745417699.dkr.ecr.us-west-2.amazonaws.com"

echo "Job submitted successfully!"
echo "Monitor job progress with: deadline job list"