#!/bin/bash

# Indicate path for formating, you can use --recursive. The use of --check is
# for verifying without modification

CHECKONLY=false
RECURSIVE=false
PYTHON=false
CPP=false

if [ $# -lt 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Initialiser le tableau vide
path=()

for var in "$@"
do
    case "$var" in
        "--check") CHECKONLY=true ;;
        "--recursive") RECURSIVE=true ;;
        "--python") PYTHON=true ;;
        "--cpp") CPP=true ;;
        *) path+=($var);;
    esac
done

# Afficher tous les éléments du tableau
path_concat=""
for element in "${path[@]}"; do
  path_concat="$path_concat / $element"
done

echo "Will format path: $path_concat with CHECKONLY=$CHECKONLY and RECURSIVE=$RECURSIVE"

RESULT=OK

function check_result {
    if [ "$1" == 0 ]; then
        return
    fi

    if [ -n "$1" ] || [ "$1" -ne 0 ]; then
        RESULT=KO
    fi
}

if [ "$PYTHON" = "true" ]; then
    if [ "$CHECKONLY" = "true" ]; then
        black -l 99 --check test/*.py
        check_result $?
        black -l 99 --check tools/*.py
        check_result $?
    else
        black -l 99 test/*.py
        black -l 99 tools/*.py
    fi
fi

if [ "$CPP" = "true" ]; then

    clang-format --version

    # Commented lines are OK in local, but no TTY in runner so clang-format is executed 2 times: one for
    # debug console and one for validation
    if [ "$RECURSIVE" = "true" ]; then
        if [ "$CHECKONLY" = "true" ]; then
            for element in "${path[@]}"; do
                # res=$(
                #     find "$path" -type f \( -name "*.hpp" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
                #     -exec clang-format --dry-run --color=1 --Werror {} \; 2>&1 \
                #     | tee /dev/tty
                # )
                res=$(find "$path" -type f \( -name "*.hpp" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
                    -exec clang-format --dry-run --color=1 --Werror {} \; 2>&1)
                find "$path" -type f \( -name "*.hpp" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
                    -exec clang-format --dry-run --color=1 --Werror {} \;
                check_result "$res"
            done
        else
            for element in "${path[@]}"; do
                res=$(find "$path" -type f \( -name "*.hpp" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
                -exec clang-format --color=1 -i {} \; 2>&1)
                find "$path" -type f \( -name "*.hpp" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
                -exec clang-format --color=1 -i {} \;
                check_result "$res"
            done
        fi
    else
        if [ "$CHECKONLY" = "true" ]; then
            for element in "${path[@]}"; do
                res=$(find $path -maxdepth 1 -type f \( -name "*.hpp" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
                -exec clang-format --color=1 --dry-run --Werror {} \; 2>&1)
                find $path -maxdepth 1 -type f \( -name "*.hpp" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
                -exec clang-format --color=1 --dry-run --Werror {} \;
                check_result $res
            done
        else
            for element in "${path[@]}"; do
                res=$(find $path -maxdepth 1 -type f \( -name "*.hpp" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" \) \
                -exec clang-format --color=1 -i {} \; 2>&1)
                check_result $res
            done
        fi
    fi
fi

if [ "$RESULT" = "KO" ]; then
    echo "Formatting is not correct"
    exit 1
else
    echo "Formatting is correct"
    exit 0
fi
