# After Effects Docker Container - Phase 1: Build Docker Image

This guide covers building a Windows Docker container with Adobe After Effects, Red Giant, and Universe pre-installed for use with AWS Deadline Cloud.

## Phase 1 Overview

```
INPUT                    PROCESS                     OUTPUT
┌─────────────────┐     ┌─────────────────┐        ┌─────────────────┐
│ S3 Bucket       │     │ Docker Build    │        │ ECR Repository  │
│ ├── AE.zip      │────►│ ├── Download    │───────►│ ├── ae-redgiant │
│ ├── RG.exe      │     │ ├── Install     │        │ │   :latest     │
│ ├── Universe    │     │ ├── Configure   │        │ └── 7GB image   │
│ └── Maxon.exe   │     │ └── 15-20 min   │        │     ready       │
└─────────────────┘     └─────────────────┘        └─────────────────┘

Local Files              Build Machine               Cloud Storage
┌─────────────────┐     ┌─────────────────┐        ┌─────────────────┐
│ ├── Dockerfile  │────►│ docker build    │───────►│ docker push     │
│ └── install.ps1 │     │ -t ae-redgiant  │        │ to ECR          │
└─────────────────┘     └─────────────────┘        └─────────────────┘
```

## Prerequisites

- AWS CLI configured with credentials
- Python installed locally
- Docker Desktop with Windows containers enabled
- S3 bucket with software installers (see [host configuration guide](../../host_configuration_scripts/aftereffects/aftereffects_redgiant/README.md))

## Project Structure

Create the following directory structure:

```
ae-docker-build/
├── Dockerfile
├── install-software.ps1
└── README.md
```

## Step 1: Update Configuration

Edit `install-software.ps1` and update these variables:

```powershell
$INSTALLER_S3_BUCKET = "your-actual-bucket-name"  # Replace with your S3 bucket
$vpc_endpoint = "your-vpc-endpoint"  # Replace if using CMF
```

Verify installer file names match what's in your S3 bucket.

## Step 2: Create Dockerfile

```dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2022
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

COPY install-software.ps1 C:/
RUN C:/install-software.ps1

WORKDIR C:/workspace
```

## Step 3: Create ECR Repository

```bash
aws ecr create-repository --repository-name ae-redgiant --region us-west-2
```

## Step 4: Build Docker Image

```bash
docker build -t ae-redgiant-windows .
```

> **Note**: This build process will take 15-20 minutes as it downloads and installs all software.

## Step 5: Tag and Push to ECR

```bash
# Get ECR login
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 484745417699.dkr.ecr.us-west-2.amazonaws.com

# Tag image
docker tag ae-redgiant-windows:latest 484745417699.dkr.ecr.us-west-2.amazonaws.com/ae-redgiant:latest

# Push image
docker push 484745417699.dkr.ecr.us-west-2.amazonaws.com/ae-redgiant:latest
```

## Step 6: Verify Image

```bash
aws ecr describe-images --repository-name ae-redgiant --region us-west-2
```

## Result

You now have a Docker image in ECR with:
- Adobe After Effects 2025
- Red Giant plugins
- Universe plugins
- Maxon App
- All necessary environment variables configured

The image is ready for Phase 2: Creating the job template.

---

# Phase 2: Create Docker Job Template

This phase creates a Deadline Cloud job template that uses the Docker image built in Phase 1.

## Phase 2 Overview

```
INPUT                    PROCESS                     OUTPUT
┌─────────────────┐     ┌─────────────────┐        ┌─────────────────┐
│ User Submission │     │ Deadline Cloud  │        │ Rendered Files  │
│ ├── project.aep │────►│ ├── Schedule    │───────►│ ├── frame_001   │
│ ├── scripts/    │     │ ├── Download    │        │ ├── frame_002   │
│ └── parameters  │     │ └── Execute     │        │ └── ...         │
└─────────────────┘     └─────────────────┘        └─────────────────┘

ECR Image               Worker Node                 S3 Output
┌─────────────────┐     ┌─────────────────┐        ┌─────────────────┐
│ ae-redgiant     │────►│ docker run      │───────►│ Job Attachments │
│ :latest         │     │ --rm -v mounts  │        │ Upload          │
│ (pre-installed) │     │ call_aerender   │        │                 │
└─────────────────┘     └─────────────────┘        └─────────────────┘
```

## Step 1: Create Job Bundle Structure

```bash
cd /path/to/deadline-cloud-samples
mkdir -p job_bundles/aftereffects_docker_render/scripts
```

## Step 2: Copy Required Scripts

Copy the After Effects scripts from the official submitter:

```bash
# Copy all Python scripts
cp /path/to/deadline-cloud-for-after-effects/dist/DeadlineCloudSubmitter_Assets/JobTemplate/scripts/* \
   job_bundles/aftereffects_docker_render/scripts/
```

## Step 3: Create Job Template

Create `job_bundles/aftereffects_docker_render/template.yaml`:

