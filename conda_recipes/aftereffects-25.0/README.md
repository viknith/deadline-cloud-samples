# Adobe After Effects 25 conda build recipe

## Creating an archive file for Windows

The Windows installer requires Administrator permissions that are not available in most conda package
build environments, such as on a Deadline Cloud service-managed fleets. Follow these instructions to
install Adobe After Effects 25 on a freshly created EC2 instance as Administrator, and create an archive file for use by the conda build recipe. If you have a Windows workstation, you can also do step 3 and 5 without starting an EC2 instance.

1. Launch a fresh Windows Server 2022 instance.
   1. From the AWS EC2 management console, select the option to Launch instance.
   2. Enter instance name "Create Windows AE archive".
   3. Select "Microsoft Windows Server 2022 Base" for the AMI.
   4. Select an instance type with enough vCPUs and RAM, for example c5.4xlarge has 8 vCPUs and 16 GiB RAM.
   5. Select "Proceed without a key pair" for the "Key pair (login)" option.
   6. Make sure that "Allow RDP traffic" is unchecked. We will use SSM port forwarding to avoid sending RDP
      protocol traffic directly over the internet.
   7. Set the storage to at least 64 GiB. Adjust other settings as you like, e.g. if you want an encrypted volume of type gp3.
   8. Select "Launch instance."
   9. If it asks, select "Proceed without key pair" and proceed with the launch.
   10. Once it launched, navigate to the instance detail page. Select "Connect," and with "Session manager" selected, again select "Connect."
       If it says "SSM Agent is not online," you may have to wait a few minutes for it to initialize.
   11. Create a secure password for the Administrator account. From the Administrator powershell window that session manager,
       enter the following command with your secure password substituted to change the password.
       1. `net user Administrator MY_SECURE_PASSWORD`
2. Connect to the instance with SSM port forwarding and RDP.
   1. Install or update the AWS CLI v2 from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html.
   2. Install or update the Session Manager plugin from https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html.
   3. Run the following command, using AWS credentials that have suitable permissions, to start the SSM port forwarding. Replace INSTANCE_ID with the one you launched.
      1. `aws ssm start-session --document-name AWS-StartPortForwardingSession --parameters "localPortNumber=33389,portNumber=3389" --target INSTANCE_ID`
   4. Open RDP, and enter the following connection details:
      1. Computer: `localhost:33389`
      2. User name: `Administrator`
   5. Enter the password you set for Administrator after you created the instance. You should now have a remote desktop session to your instance.
3. Install Adobe After Effects 25 on the instance.
   1. Download Adobe Creative Cloud after logging into your Adobe account.
   2. Download Adobe After Effects 25 from Creative Cloud App.
   3. The After Effects installer will launch. Proceed to install as normal with the components you want included.
   4. Log in with a powershell window again, either from the EC2 management console session manager or reconnecting to RDP.
   5. Run the following commands to create the archive.
      1. `Compress-Archive -Path 'C:\Program Files\Adobe\Adobe After Effects 2025\Support Files' -DestinationPath Adobe_AfterEffects_25_0_Windows_installation.zip`
      2. `(Get-FileHash -Path "Adobe_AfterEffects_25_0_Windows_installation.zip" -Algorithm SHA256).Hash.ToLower()`
   6. Record the file sha256 hash, and upload the archive to your private S3 bucket. You can use a PowerShell command like
      `Write-S3Object -BucketName MY_BUCKET_NAME -Key Adobe_AfterEffects_25_0_Windows_installation.zip -File Adobe_AfterEffects_25_0_Windows_installation.zip`.
4. From the AWS EC2 management console, select the instance you used and terminate it.
5. Download the zip file to the `conda_recipes/archive_files` directory in your git clone of the [deadline-cloud-samples](https://github.com/aws-deadline/deadline-cloud-samples) repository for submitting package build jobs, and update the Windows source artifact hash in the aftereffects-25 conda build recipe meta.yaml.
