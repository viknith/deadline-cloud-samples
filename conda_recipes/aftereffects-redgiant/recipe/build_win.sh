#!/bin/sh
set -xeuo pipefail

# Version without update number
RG_VERSION=${PKG_VERSION}

# Set up RGU plug-ins within After Effects installation
AE_PLUGINS_DIRECTORY="$AE_LOCATION/Plug-ins"
mkdir -p $AE_PLUGINS_DIRECTORY
cp -r "$SRC_DIR/redgiant/RGU Plug-ins" $AE_PLUGINS_DIRECTORY
RGU_PLUGINS_DIRECTORY="$AE_PLUGINS_DIRECTORY/RGU Plug-ins"

# Set up RGU in Program Files (needs Admin permission)
RG_SERVICE_PATH="C:\Program Files\Red Giant"
cp -r "$SRC_DIR/redgiant/Red Giant" "C:\Program Files"

# Set up RLM folder to support licensing proxy
MAXON_FOLDER_PATH="C:\ProgramData\Maxon\RLM"
mkdir -p "$MAXON_FOLDER_PATH"

# See https://docs.conda.io/projects/conda/en/latest/dev-guide/deep-dives/activation.html
# for details on activation. The Deadline Cloud sample queue environments use bash
# to activate environments on Windows, so we recommend always producing both .bat and .sh files.
mkdir -p "$PREFIX/etc/conda/activate.d"
mkdir -p "$PREFIX/etc/conda/deactivate.d"

# TODO: Fix the timeout thing to use some kind of for loop to verify the PID is defined.
cat <<EOF > "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.bat"
set "RG_VERSION=$RG_VERSION"

:: Setting GPU preference max performance setting
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" /v "$AE_LOCATION\aerender.exe" /t REG_SZ /d "GpuPreference=2" /f

:: Starting licensing proxy service, this will most likely need to be managed via adaptor
start "" "$RG_SERVICE_PATH\Services\Red Giant Service.exe" --noservice
timeout /t 5 >nul

:: Capture PID of licensing proxy service to kill process when conda env is deactivated
for /f "tokens=2 delims=," %%a in ('tasklist /fi "imagename eq Red Giant Service.exe" /nh /fo csv') do set "RG_PID=%%a"
EOF
cat "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.bat"


cat <<EOF > "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.sh"
export "RG_VERSION=$RG_VERSION"

# Setting GPU preference max performance setting
MSYS_NO_PATHCONV=1 reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" /v "$AE_LOCATION\aerender.exe" /t REG_SZ /d "GpuPreference=2" /f

# Starting licensing proxy service, this will most likely need to be managed via adaptor
start "" "$RG_SERVICE_PATH\Services\Red Giant Service.exe" --noservice
sleep 5

# Capture PID of licensing proxy service to kill process when conda env is deactivated
export "RG_PID=\$(ps -W | grep "Red Giant Service" | grep -v grep | awk '{print \$4}')"
EOF
cat "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.sh"


cat <<EOF > "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.bat"
:: Remove reg key and kill licensing proxy process and child processes
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" /v "$AE_LOCATION\aerender.exe" /f
taskkill /F /T /PID %RG_PID%

set RG_VERSION=
set RG_PID=
EOF
cat "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.bat"


cat <<EOF > "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.sh"
# Remove reg key and kill licensing proxy process and child processes
MSYS_NO_PATHCONV=1 reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" /v "$AE_LOCATION\aerender.exe" /f
pkill -9 -P \$RG_PID
kill -9 \$RG_PID

unset RG_VERSION
unset RG_PID
EOF
cat "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.sh"