# After Effects Docker Render Job Bundle

This job bundle renders After Effects projects using Docker containers on Windows workers. The job handles Docker startup, ECR authentication, and runs After Effects rendering inside a container.

## Prerequisites

- Windows workers with Docker Desktop installed (use host configuration script)
- ECR registry with `ae-redgiant-full:latest` container image
- After Effects project file (.aep or .aepx)

## Usage

### Using the Submit Script

Edit `submit.sh` with your project details:

```bash
deadline bundle submit . \
  -p ProjectFile="/path/to/your/project.aep" \
  -p StartFrame=1 \
  -p EndFrame=100 \
  -p ECR_REGISTRY="your-account.dkr.ecr.region.amazonaws.com"
```

Then run: `./submit.sh`

### Manual Submission

```bash
deadline bundle submit job_bundles/aftereffects_docker_render \
  -p ProjectFile="my_project.aep" \
  -p StartFrame=1 \
  -p EndFrame=100
```

## Parameters

- **ProjectFile**: After Effects project file path
- **RenderQueueIndex**: Render queue item to use (default: 1)
- **StartFrame**: First frame to render (default: 96)
- **EndFrame**: Last frame to render (default: 215)
- **OutputDir**: Output directory (default: "./output")
- **ECR_REGISTRY**: ECR registry URI

## What to Change

Update these values in `submit.sh` for your project:

- **ProjectFile**: Path to your After Effects project
- **StartFrame/EndFrame**: Frame range for your composition
- **ECR_REGISTRY**: Your ECR registry if different from default

## How It Works

The job automatically starts Docker Desktop, waits for required processes, authenticates with ECR, and runs After Effects rendering in a Windows container with your project files mounted.

## Troubleshooting

- **Docker not starting**: Ensure Docker Desktop installed via host configuration
- **ECR auth fails**: Check AWS credentials and registry URI
- **Container not found**: Verify `ae-redgiant-full:latest` exists in ECR
- **Render fails**: Check project file and render queue settings