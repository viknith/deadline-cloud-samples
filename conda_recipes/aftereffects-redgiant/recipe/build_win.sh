#!/bin/sh
set -xeuo pipefail

# Version without update number
RG_VERSION=${PKG_VERSION}

# Set up RGU plug-ins within After Effects installation
AE_PLUGINS_DIRECTORY="$AE_LOCATION/Plug-ins"
mkdir -p $AE_PLUGINS_DIRECTORY
cp -r "$SRC_DIR/redgiant/Plug-ins"/* $AE_PLUGINS_DIRECTORY

# Set up RGU service path to source location
RG_SERVICE_PATH="$SRC_DIR/redgiant/Red Giant Service.exe"

# See https://docs.conda.io/projects/conda/en/latest/dev-guide/deep-dives/activation.html
# for details on activation. The Deadline Cloud sample queue environments use bash
# to activate environments on Windows, so we recommend always producing both .bat and .sh files.
mkdir -p "$PREFIX/etc/conda/activate.d"
mkdir -p "$PREFIX/etc/conda/deactivate.d"

# TODO: Fix the timeout thing to use some kind of for loop to verify the PID is defined.
cat <<EOF > "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.bat"
set "RG_VERSION=$RG_VERSION"
set "RG_SERVICE_PATH=$RG_SERVICE_PATH"

:: Starting licensing proxy service as a background process with render-only variable set
start "" /env MAXON_RENDERONLY=true "%RG_SERVICE_PATH%" --noservice
timeout /t 5 >nul
EOF
cat "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.bat"


cat <<EOF > "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.sh"
export "RG_VERSION=$RG_VERSION"
export "RG_SERVICE_PATH=$RG_SERVICE_PATH"

# Starting licensing proxy service as a background process with render-only variable set
start "" /env MAXON_RENDERONLY=true "\$RG_SERVICE_PATH" --noservice
EOF
cat "$PREFIX/etc/conda/activate.d/$PKG_NAME-$PKG_VERSION-vars.sh"


cat <<EOF > "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.bat"
set RG_VERSION=
set RG_SERVICE_PATH=
EOF
cat "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.bat"


cat <<EOF > "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.sh"
unset RG_VERSION
unset RG_SERVICE_PATH
EOF
cat "$PREFIX/etc/conda/deactivate.d/$PKG_NAME-$PKG_VERSION-vars.sh"