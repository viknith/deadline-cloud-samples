FROM mcr.microsoft.com/windows/servercore:ltsc2022
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

COPY archive_files/ C:/installers/
COPY docker-install-software.ps1 C:/
RUN C:/docker-install-software.ps1

WORKDIR C:/workspace