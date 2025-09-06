# After Effects Docker Container - Phase 1: Build Docker Image

This guide covers building a Windows Docker container with Adobe After Effects, Red Giant, and Universe pre-installed for use with AWS Deadline Cloud.

## Phase 1 Overview

```
INPUT                    PROCESS                     OUTPUT
┌─────────────────┐     ┌─────────────────┐        ┌─────────────────┐
│ Local Files     │     │ Docker Build    │        │ ECR Repository  │
│ ├── AE.zip      │────►│ ├── Copy Files  │───────►│ ├── ae-redgiant-│
│ ├── RG.exe      │     │ ├── Install     │        │ │   full:latest │
│ ├── Universe    │     │ ├── Configure   │        │ └── ~27GB image │
│ └── Maxon.exe   │     │ └── ~60 min     │        │     ready       │
└─────────────────┘     └─────────────────┘        └─────────────────┘

Local Files              Build Machine               Cloud Storage
┌─────────────────┐     ┌─────────────────┐        ┌─────────────────┐
│ ├── Dockerfile  │────►│ ./build.sh      │───────►│ docker push     │
│ ├── docker-     │     │ (automated)     │        │ to ECR          │
│ │   install.ps1 │     │                 │        │                 │
│ └── archive_files/│    └─────────────────┘        └─────────────────┘
└─────────────────┘
```

## Prerequisites

- Docker Desktop with Windows containers enabled
- AWS CLI configured with ECR permissions
- Required installer files downloaded to `archive_files/` directory

## Project Structure

```
aftereffects/
├── Dockerfile
├── docker-install-software.ps1
├── build.sh
├── test-container.ps1
├── archive_files/
│   ├── After Effects_en_US_WIN_64.zip
│   ├── RedGiant-2025.6.0-Win.exe
│   ├── Universe-2025.3.3_Win.exe
│   ├── Maxon_App_2025.4.2_Win.exe
│   └── MicrosoftEdgeWebView2RuntimeInstallerX64.exe
└── README.md
```

## Step 1: Download Required Installer Files

Download the following files and place them in the `archive_files/` directory:

- **After Effects_en_US_WIN_64.zip** - Adobe After Effects 2025 installer
- **RedGiant-2025.6.0-Win.exe** - Red Giant plugins installer  
- **Universe-2025.3.3_Win.exe** - Universe plugins installer
- **Maxon_App_2025.4.2_Win.exe** - Maxon App installer
- **MicrosoftEdgeWebView2RuntimeInstallerX64.exe** - WebView2 Runtime

Verify all files are present before proceeding to the build step.

## Step 2: Dockerfile Configuration

```dockerfile
FROM mcr.microsoft.com/windows/server:ltsc2022
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

COPY archive_files/ C:/installers/
COPY docker-install-software.ps1 C:/
RUN C:/docker-install-software.ps1

WORKDIR C:/workspace
```

> **Important**: Uses full `windows/server:ltsc2022` base image (not servercore) because Adobe After Effects requires complete Windows environment. ServerCore is missing essential components needed for Adobe software installation.

## Step 3: Automated Build Process

Run the automated build script:

```bash
./build.sh
```

This script will:
1. Create ECR repository `ae-redgiant-full`
2. Build Docker image (~60 minutes)
3. Login to ECR automatically
4. Tag and push image (~27GB)
5. Verify deployment

> **Note**: Build time is approximately 60 minutes due to sequential installation of all Adobe software and plugins. Final image size is ~27GB.

## Manual Build (Alternative)

If you prefer manual control:

```bash
# Create ECR repository
aws ecr create-repository --repository-name ae-redgiant-full --region us-west-2

# Build Docker image
docker build -t ae-redgiant-windows .

# ECR login
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 484745417699.dkr.ecr.us-west-2.amazonaws.com

# Tag and push
docker tag ae-redgiant-windows:latest 484745417699.dkr.ecr.us-west-2.amazonaws.com/ae-redgiant-full:latest
docker push 484745417699.dkr.ecr.us-west-2.amazonaws.com/ae-redgiant-full:latest
```

## Step 4: Test Container

Verify your container works:

```bash
./test-container.ps1
```

This will test all software installations and run a sample After Effects render.

## Step 5: Verify Image

```bash
aws ecr describe-images --repository-name ae-redgiant-full --region us-west-2
```

## Result

You now have a Docker image in ECR with:
- Adobe After Effects 2025
- Red Giant plugins  
- Universe plugins
- Maxon App
- All necessary environment variables configured
- Full Windows Server environment for Adobe compatibility

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
│ ae-redgiant-    │────►│ docker run      │───────►│ Job Attachments │
│ full:latest     │     │ --rm -v mounts  │        │ Upload          │
│ (pre-installed) │     │ call_aerender   │        │                 │
└─────────────────┘     └─────────────────┘        └─────────────────┘
```

The job template is located at:
`job_bundles/aftereffects_docker_render/`

## Usage

```bash
deadline bundle submit job_bundles/aftereffects_docker_render \
  -p ProjectFile=my_project.aep \
  -p RenderQueueIndex=1 \
  -p OutputDir=./output \
  -p Frames="1-100" \
  -p ChunkSize=10 \
  -p ECR_REGISTRY=484745417699.dkr.ecr.us-west-2.amazonaws.com
```

The job template automatically:
- Authenticates with ECR
- Pulls the Docker image
- Mounts project files and output directories
- Executes After Effects renders in containers
- Uploads results via Job Attachments