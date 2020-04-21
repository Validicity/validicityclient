#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <nfc/nfc.h>
#include <freefare.h>

// This is a small binary executable that communicates over stdout/stdin using JSON
// payloads. It is spawned as a child process from the Dart main client and driven
// from Dart to initiate scans etc.
int main(int argc, char *argv[]) {
	char line[50];

	printf("{\"STATUS\":\"STARTING\"}\n");
	fflush(stdout); // Important for this to work!

    nfc_device *device = NULL;
    FreefareTag *tags = NULL;

    if (argc > 1) {
		errx(EXIT_FAILURE, "usage: %s", argv[0]);
	}

    nfc_connstring devices[8];
    size_t device_count;

    nfc_context *context;
    nfc_init(&context);
    if (context == NULL) {
		errx(EXIT_FAILURE, "Unable to init libnfc (malloc)");
	}

    device_count = nfc_list_devices(context, devices, sizeof(devices) / sizeof(*devices));
    if (device_count <= 0) {
		errx(EXIT_FAILURE, "No NFC device found");
	}
	device = nfc_open(context, devices[0]);
	if (!device) {
		errx(EXIT_FAILURE, "nfc_open() failed.");
	}
	printf("{\"STATUS\":\"READY\"}\n");
	fflush(stdout);

	while (fgets(line, 50, stdin) != NULL) {
		if (!(tags = freefare_get_tags(device))) {
			//nfc_close(device);
			printf("{\"STATUS\": \"FAILED SCAN\"}\n");
			fflush(stdout);
		} else {
			// We only take one tag per scan
			if (!tags[0]) {
				printf("{\"STATUS\": \"NOTAG\"}\n");
				fflush(stdout);
			} else {
				char *tag_uid = freefare_get_tag_uid(tags[0]);
				printf("{\"STATUS\": \"OK\", \"ID\":\"%s\", \"NAME\": \"%s\"}\n", tag_uid, freefare_get_tag_friendly_name(tags[0]));
				fflush(stdout);
				free(tag_uid);
			}
			freefare_free_tags(tags);
		}
	}
	nfc_close(device);
    nfc_exit(context);
    exit(EXIT_SUCCESS);
}
