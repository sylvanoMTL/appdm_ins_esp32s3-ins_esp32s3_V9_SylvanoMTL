#include <Arduino.h>

#include "common.hpp"
#include "tasks.hpp"

void setup()
{
    // Serial.begin(250000000);
    Serial.begin(115200);

    pinInit();
    protocolInit();

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
