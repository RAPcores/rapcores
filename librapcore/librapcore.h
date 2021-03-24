
#include <inttypes.h>

struct RAPcore {
    const char* device;
    uint32_t mode;
    uint8_t bits; //8
    uint32_t speed;
};

void init_rapcore(struct RAPcore *r) {
    r->device = "/dev/spidev0.0";
    r->mode = 0x04;
    r->bits = 0x08;
    r-> speed = 1000000;
}
