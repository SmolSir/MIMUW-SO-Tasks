#!/bin/bash

for i in {512000..513000}
do
    nasm -DCORES=1 -f elf64 -w+all -w+error -o so_emulator.o ../so_emulator.asm
    gcc -DCORES=1 -DSTEPS=$i -c -Wall -Wextra -std=c17 -O2 -o so_emulator_example.o ../so_emulator_example.c
    gcc -pthread -o example_debug so_emulator_example.o so_emulator.o
    gcc -pthread -o example_correct so_emulator_example.o so_emulator_wiktor.o

    ./example_debug 10240 > debug.out
    ./example_correct 10240 > correct.out
    
    if ! diff debug.out correct.out ; then
        echo "Difference on step $i"
        exit 1
    fi
    echo "Step $i passed"
done
echo "All steps passed"