#!/bin/bash
gcc -DCORES=4 -c -Wall -Wextra -std=c17 -O2 -o so_emulator_example.o so_emulator_example.c
nasm -DCORES=4 -f elf64 -w+all -w+error -o so_emulator.o so_emulator.asm
gcc -pthread -o example so_emulator_example.o so_emulator.o