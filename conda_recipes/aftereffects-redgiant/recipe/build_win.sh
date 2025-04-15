#!/bin/sh
set -xeuo pipefail

AE_PLUGINS_DIRECTORY="$AE_LOCATION/Plug-ins"

mkdir -p $AE_PLUGINS_DIRECTORY
cp -r $SRC_DIR/redgiant $AE_PLUGINS_DIRECTORY

# Version without update number
RG_VERSION=${PKG_VERSION}
RG_SERVICE_PATH="$AE_PLUGINS_DIRECTORY/redgiant/Red Giant Service.exe"
MAXON_FOLDER_PATH="C:\ProgramData\Maxon\RLM"

mkdir -p "$MAXON_FOLDER_PATH"

# See https://docs.conda.io/projects/conda/en/latest/dev-guide/deep-dives/activation.html
# for details on activation. The Deadline Cloud sample queue environments use bash
# to activate environments on Windows, so we recommend always producing both .bat and .sh files.
mkdir -p "$PREFIX/etc/conda/activate.d"
mkdir -p "$PREFIX/etc/conda/deactivate.d"


# TODO: Fix the timeout thing to use some kind of for loop to verify the PID is defined.
cat <<EOF > "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.bat"
start "" cmd /k "echo Redshift License: %redshift_LICENSE% && "$RG_SERVICE_PATH" --noservice"
timeout /t 5 >nul
for /f "tokens=2 delims=," %%a in ('tasklist /fi "imagename eq Red Giant Service.exe" /nh /fo csv') do set "RG_PID=%%a"
set "RG_VERSION=$RG_VERSION"
EOF
cat "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.bat"


cat <<EOF > "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.sh"
start "" cmd /k "echo Redshift License: %redshift_LICENSE% && "$RG_SERVICE_PATH" --noservice"
sleep 5
export "RG_PID=\$(ps -W | grep "Red Giant Service" | grep -v grep | awk '{print \$4}')"
export "RG_VERSION=$RG_VERSION"
EOF
cat "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.sh"


cat <<EOF > "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.bat"
taskkill /F /T /PID %RG_PID%
set RG_VERSION=
set RG_PID=
EOF
cat "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.bat"


cat <<EOF > "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.sh"
pkill -9 -P \$RG_PID
kill -9 \$RG_PID
unset RG_VERSION
unset RG_PID
EOF
cat "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.sh"