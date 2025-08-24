#!/bin/bash

# Call with ./generate_doc.sh do_install_packages
# do_install_packages: true or false, need to be done only one time per machine

# Install necessary documentation tools (doxygen, sphinx)
# Clone general documentation repo
# Generate documentation for specific project

echo "Hello terminal is $TERM"
if [ -z "$TERM" ] ||  [ "$TERM" == "dumb" ]; then
    export TERM=xterm
fi

COLOR_REST="$(tput sgr0)"
COLOR_RED="$(tput setaf 2)"
COLOR_GREEN="$(tput setaf 2)"
COLOR_ORANGE="$(tput setaf 3)"
BOLD=$(tput bold)

#options:
generate_doc_proto=false

if [ "${PWD##*/}" == "libdm_protobuf" ] || [ "${PWD##*/}" == "libDM_protobuf" ]; then
    generate_doc_proto=true
    printf '%s%s%s%s%s\n' $BOLD $COLOR_GREEN 'Will generate proto documentation!' $COLOR_REST
fi

echo "Hello ${PWD##*/}"

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac
printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Detected machine is a ${machine}" $COLOR_REST

if [ "$2" = "ci" ]; then
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE 'Installing necessary packages for gitlab CI' $COLOR_REST
    apt-get update
    # apt-get install -y doxygen doxygen-gui doxygen-doc
    # Install specific version of doxygen
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE 'Installing doxygen 1.9.8' $COLOR_REST
    wget --quiet https://www.doxygen.nl/files/doxygen-1.9.8.linux.bin.tar.gz
    tar xzf doxygen-1.9.8.linux.bin.tar.gz
    cd doxygen-1.9.8
    chmod +x INSTALL
    make install
    cd ../
    # apt-get install python3-sphinx
    pip install Sphinx
    # echo "Installing sphinx 6.2.1"
    # pip install Sphinx==6.2.1
    pip install breathe
    pip install furo
    # pip install piccolo-theme
    # pip install sphinx-rtd-theme
    # pip install sphinx-book-theme
    # pip install sphinx-nefertiti

    if [ "$generate_doc_proto" == "true" ]; then
        apt-get install -y protobuf-compiler
        protoc --version
    fi
elif [ "$1" = "true" ]; then
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE 'Installing necessary packages for user' $COLOR_REST

    # Install necessary documentation tools (doxygen, sphinx)
    if [ "$machine" == "Mac" ]; then
        brew install sphinx-doc
        brew link sphinx-doc --force
        brew install doxygen
        if [ "$generate_doc_proto" == "true" ]; then
            brew install protobuf
            protoc --version
        fi
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        # code for GNU/Linux platform
        sudo apt -y install doxygen doxygen-gui doxygen-doc
        sudo apt install python3-sphinx
        if [ "$generate_doc_proto" == "true" ]; then
            apt-get install -y protobuf-compiler
            protoc --version
        fi
    fi
    pip install breathe

    # pip install piccolo-theme
    # pip install sphinx-rtd-theme
    pip install furo
fi

