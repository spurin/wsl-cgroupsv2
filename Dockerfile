# Main Build
FROM ubuntu:22.04

# Install our customised systemd
RUN apt-get update \
    && apt-get install -y systemd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Specify a different stop signal for systemd
STOPSIGNAL SIGRTMIN+3

CMD stat -fc %T /sys/fs/cgroup/ | awk '{if ($1 == "cgroup2fs") print "Success: cgroup type is cgroup2fs"; else print "Failure: Expected cgroup type to be cgroup2fs, but got " $1}'
