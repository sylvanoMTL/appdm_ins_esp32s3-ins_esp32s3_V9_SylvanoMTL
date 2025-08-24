COLOR_REST="$(tput sgr0)"
COLOR_RED="$(tput setaf 1)"
COLOR_GREEN="$(tput setaf 2)"
COLOR_ORANGE="$(tput setaf 3)"
BOLD=$(tput bold)

# Create an isolated python environment with platformio installed is vscode extension is not installed
if [ ! -d "~/.platformio/penv" ]; then
    if [ ! -d "pioenv" ]; then
        printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE 'Creating isolated python environment in pioenv folder' $COLOR_REST
        mkdir pioenv
        python3 -m venv pioenv
    else
        printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE 'Isolated python environment already exists in pioenv folder' $COLOR_REST
    fi
    source pioenv/bin/activate
    pip install -U platformio
    pio project init -b lolin_s3
    pio pkg install -p espressif32
fi

# locate esp
usb_module=$(ls /dev | grep cu.usbmodem | head -n 1)
if [ -n "$usb_module" ]; then
    printf '%s%s%s%s%s\n' $BOLD $COLOR_GREEN 'Located usb device: '$usb_module'' $COLOR_REST
    # flash esp
    python3 ~/.platformio/packages/tool-esptoolpy/esptool.py --chip esp32s3 --port "/dev/$usb_module" --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 16MB 0x0000 bootloader.bin 0x8000 partitions.bin 0xe000 boot_app0.bin 0x10000 firmware.bin
else
    printf '%s%s%s%s%s\n' $BOLD $COLOR_RED 'Can not locate usb device' $COLOR_REST
fi

deactivate