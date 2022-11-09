#include <assert.h>

int polynomial_degree(const int *y, int n);

#define test(n, ans, y...) { \
	int tab[n] = y; \
	assert(polynomial_degree(tab, n) == ans); \
}

int main() {
	test(84, 83, {2859, 0, 390, 0, 125, 0, 46, 0, 55, 0, 0, 0, 15, 0, 0, 0, 5, 0, 0, 0, 3, 0, 6, 0, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
}
