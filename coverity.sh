#!/bin/bash

# has to be used in pioenv if platformio has been installed through vscode.
# To do so:
# - From vscode, use left PIO alien icon, pio_quick_access/miscellaneous/new terminal
# - From any terminal:
#       source ~/.platformio/penv/bin/activate
# if .platformio is located here of course

# Then execute ./coverity.sh
rm -rf .pio
cp conf/conf.ini platformio.ini
pio check -e coverity --fail-on-defect=medium --fail-on-defect=high --skip-packages \
    --src-filters="-<*>" --src-filters="+<src>" #--flags "--std=c++17"
RESULT=$?
rm platformio.ini
rm -rf .pio

exit $RESULT
