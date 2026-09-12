#ifndef SMC_BRIDGE_H
#define SMC_BRIDGE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    float system_total;    // PSTR: System Total Power Consumed in Watts (Delayed 1s)
    float battery_rate;    // PPBR: Battery Power Flow in Watts
    float delivery_rate;   // PDTR: Power Delivery Rate from Charger in Watts
    float heatpipe;        // PHPC: SoC Power in Watts
    float brightness;      // PDBR: Screen Power in Watts
    float temperature;     // TB0T: Battery Temperature in Celsius
    float charging_status; // CHCC: > 0 if charging
    float full_capacity;   // B0FC: Full charge capacity
    float current_capacity;// SBAR: Current capacity
    bool is_valid;
} SMCPowerReading;

bool smc_open(void);
void smc_close(void);
SMCPowerReading smc_read_all(void);

#ifdef __cplusplus
}
#endif

#endif /* SMC_BRIDGE_H */
