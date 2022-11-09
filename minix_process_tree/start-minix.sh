#!/bin/bash
qemu-system-x86_64 -display curses -drive file=$1 -rtc base=localtime -net user,hostfwd=tcp::$2-:22 -net nic,model=virtio -m 1024M