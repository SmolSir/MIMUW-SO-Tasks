#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stdbool.h>

bool check_zeros(const int *delta, int length) {
    for (int i = 0; i < length; i++) {
        if (delta[i]) {
            return false;
        }
    }

    return true;
}

bool check_signs(const int *delta, int length) {
    for (int i = 1; i < length; i++) {
        if (delta[i - 1] != -delta[i]) {
            return false;
        }
    }

    return true;
}

int polynomial_degree(const int *y, int n) {
    if (check_zeros(y, n)) {
        return -1;
    }
    if (check_signs(y, n)) {
        return n - 1;
    }

    int *values = malloc(sizeof(int[n]));
    memcpy(values, y, sizeof(int[n]));

    for (int delta = 1; delta < n; delta++) {
        for (int i = 0; i < n - delta; i++) {
            values[i] = values[i + 1] - values[i];
        }

        if (check_zeros(values, n - delta)) {
            free(values);
            return delta - 1;
        }

        if (check_signs(values, n - delta)) {
            free(values);
            return n - 1;
        }
    }

    return n - 1;
}
