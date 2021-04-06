
#include "librapcore.h"

static void print_usage(const char *prog)
{
	printf("Usage: %s \n", prog);
	puts("  -D --device          device to use (default /dev/spidev0.0)\n"
	     "  -s --speed           max speed (Hz)\n"
	     "  -v --verbose         Verbose (show tx buffer)\n"
		 "     --test-connection Test the Bus error rate"
		 "     --version         Print Version and exit"
		 "     --info            Print info and exit");
	exit(1);
}

static int print_version = 0;
static int verbose_flag = 0;
static int info_flag = 0;
static int telemetry_flag = 0;
static int connection_test_flag = 0;
char* version_str = "0.1.0-dev";
char* device = "/dev/spidev0.0";
static uint32_t speed = 100000;


static void parse_opts(int argc, char *argv[])
{
	while (1) {
		static const struct option lopts[] = {
            {"verbose", no_argument, &verbose_flag, 'v'},
			{"version", no_argument, &print_version, 1},
			{"info", no_argument, &info_flag, 1},
			{"test-connection", no_argument, &connection_test_flag, 1},
			{"help", no_argument, NULL, 1},
			{"device",  1, 0, 'D' },
			{"speed", 1, 0, 's'},
			{ NULL, 0, 0, 0 },
		};
		int c;
		int option_index = 0;

		c = getopt_long(argc, argv, "D:sv",
				lopts, &option_index);

		if (c == -1)
			break;

		switch (c) {
			case 0:
				/* If this option set a flag, do nothing else now. */
				if (lopts[option_index].flag != 0)
					break;
				break;
			case 's':
				speed = atoi(optarg);
				break;
			case 'D':
				device = optarg;
				break;
			default:
				print_usage(argv[0]);
		}
	}
}

void connection_test(struct RAPcore rapcore) {

	int error_ct = 0;
	for (int i=0; i < 1000; i++) {
		struct RAPcores_version ver = get_version(rapcore);
		// TODO - Hardcoded
		if (ver.major != 0x0 || ver.minor != 0x2 || ver.patch != 0x0 || ver.dev != 0x1) {
			error_ct++;
		}
	}
	printf("Error count: %u\n", error_ct);
	printf("Error rate: %f%%\n", error_ct/10.0);
}

int main(int argc, char *argv[])
{
	int ret = 0;

	parse_opts(argc, argv);

	struct RAPcore rapcore = init_rapcore(device, speed);

	if (print_version || info_flag || verbose_flag) {
		printf("librapcores version: %s\n", version_str);
		struct RAPcores_version ver = rapcore.version;
		printf("bitstream version: %u.%u.%u-%s\n", ver.major, ver.minor, ver.patch, ver.dev ? "dev" : "");
		if (!info_flag || !verbose_flag) exit(0);
	}

	if (info_flag || verbose_flag) {
		printf("device: %s\n", device);
		printf("spi mode: 0x%x\n", rapcore.mode);
		printf("bits per word: %u\n", rapcore.bits);
		printf("max speed: %u Hz (%.3f MB/s)\n", rapcore.speed, rapcore.speed/8000000.0);
		printf("motor count: %u\n", rapcore.motor_count);
		printf("encoder count: %u\n", rapcore.encoder_count);
		printf("encoder position bits: %u\n", rapcore.encoder_position_precision);
		printf("encoder velocity bits: %u\n", rapcore.encoder_velocity_precision);

		if (!verbose_flag) exit(0);
	}

	if (connection_test_flag){
		connection_test(rapcore);
	}

	rapcores_encoder enc = get_encoder(rapcore, 3);
	printf("Position:%d Velocity:%d\n", enc.position, enc.velocity);
	//if (calibrate_flag) {
	//	calibrate(rapcore);
	//}

	return ret;
}
