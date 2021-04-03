
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

static void parse_opts(int argc, char *argv[])
{
	while (1) {
		static const struct option lopts[] = {
			{ "device",  1, 0, 'D' },
			{ NULL, 0, 0, 0 },
		};
		int c;

		c = getopt_long(argc, argv, "D:s:d:b:i:o:lHOLC3NR248p:vS:I:",
				lopts, NULL);

		if (c == -1)
			break;

		switch (c) {
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

	return ret;
}
