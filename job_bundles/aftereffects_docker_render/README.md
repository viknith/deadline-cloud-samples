# After Effects Docker Render Job Bundle

This job bundle renders After Effects projects using Docker containers with pre-installed software.

## Prerequisites

1. Docker image built and pushed to ECR (see `../../docker/aftereffects/README.md`)
2. Windows workers with Docker Desktop installed
3. Deadline Cloud CLI configured

## Usage

### Basic Submission

```bash
deadline bundle submit job_bundles/aftereffects_docker_render \
  -p ProjectFile=my_project.aep \
  -p RenderQueueIndex=1 \
  -p OutputDir=./output \
  -p Frames="1-100" \
  -p ChunkSize=10
```

### Advanced Parameters

```bash
deadline bundle submit job_bundles/aftereffects_docker_render \
  -p ProjectFile=complex_project.aep \
  -p RenderQueueIndex=2 \
  -p OutputDir=./renders \
  -p OutputFileName="final_render_####.exr" \
  -p Frames="50-200" \
  -p ChunkSize=25 \
  -p ECR_REGISTRY=484745417699.dkr.ecr.us-west-2.amazonaws.com
```

## Parameters

- **ProjectFile**: After Effects project file (.aep or .aepx)
- **RenderQueueIndex**: Which render queue item to render (default: 1)
- **OutputDir**: Directory for rendered frames (default: ./output)
- **OutputFileName**: Output filename pattern (default: output_####.png)
- **Frames**: Frame range to render (default: 1-100)
- **ChunkSize**: Frames per task for parallel processing (default: 10)
- **ECR_REGISTRY**: ECR registry URI (default: 484745417699.dkr.ecr.us-west-2.amazonaws.com)

## How It Works

1. **Job Submission**: Project files uploaded to S3 via Job Attachments
2. **Worker Assignment**: Windows workers with Docker pull the ECR image
3. **Container Execution**: Docker runs with bind mounts for project and output files
4. **Frame Rendering**: After Effects renders frame chunks in parallel
5. **Output Upload**: Rendered frames uploaded to S3 via Job Attachments

## File Structure

```
aftereffects_docker_render/
├── template.yaml              # Job template definition
├── scripts/
│   ├── call_aerender.py      # Main rendering script
│   ├── create_output_directory.py
│   ├── font_manager.py       # Font installation utilities
│   └── get_user_fonts.py     # Project font detection
└── README.md
```

## Troubleshooting

- **Container not found**: Verify ECR registry URI and image exists
- **Permission denied**: Ensure Docker Desktop is running with Windows containers
- **Render fails**: Check After Effects project compatibility and render queue settings
- **Missing fonts**: Ensure fonts are in a `fonts/` directory relative to the project file