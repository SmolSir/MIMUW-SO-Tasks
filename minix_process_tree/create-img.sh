#!/bin/bash
qemu-img create -f qcow2 -F raw -o backing_file=/home/students/inf/PUBLIC/SO/scenariusze/4/minix.img $1
