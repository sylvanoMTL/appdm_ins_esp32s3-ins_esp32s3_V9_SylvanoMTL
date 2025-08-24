import os
import sys


class bcolors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


manifest_path = sys.argv[1]
project_name = sys.argv[2]
branch_name = sys.argv[3]

# manifest_path = os.path.join(os.path.dirname(__file__), "../.repo/manifests/lib.xml")
# project_name = "libdm_timer_tool"
# branch_name = "test_ci_multi_project"

print(
    f"{bcolors.HEADER}Hello, substituting revision in manifest : ",
    manifest_path + bcolors.ENDC,
)
print(
    f"{bcolors.HEADER}Getting project name = ",
    project_name,
    ", branch_name = ",
    branch_name + bcolors.ENDC,
)

# Read in the file
success = False
with open(manifest_path, "r") as file:
    lines = file.readlines()
    for line in lines:
        if project_name in line:
            print(
                f"{bcolors.OKCYAN}Line found in manifest, lets substitute!!"
                + bcolors.ENDC
            )
            # Find path= to place our revision just before:
            cur_index = line.index("path=")
            newline = (
                line[:cur_index] + 'revision="' + branch_name + '" ' + line[cur_index:]
            )
            print(f"{bcolors.OKCYAN}Getting new line : ", newline + bcolors.ENDC)
            lines[lines.index(line)] = newline
            success = True
            break

if success:
    # Write everything back
    with open(manifest_path, "w") as file:
        file.writelines(lines)
    print(
        f"{bcolors.OKGREEN}Success, project ",
        project_name,
        " has been found, manifest has been updated, revision = ",
        branch_name,
        "time for repo sync" + bcolors.ENDC,
    )
else:
    print(
        f"{bcolors.FAIL}Error, project has not been found, manifest left unchanged"
        + bcolors.ENDC
    )
