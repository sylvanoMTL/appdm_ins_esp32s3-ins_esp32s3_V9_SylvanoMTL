.. _how-to_build_code:

How build code
==============

.. toctree::
   :maxdepth: 3
   :caption: Contents:

Platform support
----------------

Framework:

- Arduino

This code is made to be used with:

- ESP32-S3 family (could work with other ESP32 family)

Assembling dependencies
-----------------------

The SYSROX code uses repo to synchronize all necessary repositories. The app_ins can not work without the necessary libraries and it is recommended to use repo or a zip file containing all dependencies.

Using repo
----------

The repo system is a tool made by google to manage multiple git repositories. With a file (manifest) containing all the repositories links, it is possible to clone et keep synchronized all project dependencies with a single command.

.. tip::

    The idea is to repo sync the code the first time, do modifications in one or multiple repositories. When the base code is updated, all repositories can be update to the latest version with repo sync. Custom modification can then be rebased on top of the new code!

Install repo
~~~~~~~~~~~~

.. code-block:: bash

    sudo apt-get install repo

If your distribution does not have a repo package, you can do:

.. code-block:: bash

    mkdir -p ~/.bin
    PATH="${HOME}/.bin:${PATH}"
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
    chmod a+rx ~/.bin/repo

Create a folder of your choice to place the project and go to it.

Repo sync code with SSH key
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    repo init -u ssh://git@git.sysrox.com:2224/code/manifests/manifest_ins.git
    repo sync

Repo sync code with HTTPS
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    repo init -u https://git.sysrox.com/code/manifests/manifest_ins.git
    repo sync


Using platformio
----------------

The easiest way to use the code is to use platformio. It includes many tools to build, test and upload the code to the board.
If you use vscode, you can install the extension and juste source the environment.

Sourcing the environment or using the cli is not mandatory as you can just repo sync the code and use platformio extension (on windows for example), but it simplifies the process as you just need to copy paste the  following commands. If you can not do it, you can just use the platformio extension and install Expressif32 platform.

Platformio cli
~~~~~~~~~~~~~~

.. code-block:: bash

    pip install -U platformio

Platformio with vscode IDE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If vscode extension is installed, you can just source the env:

.. code-block:: bash

    source ~/.platformio/penv/bin/activate


Build full code
---------------

The configuration file for the build is a conf.ini located in conf folder. We want to create a symbolic link or copy this file to the root of the project in order to be able to build:

.. code-block:: bash

    ln -s src/appDM_ins_esp32s3/conf/conf.ini platformio.ini

Now we can build the code with:

.. code-block:: bash

    pio run -e lolin_s3


and build+flash with:

.. code-block:: bash

    pio run -e lolin_s3 --target upload