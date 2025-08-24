
How modify code
===============

.. toctree::
   :maxdepth: 3
   :caption: Contents:


The code proposed is just made to be used as example and propose an architecture. Any compatible library can be integrated, and included library can be reused in other projects.

Platform support
----------------

Framework:

- Arduino

This code is made to be used with:

- ESP32-S3 family

Tasks
------

A list of tasks are already running in the app_ins example. They are described by :cpp:struct:`TASKS_UNIT_CONFIG`. Any task can be modified, removed or added with the same configuration as the existing ones in `tasks.hpp` and definition in `task.cpp`.

The included ones are:

.. role:: underline
    :class: underline

- **taskMain**: this is the principal and most prioritary task. Its role is to get sensors measures at the correct frequency and to feed them to INS fusion algorithm at 500Hz. This frequency is defined by the native INS fusion algorithm frequency, it should not be changed.

- **taskSecondary**: this task is the main task of the second ESP32 core. In the example included it is used to parse ublox GPS NAV_PVT messages and write buffers to SD card for logging. It can be used for any fast task that can run on the second core.

- **taskCom**: this task is placed on the first core but can be moved to the second one if necessary. It is less prioritary than `task_main` and is triggered at 200Hz. In the example, it is used for messages reception/broadcasting in protobuf, mavlink, CAN ... It will be used for wifi and bluetooth communication and configuration from client in the future.

- **taskCalib**: this task does not contain loop. In the example included, it is used for calibration tasks like magnetometer calibration. It can be used for any task that does not need to run continuously.

- **taskDebug**: this task is the lowest prioritary task. It is triggered at 10Hz and is used for debug purposes. It can be used to print variables on serial monitor, blink a led... without disturbing time critical tasks.

Sensors
-------

A light machanism is used to manage sensors. It is described by :cpp:class:`SENSOR_UNIT_CONFIG`. Any sensor can be modified, removed or added with the same configuration as the existing ones.

The principle is the create a sensor object, set its activation state and indicate the frequency at which it should be read.
Once inside the task that will be used to read the sensor, a call to :cpp:func:`SENSOR_UNIT_CONFIG::setRatio` with the current task period will complete the sensor configuration.

Once inside the task's loop, a call to :cpp:func:`SENSOR_UNIT_CONFIG::checkRatio` will return true if the sensor should be read at this loop iteration.

An example could be:

.. code-block:: cpp

    // Create a sensor object which is activated and should be read at 100Hz (10ms period)
    SENSOR_UNIT_CONFIG sensorTest = SENSOR_UNIT_CONFIG(true, 10);

    // Inside task setup
    sensorTest.setRatio(currentTask.period);

    // Inside task loop
    while(true)
    {
        if(sensorTest.checkRatio())
        {
            // Read sensor
        }
    }


Add a library to the code
-------------------------

Any library code can be cloned in the `lib` folder. It will be compiled and linked with the code thanks to platformio library dependency finder.

If a library is added, user just need to include its headers in the app_ins code and add include source code folders in `platformio.ini` file of app_ins folder:

.. code-block:: ini

    build_flags =
        -I lib/newlib_folder/src/
        ...

Like explained in the :ref:`Build code<how-to_build_code>` section, we can build the code with:

.. code-block:: bash

    pio run -e lolin_s3


and build+flash with:

.. code-block:: bash

    pio run -e lolin_s3 --target upload