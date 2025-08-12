# Red Giant for After Effects conda build recipe

## Creating an archive file for Windows

The Windows installer requires Administrator permissions that are not available in most conda package build environments, such as on a Deadline Cloud service-managed fleets. Follow these instructions to install Adobe After Effects 25 on a freshly created EC2 instance as Administrator, then install Red Giant, and then create an archive file from the Red Giant files for After Effects to use with a conda build recipe. If you have a Windows workstation, you can also do step 3 and 5 without starting an EC2 instance.

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
4. Install Red Giant and Universe and package their plugin files
   1. Log into Maxon and download the Maxon One application to manage the installation of Red Giant and Universe.
   2. Then log into the Maxon One application and download Red Giant and Universe.
5. Package the Red Giant + Universe plugin assets
   1. First, make a directory under your Downloads folder called `Red Giant Universe`.
   2. Then move all of the Red Giant plugin folders located under `C:\Program Files\Adobe\Common\Plug-ins\7.0\MediaCore` to a subfolder called `RGU Plug-ins` located at `Downloads\Red Giant Universe\RGU Plug-ins`.
6. Then grab the Red Giant folder under Program Files, move it under the `Downloads\Red Giant Universe\Red Giant`.
7. Follow similar instructions as the After Effects Conda recipe to get a zip file set up from the Red Giant Universe folder so that you get the hash and push up the zip asset to your S3 bucket.
8. From the AWS EC2 management console, select the instance you used and terminate it.
9. Download the zip file to the `conda_recipes/archive_files` directory in your git clone of the [deadline-cloud-samples](https://github.com/aws-deadline/deadline-cloud-samples) repository for submitting package build jobs, and update the Windows source artifact hash in the Red Giant conda build recipe meta.yaml.
