
#include "librapcore.h"


static void print_usage(const char *prog)
{
	printf("Usage: %s \n", prog);
	puts("  -D --device   device to use (default /dev/spidev0.0)\n"
	     "  -s --speed    max speed (Hz)\n"
	     "  -v --verbose  Verbose (show tx buffer)\n"
		 "     --version  Print Version and exit"
		 "     --info     Print info and exit");
	exit(1);
}

static int print_version;
static int verbose_flag;
static int info_flag;
static int telemetry_flag;
char* version_str = "0.1.0-dev";

static void parse_opts(int argc, char *argv[])
{
	while (1) {
		static const struct option lopts[] = {
            {"verbose", no_argument, &verbose_flag, 1},
			{"version", no_argument, &print_version, 1},
			{"info", no_argument, &info_flag, 1},
			{"help", no_argument, NULL, 1},
			{ "device",  1, 0, 'D' },
			{ NULL, 0, 0, 0 },
		};
		int c;
		int option_index = 0;

		c = getopt_long(argc, argv, "D:",
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
				//speed = atoi(optarg);
				break;
			default:
				print_usage(argv[0]);
		}
	}
}

int main(int argc, char *argv[])
{
	int ret = 0;

	struct RAPcore rapcore = init_rapcore();

	parse_opts(argc, argv);

	if (print_version) {
		printf("librapcores Version: %s\n", version_str);
		struct RAPcores_version ver = rapcore.version;
		printf("Bitstream Version: %u.%u.%u-%s\n", ver.major, ver.minor, ver.patch, ver.dev ? "dev" : "");
		exit(0);
	}

	if (info_flag) {
		printf("spi mode: 0x%x\n", rapcore.mode);
		printf("bits per word: %u\n", rapcore.bits);
		printf("max speed: %u Hz (%.3f mbps)\n", rapcore.speed, rapcore.speed/8000000.0);
		exit(0);
	}

	rapcores_encoder enc = get_encoder(rapcore, 3);
	printf("Position:%d Velocity:%d\n", enc.position, enc.velocity);
	//if (calibrate_flag) {
	//	calibrate(rapcore);
	//}

	return ret;
}
