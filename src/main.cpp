#include <Arduino.h>

#include "common.hpp"
#include "tasks.hpp"

#include <SparkFun_u-blox_GNSS_v3.h> 


void setup()
{
    // Serial.begin(250000000);
    Serial.begin(115200);

    pinInit();
    protocolInit();

    // Gps init
    initializeGPS();

    // Model init
    initializeModel();



    // Logger init
    initializeModelLogger();
    initializeSensorsLogger();
    initializeUtilityLogger();
    //startLogger(); // Has to be done after SPI init (protocolInit)

    // Configure RTOS tasks
    rtosSetup();
}

void loop()
{
    //delay(1000); // NOLINT
}