```yaml
specificationVersion: jobtemplate-2023-09
name: After Effects Docker Render
description: Render After Effects projects using Docker containers
parameterDefinitions:
  - name: ProjectFile
    type: PATH
    objectType: FILE
    dataFlow: IN
    userInterface:
      control: CHOOSE_INPUT_FILE
      label: Project file
      groupLabel: Source
      fileFilters:
        - label: After Effects project files
          patterns:
            - "*.aep"
            - "*.aepx"
    description: The After Effects project file to render

  - name: RenderQueueIndex
    type: INT
    userInterface:
      control: SPIN_BOX
      label: Render Queue Index
      groupLabel: Source
    default: 1
    description: The index of the item in the render queue to render

  - name: OutputDir
    type: PATH
    objectType: DIRECTORY
    dataFlow: OUT
    userInterface:
      control: CHOOSE_DIRECTORY
      label: Output Directory
      groupLabel: Render Parameters
    default: "./output"
    description: Choose the render output directory

  - name: OutputFileName
    type: STRING
    userInterface:
      control: LINE_EDIT
      label: Output File Pattern
      groupLabel: Render Parameters
    default: "output_####.png"
    description: Output filename pattern

  - name: Frames
    type: STRING
    userInterface:
      control: LINE_EDIT
      label: Start Frame - End Frame
      groupLabel: Frame Range
    default: "1-100"
    description: Frame range to render

  - name: ChunkSize
    type: INT
    userInterface:
      control: SPIN_BOX
      label: Frames Per Task
      groupLabel: Frame Range
    default: 10
    minValue: 1
    description: Number of frames per task for chunking

  - name: ECR_REGISTRY
    type: STRING
    userInterface:
      control: LINE_EDIT
      label: ECR Registry
      groupLabel: Docker Settings
    default: "484745417699.dkr.ecr.us-west-2.amazonaws.com"
    description: ECR registry URI

  - name: JobScriptDir
    type: PATH
    objectType: DIRECTORY
    dataFlow: IN
    userInterface:
      control: HIDDEN
    default: "scripts"
    description: Directory containing scripts

jobEnvironments:
  - name: Create Output Directories
    description: Create output directories
    script:
      actions:
        onEnter:
          command: powershell
          args:
            - "-Command"
            - "if (-not (Test-Path '{{Param.OutputDir}}')) { New-Item -ItemType Directory -Path '{{Param.OutputDir}}' -Force }"

steps:
  - name: "Render Frames {{Param.Frames}}"
    hostRequirements:
      attributes:
        - name: attr.worker.os.family
          anyOf:
            - windows
    parameterSpace:
      taskParameterDefinitions:
        - name: Index
          type: INT
          range: "{{Param.Frames}}:{{Param.ChunkSize}}"
    script:
      actions:
        onRun:
          command: powershell
          args:
            - "{{Task.File.Run}}"
      embeddedFiles:
        - name: Run
          type: TEXT
          data: |
            $ErrorActionPreference = "Stop"

            Write-Host "Starting Docker AE render - Task {{Task.Param.Index}}"
            Write-Host "Project: {{Param.ProjectFile}}"
            Write-Host "RQ Index: {{Param.RenderQueueIndex}}"
            Write-Host "Chunk: {{Task.Param.Index}} (size: {{Param.ChunkSize}})"

            # Run Docker container with call_aerender.py
            docker run --rm `
              -v "{{Session.WorkingDirectory}}:C:\workspace" `
              -v "{{Param.OutputDir}}:C:\output" `
              -e AERENDER_EXECUTABLE="C:\Program Files\Adobe\Adobe After Effects 2025\Support Files\aerender.exe" `
              -e MAXON_RENDERONLY="true" `
              {{Param.ECR_REGISTRY}}/ae-redgiant:latest `
              python C:\workspace\{{Param.JobScriptDir}}\call_aerender.py `
              "C:\workspace\{{Param.ProjectFile}}" `
              {{Param.RenderQueueIndex}} `
              "C:\output\{{Param.OutputFileName}}" `
              "{{Param.Frames}}" `
              --chunk-size {{Param.ChunkSize}} `
              --index {{Task.Param.Index}} `
              --multi-frame-rendering OFF `
              --max-cpu-usage-percentage 90

            if ($LASTEXITCODE -ne 0) {
                throw "Docker render failed with exit code $LASTEXITCODE"
            }

            Write-Host "Task completed successfully!"
```

## Step 4: Test Job Submission

```bash
# Submit test job
deadline bundle submit job_bundles/aftereffects_docker_render \
  -p ProjectFile=test_project.aep \
  -p RenderQueueIndex=1 \
  -p OutputDir=./output \
  -p Frames="1-10" \
  -p ChunkSize=5 \
  -p ECR_REGISTRY=484745417699.dkr.ecr.us-west-2.amazonaws.com
```

## Complete Workflow Summary

```
Phase 1: S3 Installers + Dockerfile → Docker Build → ECR Image
Phase 2: ECR Image + AE Project → Docker Run → Rendered Frames
```

## Data Flow

1. **Job Submission**: Project files uploaded to S3 via Job Attachments
2. **Worker Assignment**: Windows workers with Docker selected
3. **File Download**: Project and scripts downloaded to worker session directory
4. **Container Execution**: Docker runs with bind mounts:
   - `{{Session.WorkingDirectory}}` → `C:\workspace` (project files)
   - `{{Param.OutputDir}}` → `C:\output` (rendered frames)
5. **Rendering**: After Effects renders frames inside container
6. **Output**: Rendered frames uploaded to S3 via Job Attachments

## Key Benefits

- **Fast startup**: No runtime software installation (30 seconds vs 15-20 minutes)
- **Consistent environment**: Same software versions every time
- **Parallel execution**: Multiple frame chunks render simultaneously
- **No file copying**: Bind mounts provide direct access to files
- **Scalable**: Handles large frame ranges efficiently

## Troubleshooting

- **Build fails**: Check AWS credentials and S3 bucket access
- **Installer not found**: Verify file names in S3 match script variables
- **Permission denied**: Ensure Docker Desktop is running with Windows containers enabled
- **Container not found**: Verify ECR registry URI in template
- **Render fails**: Check After Effects project compatibility and render queue settings