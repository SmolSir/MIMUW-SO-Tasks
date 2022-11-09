#!/bin/bash

GREEN="\e[1;32m"
RED="\e[1;31m"
DEFAULT="\e[0m"

function test_ok {
    printf "${GREEN}OK${DEFAULT}\n"
}

function test_bad {
    printf "${RED}WRONG${DEFAULT}\n"
}

function compile_so_emulator_asm {
	if ! nasm -DCORES=4 -f elf64 -w+all -w+error -o so_emulator.o ../so_emulator.asm; then
		test_bad
		echo "Błąd kompilacji ../so_emulator.asm"
		exit 1
	fi
}

function compile_c {
	compile_so_emulator_asm
	if ! gcc -DCORES=4 -c -Wall -Wextra -std=c17 -O2 -o $1.o $1.c; then
		test_bad
		echo "Błąd kompilacji $1.c"
		exit 1
	fi
	if ! gcc -pthread -o $1.e $1.o so_emulator.o; then
		test_bad
		echo "Błąd linkowania $1.o so_emulator.o"
		exit 1
	fi
}

function compile_cpp {
	compile_so_emulator_asm
	if ! g++ -DCORES=1 -c -Wall -Wextra -std=c++17 -O2 -o $1.o $1.cpp -g; then
		test_bad
		echo "Błąd kompilacji $1.cpp"
		exit 1
	fi
	if ! g++ -pthread -o $1.e $1.o so_emulator.o -g; then
		test_bad
		echo "Błąd linkowania $1.o so_emulator.o"
		exit 1
	fi
}

function run_test {
	./$1.e < $1.out > user_output.out
	code=$?

	if (( $code != 0 )); then
		test_bad
		echo "Runtime Error"
		exit 1
	elif ! diff $1.out user_output.out > /dev/null; then
		test_bad
		echo "Wrong Answer"
		exit 1
	else
		test_ok
	fi
}

function cleanup {
	rm *.o *.e user_output.out
}

TESTS="so_emulator_example_mov.c so_emulator_example_mul.c so_emulator_example_multi_core_inc.c xchg_atomicity.c correctness_random.cpp correctness_random_bigger.cpp"

function run_all_tests {
	for file in $TESTS; do
		testname=${file%.*}
		extension=${file#*.}
		echo -n "$testname "

		if [ $extension = "c" ]; then
			compile_c $testname
		elif [ $extension = "cpp" ]; then
			compile_cpp $testname
		else
			test_bad
			exit 1
		fi

		run_test $testname

		cleanup $testname
	done
}

run_all_tests 2> /dev/null
