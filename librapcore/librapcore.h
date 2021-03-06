
#include <inttypes.h>
#include <errno.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <fcntl.h>
#include <time.h>
#include <sys/ioctl.h>
#include <linux/ioctl.h>
#include <sys/stat.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>


#define SPI_CPHA		0x01
#define SPI_CPOL		0x02

#define SPI_MODE_0		(0|0)
#define SPI_MODE_1		(0|SPI_CPHA)
#define SPI_MODE_2		(SPI_CPOL|0)
#define SPI_MODE_3		(SPI_CPOL|SPI_CPHA)

#define SPI_CS_HIGH		0x04
#define SPI_LSB_FIRST		0x08
#define SPI_3WIRE		0x10
#define SPI_LOOP		0x20
#define SPI_NO_CS		0x40
#define SPI_READY		0x80
#define SPI_TX_DUAL		0x100
#define SPI_TX_QUAD		0x200
#define SPI_RX_DUAL		0x400
#define SPI_RX_QUAD		0x800
#define SPI_CS_WORD		0x1000
#define SPI_TX_OCTAL		0x2000
#define SPI_RX_OCTAL		0x4000
#define SPI_3WIRE_HIZ		0x8000

int32_t sign_extend_24_32(uint32_t x) {
    const int bits = 24;
    int32_t m = 1u << (bits - 1);
    return (x ^ m) - m;
}

static void pabort(const char *s)
{
	if (errno != 0)
		perror(s);
	else
		printf("%s\n", s);

	abort();
}

static uint64_t default_tx[64];
static uint64_t default_rx[64];

typedef struct RAPcores_version {
    uint8_t major;
    uint8_t minor;
    uint8_t patch;
    uint8_t dev;
} rapcores_version;

typedef struct RAPcores_encoder {
    int32_t position;
    int32_t velocity;
} rapcores_encoder;

typedef struct RAPcore {
    char* device;
    uint32_t mode;
    uint8_t  bits; //8
    uint32_t speed;
    uint64_t *tx;
    uint64_t *rx;
    int fd;

    // Queried from SPI FSM
    uint8_t motor_count;
    uint8_t encoder_count;
    uint8_t encoder_position_precision;
    uint8_t encoder_velocity_precision;

    struct RAPcores_version version;
} rapcore;

static void transfer(struct RAPcore rapcore, uint8_t length) //int fd, uint64_t const *tx, uint64_t const *rx, size_t len)
{

	int ret;

	struct spi_ioc_transfer tr = {
		.tx_buf = (unsigned long)rapcore.tx,
		.rx_buf = (unsigned long)rapcore.rx,
		.len = length*8, // expects bytes
        .speed_hz = rapcore.speed,
        .delay_usecs = 0,
        .bits_per_word = 8
	};

	ret = ioctl(rapcore.fd, SPI_IOC_MESSAGE(1), &tr);
	if (ret < 1)
		pabort("can't send spi message");

};

struct RAPcores_version get_version(struct RAPcore rapcore) {
    rapcore.tx[0] = (uint64_t)0xfe << 56;
    rapcore.tx[1] = 0;

    transfer(rapcore, 2);

    rapcores_version v = {
        .patch = rapcore.rx[1] & 0xff,
        .minor = (rapcore.rx[1] & 0xff<<8) >> 8,
        .major = (rapcore.rx[1] & 0xff<<16) >> 16,
        .dev   = (rapcore.rx[1] & 0xff<<24) >> 24
    };
    return v;
}

struct RAPcores_encoder get_encoder(struct RAPcore rapcore, uint64_t channel) {
    rapcore.tx[0] = (uint64_t)0x03 << 56 | channel << 48;
    rapcore.tx[1] = 0;

    transfer(rapcore, 2);

    rapcores_encoder e = {
        .position = sign_extend_24_32(rapcore.rx[1] & 0xffffff),
        .velocity   = (rapcore.rx[1] & (uint64_t)0xffffffff<<24) >> 24
    };
    return e;
}

void get_channel_info(struct RAPcore *rapcore) {
    rapcore->tx[0] = (uint64_t)0xfd << 56;
    rapcore->tx[1] = 0;

    transfer(*rapcore,2);

    rapcore->motor_count = rapcore->rx[1] & 0xff;
    rapcore->encoder_count = (rapcore->rx[1] & 0xff<<8) >> 8;
    rapcore->encoder_position_precision = (rapcore->rx[1] & 0xff<<16) >> 16;
    rapcore->encoder_velocity_precision = (rapcore->rx[1] & 0xff<<24) >> 24;
}



struct RAPcore init_rapcore(char* device, uint32_t speed) {
    uint32_t mode = 0x04;
    uint8_t  bits = 0x08;

    int fd = open(device, O_RDWR);

    struct RAPcore rapcore = {
        .mode = mode,
        .bits = bits,
        .speed = speed,
        .fd = fd,
        .tx = default_tx,
        .rx = default_rx,
    };


    int ret;

	if (fd < 0)
		pabort("can't open device");

	/*
	 * spi mode
	 */
	ret = ioctl(fd, SPI_IOC_WR_MODE32, &mode);
	if (ret == -1)
		pabort("can't set spi mode");

	ret = ioctl(fd, SPI_IOC_RD_MODE32, &mode);
	if (ret == -1)
		pabort("can't get spi mode");

	/*
	 * bits per word
	 */
	ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &rapcore.bits);
	if (ret == -1)
		pabort("can't set bits per word");

	ret = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &rapcore.bits);
	if (ret == -1)
		pabort("can't get bits per word");

	/*
	 * max speed hz
	 */
	ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &rapcore.speed);
	if (ret == -1)
		pabort("can't set max speed hz");

	ret = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &rapcore.speed);
	if (ret == -1)
		pabort("can't get max speed hz");

	struct RAPcores_version ver = get_version(rapcore);
    rapcore.version = ver;

	if (ver.major == 0 && ver.minor == 0)
		pabort("failed to query version, check connection");

    get_channel_info(&rapcore);

    return rapcore;
}