#Initialize necessary files
if [ ! -d doc ]; then
    lib_name=${PWD##*/}

    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE 'No doc folder detected, creating one, and apply first configuration' $COLOR_REST
    mkdir doc
    mkdir doc/doc_repo
    cd doc
    # Cloning reference repo
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE 'Getting template files' $COLOR_REST
    if [ "$2" = "ci" ]; then
        git clone https://gitlab-ci-token:$runner_ci_token_main@git.weskrauser.duckdns.org/code/doc/libdm_doc_template libDM_doc_template
    else
        git clone ssh://git@git.weskrauser.duckdns.org:2224/code/doc/libdm_doc_template.git libDM_doc_template
    fi
    cd doc_repo
    # Sphinx need empty folder to initialize files
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE 'Generating Sphinx configuration' $COLOR_REST
    sphinx-quickstart --quiet --no-sep -p $lib_name -a Sysrox -v 0.0
    # Customize Sphinx configuration
    cp ../libDM_doc_template/configs_examples/conf.py conf.py
    sed -i '' 's/alabaster/furo/g' conf.py
    sed -i '' 's/libDM_dummy/'"$lib_name"'/g' conf.py
    cd ../

    mkdir doc_repo/_static
    mkdir doc_repo/_static/images
    mkdir doc_repo/images

    # Doxygen
    cp libDM_doc_template/configs_examples/Doxyfile doc_repo/Doxyfile
    cp -r libDM_doc_template/images/* doc_repo/_static/images/
    # Grab basic information about lib
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Library name is $lib_name" $COLOR_REST
    lib_description="$lib_name is a library called $lib_name (add description here)"
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Basic library description is $lib_description" $COLOR_REST
    sed -i '' 's/libDM_dummy/'"$lib_name"'/' doc_repo/Doxyfile
    sed -i '' 's/libDM_description_dummy/'"$lib_description"'/g' doc_repo/Doxyfile
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Generating Doxygen documentation" $COLOR_REST
    cd doc_repo
    doxygen Doxyfile
    rm -rf _static/doxyfiles
    cp -r doxyfiles/html _static/doxyfiles

    # Proto documentation
    if [ "$generate_doc_proto" == "true" ]; then
        printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Generating Proto documentation" $COLOR_REST
        printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Getting plugin for protoc" $COLOR_REST
        if [ "$machine" == "Mac" ]; then
            cp ../libDM_doc_template/tools/protoc-gen-doc-mac-arm protoc-gen-doc
            mkdir protofiles
            protoc --doc_out=html,/protofiles/protobuf.html:./protofiles --plugin=protoc-gen-doc \
                --experimental_allow_proto3_optional \
                --proto_path=../../src/message_definitions \
                ../../src/message_definitions/frame.proto ../../src/message_definitions/types.proto
            cp -r protofiles _static/protofiles
        elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
            cp ../libDM_doc_template/tools/protoc-gen-doc-linux-x86 protoc-gen-doc
            mkdir protofiles
            protoc --doc_out=html,/protofiles/protobuf.html:./protofiles --plugin=protoc-gen-doc \
                --experimental_allow_proto3_optional \
                --proto_path=../../src/message_definitions \
                ../../src/message_definitions/frame.proto ../../src/message_definitions/types.proto
            cp -r protofiles _static/protofiles
        else
            printf '%s%s%s%s%s\n' $BOLD $COLOR_RED "Can not find correct plugin for protobuf documentation" $COLOR_REST
        fi
    fi


    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Generating Sphinx documentation" $COLOR_REST
    make html

    printf '%s%s%s%s%s\n' $BOLD $COLOR_GREEN 'Full generation successful, links are:' $COLOR_REST
    doxy_path="${PWD}/doxyfiles/html/index.html"
    sphinx_path="${PWD}/_build/html/index.html"
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Doxygen documentation is available at:" $COLOR_REST
    echo "file://$doxy_path"
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Sphinx documentation is available at:" $COLOR_REST
    echo "file://$sphinx_path"

    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "If you want to update documentation, just rerun script without the true option" $COLOR_REST

    # Updating gitignore
    cd ../..
    echo "Updating gitignore"
    echo "doc/libDM_doc_template/" >> .gitignore
    echo "doc/doc_repo/_build/" >> .gitignore
    echo "doc/doc_repo/_static/doxyfiles/" >> .gitignore
    echo "doc/doc_repo/doxyfiles/" >> .gitignore
    if [ "$generate_doc_proto" == "true" ]; then
        echo "doc/doc_repo/protofiles/" >> .gitignore
        echo "doc/doc_repo/_static/protofiles/" >> .gitignore
    fi
else
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Doc folder exists, so we assume that there already configured doc, and we just need to update it" $COLOR_REST
    if [ ! -d doc/doc_repo ]; then
        printf '%s%s%s%s%s\n' $BOLD $COLOR_RED "No doc_repo folder detected, to avoid any mistake script will stop here" $COLOR_REST
        printf '%s%s%s%s%s\n' $BOLD $COLOR_RED "If you want to use generic doc, please delete doc folder and rerun script" $COLOR_REST
        exit 1
    fi

    cd doc

    if [ ! -d libDM_doc_template ]; then
        printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Getting template files, no configuration file will be updated from it" $COLOR_REST
        if [ "$2" = "ci" ]; then
            git clone https://gitlab-ci-token:$runner_ci_token_main@git.weskrauser.duckdns.org/code/doc/libdm_doc_template.git libDM_doc_template
        else
            git clone ssh://git@git.weskrauser.duckdns.org:2224/code/doc/libdm_doc_template.git libDM_doc_template
        fi
    fi

    cd doc_repo
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Generating Doxygen documentation" $COLOR_REST
    doxygen Doxyfile
    rm -rf _static/doxyfiles
    cp -r doxyfiles/html _static/doxyfiles
    # Protobuf
    if [ "$generate_doc_proto" == "true" ]; then
        printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Generating Proto documentation" $COLOR_REST
        printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Getting plugin for protoc" $COLOR_REST
        if [ "$machine" == "Mac" ]; then
            cp ../libDM_doc_template/tools/protoc-gen-doc-mac-arm protoc-gen-doc
            rm -rf _static/protofiles
            if [ ! -d protofiles ]; then
                mkdir protofiles
            fi
            protoc --doc_out=html,/protofiles/protobuf.html:./protofiles --plugin=protoc-gen-doc \
                --experimental_allow_proto3_optional \
                --proto_path=../../src/message_definitions \
                ../../src/message_definitions/frame.proto ../../src/message_definitions/types.proto
            cp -r protofiles _static/protofiles
        elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
            cp ../libDM_doc_template/tools/protoc-gen-doc-linux-x86 protoc-gen-doc
            rm -rf _static/protofiles
            if [ ! -d protofiles ]; then
                mkdir protofiles
            fi
            protoc --doc_out=html,/protofiles/protobuf.html:./protofiles --plugin=protoc-gen-doc \
                --experimental_allow_proto3_optional \
                --proto_path=../../src/message_definitions \
                ../../src/message_definitions/frame.proto ../../src/message_definitions/types.proto
            cp -r protofiles _static/protofiles
        else
            printf '%s%s%s%s%s\n' $BOLD $COLOR_RED "Can not find correct plugin for protobuf documentation" $COLOR_REST
        fi
    fi
    printf '%s%s%s%s%s\n' $BOLD $COLOR_ORANGE "Generating Sphinx documentation" $COLOR_REST
    make html
fi