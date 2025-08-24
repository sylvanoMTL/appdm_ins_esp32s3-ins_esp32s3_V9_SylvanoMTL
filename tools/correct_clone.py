# Platformio is not cloning correctly complex libraries, so we do it manually

import os
from pathlib import Path
import sys

Import("env")
# print(env.Dump())
# print(os.listdir(env["PROJECT_LIBDEPS_DIR"] + "/teensy41" + "/cmsis_5"))

target = sys.argv[1]
clone_path = sys.argv[2]
dest_directory_name = sys.argv[3]

path = env["PROJECT_LIBDEPS_DIR"] + "/" + target + "/" + dest_directory_name
command = "git clone " + clone_path + " " + path

os.system(command)

def list_dir(rootDir):
    list_dirs = os.walk(rootDir)
    for root, dirs, files in list_dirs:
        for d in dirs:
            print(os.path.join(root, d))
        for f in files:
            print(os.path.join(root, f))

# list_dir(path)
