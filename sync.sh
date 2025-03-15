if [ -z "$1" ]; then
    echo "Usage: $0 <host>"
    exit 1
fi

# https://gist.github.com/Venemo/a9483106565df3a83fc67a411191edbd

RHOST=$1
RSYNC="rsync -rv --exclude .git --exclude venv --exclude __pycache__ --links"
DEVUSER=${DEVUSER:-bazzite}

# If RHOST=claw, set driver name to intel
if [ "$RHOST" = "claw" ]; then
    echo "Using Intel driver"
    DRIVER_NAME=intel
    VKICD_NAME=intel
    GALLIUM_DRIVER=iris
else
    echo "Using AMD driver"
    DRIVER_NAME=amd
    VKICD_NAME=radeon
    GALLIUM_DRIVER=radeonsi
fi

set -e -x

sudo podman build . --tag mesa_builder \
    --build-arg UID=$(id -u) --build-arg GID=$(id -g)

PODMAN_RUN="sudo podman run --rm -v $(pwd):/workspace \
  --env CCACHE_DIR=/workspace/.cache \
  --env CCACHE_MAXSIZE=5G \
  --env CCACHE_COMPRESS=1 \
    -it mesa_builder"

$PODMAN_RUN rm -rf build64 build32

$PODMAN_RUN meson setup build64 --libdir lib64 --prefix /workspace/.out \
    -Dgallium-drivers=swrast,zink,$GALLIUM_DRIVER -Dvulkan-drivers=$DRIVER_NAME \
    -Dgallium-nine=true -Dbuildtype=release \
    -Dvideo-codecs=h264dec,h264enc,h265dec,h265enc,vc1dec

# Cross-file for arch: lib32, fedora: ./gcc-i686
$PODMAN_RUN meson setup build32 --libdir lib --prefix /workspace/.out \
    -Dgallium-drivers=swrast,zink,$GALLIUM_DRIVER -Dvulkan-drivers=$DRIVER_NAME \
    -Dgallium-nine=true -Dbuildtype=release \
    -Dvideo-codecs=h264dec,h264enc,h265dec,h265enc,vc1dec

time $PODMAN_RUN ninja -C build64 install

time $PODMAN_RUN ninja -C build32 install

RUNCONFIG=$(cat << EOF


MESA=/home/$DEVUSER/.out

export LD_LIBRARY_PATH=\$MESA/lib64:\$MESA/lib:\$LD_LIBRARY_PATH
export LIBGL_DRIVERS_PATH=\$MESA/lib64/dri:\$MESA/lib/dri
export EGL_DRIVERS_PATH=\$MESA/lib64/dri:\$MESA/lib/dri
export VK_ICD_FILENAMES=\$MESA/share/vulkan/icd.d/${VKICD_NAME}_icd.x86_64.json:\$MESA/share/vulkan/icd.d/${VKICD_NAME}_icd.i686.json
export LIBVA_DRIVERS_PATH=\$MESA/lib64/dri:\$MESA/lib/dri
export VDPAU_DRIVER_PATH=\$MESA/lib64/vdpau
export D3D_MODULE_PATH=\$MESA/lib64/d3d/d3dadapter9.so.1:\$MESA/lib/d3d/d3dadapter9.so.1
# export ENABLE_GAMESCOPE_WSI=0

EOF
)

ssh $RHOST /bin/bash << EOF
    rm -rf .out
    mkdir -p .out
EOF

echo "$RUNCONFIG" > .out/runconfig

# Fixup vunkan_icd install dir
sed -i "s|/workspace/.out|/home/$DEVUSER/.out|g" .out/share/vulkan/icd.d/*.json

$RSYNC .out/ $RHOST:.out/

ssh $RHOST /bin/bash << EOF
    sudo rpm-ostree usroverlay --hotfix

    # check if session does not have D3D_MODULE_PATH
    if ! grep -q D3D_MODULE_PATH /usr/share/gamescope-session-plus/device-quirks; then
        cat ~/.out/runconfig | sudo tee -a /usr/share/gamescope-session-plus/device-quirks
    fi

    # sudo rsync -r -v ~/.out/* /usr/
    
    bazzite-session-select gamescope
    # sudo reboot
EOF
