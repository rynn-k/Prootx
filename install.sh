#!/data/data/com.termux/files/usr/bin/bash

set -e

DIM="\e[2m"
RST="\e[0m"
P="  "

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"

clear
echo
echo -e "${P}Select an action:"
echo -e "${P}  ${DIM}1)${RST} Install"
echo -e "${P}  ${DIM}2)${RST} Uninstall"
echo
echo -ne "${P}${DIM}>${RST} "
read ACTION

if [ "$ACTION" = "2" ]; then
    mapfile -t INSTALLED < <(proot-distro list --quiet 2>/dev/null)

    if [ "${#INSTALLED[@]}" -eq 0 ]; then
        echo -e "${P}[!] No installed distros found."
        exit 1
    fi

    clear
    echo
    echo -e "${P}Select a distro to uninstall:"
    for i in "${!INSTALLED[@]}"; do
        echo -e "${P}  ${DIM}$((i+1)))${RST} ${INSTALLED[$i]}"
    done
    echo
    echo -ne "${P}${DIM}>${RST} "
    read NUM
    INDEX=$((NUM-1))

    if [ -z "${INSTALLED[$INDEX]}" ]; then
        echo -e "${P}[!] Invalid selection."
        exit 1
    fi

    TARGET="${INSTALLED[$INDEX]}"

    clear
    echo
    echo -e "${P}[*] Removing $TARGET..."
    proot-distro remove "$TARGET" --quiet

    ROOTFS_LINK="$PREFIX/var/lib/proot-distro/containers/$TARGET"
    if [ -L "$ROOTFS_LINK" ]; then
        ROOTFS_REAL=$(readlink -f "$ROOTFS_LINK")
        rm -f "$ROOTFS_LINK"
        rm -rf "$ROOTFS_REAL"
    elif [ -d "$HOME/${TARGET}-rootfs" ]; then
        rm -rf "$HOME/${TARGET}-rootfs"
    fi

    for bin in "$PREFIX/bin/"*; do
        if grep -q "proot-distro login \"$TARGET\"" "$bin" 2>/dev/null; then
            rm -f "$bin"
        fi
    done

    clear
    echo
    echo -e "${P}[*] Done."
    echo -e "${P}Removed  ${DIM}${TARGET}${RST}"
    echo
    exit 0
fi

clear
echo
echo -e "${P}[*] Installing dependencies..."
echo
pkg update -y
pkg upgrade -y
pkg install -y proot-distro

clear
echo
echo -ne "${P}Distro (e.g. ubuntu:24.04) > "
read IMAGE

if [ -z "$IMAGE" ]; then
    echo -e "${P}[!] No distro specified."
    exit 1
fi

DEFAULT_NAME="${IMAGE##*/}"
DEFAULT_NAME="${DEFAULT_NAME%%:*}"

echo -ne "${P}Alias ${DIM}[${DEFAULT_NAME}]${RST} > "
read ALIAS_NAME
ALIAS_NAME="${ALIAS_NAME:-$DEFAULT_NAME}"

INSTALL_NAME="$ALIAS_NAME"

clear
echo
echo -e "${P}[*] Installing $IMAGE as '$INSTALL_NAME'..."
proot-distro install "$IMAGE" -n "$INSTALL_NAME" --quiet

ROOTFS_DEFAULT="$PREFIX/var/lib/proot-distro/containers/$INSTALL_NAME"
ROOTFS_TARGET="$HOME/${INSTALL_NAME}-rootfs"

if [ -d "$ROOTFS_DEFAULT" ] && [ ! -L "$ROOTFS_DEFAULT" ]; then
    mv "$ROOTFS_DEFAULT" "$ROOTFS_TARGET"
    ln -s "$ROOTFS_TARGET" "$ROOTFS_DEFAULT"
fi

LAUNCHER="$PREFIX/bin/$ALIAS_NAME"
echo "#!$PREFIX/bin/bash" > "$LAUNCHER"
echo "proot-distro login \"$INSTALL_NAME\" \"\$@\"" >> "$LAUNCHER"
chmod a+x "$LAUNCHER"

clear
echo
echo -e "${P}[*] Done."
echo -e "${P}Rootfs   ${DIM}~/${INSTALL_NAME}-rootfs${RST}"
echo -e "${P}Login    ${DIM}${ALIAS_NAME}${RST}"
echo
echo -ne "${P}Login now? ${DIM}[Y/n]${RST} > "
read RESP
RESP="${RESP:-Y}"

if [[ "$RESP" =~ ^[Yy]$ ]]; then
    exec "$LAUNCHER"
fi
