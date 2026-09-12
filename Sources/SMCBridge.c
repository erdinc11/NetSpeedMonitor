#include "SMCBridge.h"
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <IOKit/IOKitLib.h>

typedef struct {
    uint8_t major;
    uint8_t minor;
    uint8_t build;
    uint8_t reserved;
    uint16_t release;
} SMCVersion;

typedef struct {
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
} SMCPLimitData;

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    uint8_t dataAttributes;
} SMCKeyInfoData;

typedef struct {
    uint32_t key;
    SMCVersion vers;
    SMCPLimitData pLimitData;
    SMCKeyInfoData keyInfo;
    uint8_t result;
    uint8_t status;
    uint8_t data8;
    uint32_t data32;
    uint8_t bytes[32];
} SMCKeyData;

static io_connect_t g_smc_conn = 0;

static uint32_t str_to_u32(const char *s) {
    return ((uint32_t)(uint8_t)s[0] << 24) |
           ((uint32_t)(uint8_t)s[1] << 16) |
           ((uint32_t)(uint8_t)s[2] << 8)  |
           (uint32_t)(uint8_t)s[3];
}

bool smc_open(void) {
    if (g_smc_conn != 0) return true;
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (!service) return false;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &g_smc_conn);
    IOObjectRelease(service);
    return (kr == KERN_SUCCESS);
}

void smc_close(void) {
    if (g_smc_conn != 0) {
        IOServiceClose(g_smc_conn);
        g_smc_conn = 0;
    }
}

static float smc_read_key(const char *key) {
    if (!smc_open()) return -1.0f;

    SMCKeyData input = {0};
    SMCKeyData output = {0};
    size_t inSize = sizeof(SMCKeyData);
    size_t outSize = sizeof(SMCKeyData);

    input.key = str_to_u32(key);
    input.data8 = 9; // CMD_READ_KEYINFO

    kern_return_t kr = IOConnectCallStructMethod(g_smc_conn, 2, &input, inSize, &output, &outSize);
    if (kr != KERN_SUCCESS) return -1.0f;

    uint32_t dt = output.keyInfo.dataType;
    char typeStr[5] = {(char)((dt>>24)&0xff), (char)((dt>>16)&0xff), (char)((dt>>8)&0xff), (char)(dt&0xff), 0};

    memset(&input, 0, sizeof(input));
    input.key = str_to_u32(key);
    input.data8 = 5; // CMD_READ_BYTES
    input.keyInfo = output.keyInfo;
    outSize = sizeof(SMCKeyData);

    kr = IOConnectCallStructMethod(g_smc_conn, 2, &input, inSize, &output, &outSize);
    if (kr != KERN_SUCCESS) return -1.0f;

    if (strcmp(typeStr, "flt ") == 0 || strcmp(typeStr, "flt") == 0) {
        float f = 0;
        memcpy(&f, output.bytes, sizeof(float));
        return f;
    } else if (strcmp(typeStr, "sp78") == 0) {
        int16_t val = (output.bytes[0] << 8) | output.bytes[1];
        return (float)val / 256.0f;
    } else if (strcmp(typeStr, "ui8 ") == 0 || strcmp(typeStr, "ui8") == 0) {
        return (float)output.bytes[0];
    } else if (strcmp(typeStr, "ui16") == 0) {
        uint16_t val = (output.bytes[1] << 8) | output.bytes[0];
        return (float)val;
    }
    return -1.0f;
}

SMCPowerReading smc_read_all(void) {
    SMCPowerReading r = {0};
    if (!smc_open()) return r;

    // Direct sensors matching powerflow (tpower crate)
    r.system_total = smc_read_key("PSTR");  // System Total Power Consumed (Delayed 1 Second)
    r.battery_rate = smc_read_key("PPBR");  // Battery Rate
    r.delivery_rate = smc_read_key("PDTR"); // Delivery Rate (charger wattage)
    r.heatpipe = smc_read_key("PHPC");      // SoC Power
    r.brightness = smc_read_key("PDBR");    // Screen Power
    r.temperature = smc_read_key("TB0T");   // Battery Temperature
    r.charging_status = smc_read_key("CHCC");// Charging status
    r.full_capacity = smc_read_key("B0FC"); // Full charge capacity
    r.current_capacity = smc_read_key("SBAR");// Current capacity
    
    // Valid if system_total or delivery_rate or battery_rate was successfully read
    r.is_valid = (r.system_total >= 0.0f || r.battery_rate >= 0.0f);
    return r;
}
