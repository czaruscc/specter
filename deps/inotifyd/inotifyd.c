#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/inotify.h>
#include <sys/wait.h>
#include <signal.h>
#include <errno.h>

#define EVENT_SIZE (sizeof(struct inotify_event))
#define BUF_LEN (1024 * (EVENT_SIZE + 16))

static volatile int keep_running = 1;

static void handle_signal(int sig) {
    (void)sig;
    keep_running = 0;
}

static void usage(const char *prog) {
    fprintf(stderr, "Usage: %s [-m <event_mask>] <watch_path> <handler_script>\n", prog);
    fprintf(stderr, "\nIf -m is given, mask is used as-is (decimal).\n");
    fprintf(stderr, "If -m is omitted, defaults to: IN_CREATE | IN_DELETE | IN_ONLYDIR\n");
    exit(1);
}

int main(int argc, char *argv[]) {
    int opt;
    int custom_mask = 0;
    int mask_provided = 0;

    while ((opt = getopt(argc, argv, "m:")) != -1) {
        switch (opt) {
            case 'm':
                custom_mask = atoi(optarg);
                mask_provided = 1;
                break;
            default:
                usage(argv[0]);
        }
    }

    if (optind + 2 != argc) usage(argv[0]);

    const char *watch_path = argv[optind];
    const char *handler = argv[optind + 1];

    uint32_t watch_mask = mask_provided
        ? (uint32_t)custom_mask
        : (IN_CREATE | IN_DELETE | IN_ONLYDIR);

    signal(SIGCHLD, SIG_IGN);
    signal(SIGTERM, handle_signal);
    signal(SIGINT, handle_signal);

    int fd = inotify_init1(IN_CLOEXEC);
    if (fd < 0) {
        perror("inotify_init1");
        return 1;
    }

    int wd = inotify_add_watch(fd, watch_path, watch_mask);
    if (wd < 0) {
        perror("inotify_add_watch");
        close(fd);
        return 1;
    }

    char buf[BUF_LEN];

    while (keep_running) {
        ssize_t len = read(fd, buf, BUF_LEN);
        if (len < 0) {
            if (errno == EINTR) continue;
            break;
        }

        sleep(2);

        pid_t pid = fork();
        if (pid < 0) continue;
        if (pid == 0) {
            execl("/system/bin/sh", "sh", handler, NULL);
            _exit(127);
        }
    }

    close(wd);
    close(fd);
    return 0;
}
