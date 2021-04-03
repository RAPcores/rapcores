
#include "librapcore.h"


static void print_usage(const char *prog)
{
	printf("Usage: %s [-DsbdlHOLC3vpNR24SI]\n", prog);
	puts("  -D --device   device to use (default /dev/spidev1.1)\n"
	     "  -s --speed    max speed (Hz)\n"
	     "  -b --bpw      bits per word\n"
	     "  -C --cs-high  chip select active high\n"
	     "  -3 --3wire    SI/SO signals shared\n"
	     "  -v --verbose  Verbose (show tx buffer)\n"
		 "     --version  Print Version and exit"
	     "  -p            Send data (e.g. \"1234\\xde\\xad\")\n"
	     "  -N --no-cs    no chip select\n"
	     "  -R --ready    slave pulls low to pause\n"
	     "  -2 --dual     dual transfer\n"
	     "  -4 --quad     quad transfer\n"
	     "  -8 --octal    octal transfer\n"
	     "  -S --size     transfer size\n"
	     "  -I --iter     iterations\n");
	exit(1);
}

static int print_version;
static int verbose_flag;

static void parse_opts(int argc, char *argv[])
{
	while (1) {
		static const struct option lopts[] = {
            {"verbose", no_argument, &verbose_flag, 1},
			{"version", no_argument, &print_version, 1},
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
				printf ("option %s", lopts[option_index].name);
				if (optarg)
					printf (" with arg %s", optarg);
				printf ("\n");
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

	printf("spi mode: 0x%x\n", rapcore.mode);
	printf("bits per word: %u\n", rapcore.bits);
	printf("max speed: %u Hz (%.3f mbps)\n", rapcore.speed, rapcore.speed/8000000.0);

	if (print_version) {
		struct RAPcores_version ver = get_version(rapcore);
		printf("Version: %u.%u.%u\n", ver.major, ver.minor, ver.patch);
	}

	return ret;
}
