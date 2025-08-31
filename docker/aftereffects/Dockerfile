FROM mcr.microsoft.com/windows/servercore:ltsc2022
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

COPY install-software.ps1 C:/
RUN C:/install-software.ps1

WORKDIR C:/workspace