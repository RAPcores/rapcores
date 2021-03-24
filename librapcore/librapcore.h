
#include <inttypes.h>

struct RAPcore {
    

};


struct CoordinatedMove1 {
    uint32_t duration;
    int64_t increment[1];
    int64_t increment_increment[1];
};

struct ChannelConfig {
    uint8_t channel;
    uint8_t current;
    uint8_t microsteps;
};
