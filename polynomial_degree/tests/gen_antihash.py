from math import factorial
import re, os, functools, subprocess

def save_tests_to_file(tests, filename):
    print('saving ' + filename + '...')

    with open(filename, 'w') as f:
        f.write('#include <assert.h>\n\nint polynomial_degree(const int *y, int n);\n\n')
        f.write('#define test(n, ans, y...) { \\\n\tint tab[n] = y; \\\n\tassert(polynomial_degree(tab, n) == ans); \\\n}\n\n')
        f.write('int main() {\n')
        for lst in tests:
            assert [x for x in lst if x < -2 ** 31 or x >= 2 ** 31] == []
            f.write('\ttest(' + str(len(lst)) + ', ' + str(len(lst) - 1) + ', {' + ', '.join([str(x) for x in lst]) + '});\n')
        f.write('}\n')

def binom(n, k):
    return factorial(n) // (factorial(k) * factorial(n - k))

def get_antimod_sequence(mod):
    n = 3;
    while(binom(n, n // 2) <= mod):
        n = n + 1
    
    result = [0 for x in range(n + 1)]
    for i in range(n + 1):
        idx_mul = 1 if i % 2 == 0 else -1
        idx = n // 2 + (i + 1) // 2 * idx_mul
        sgn = 1 if idx % 2 == 0 else -1
        if sgn == -1:
            result[idx] = 0
        else:
            coeff = binom(n, idx)
            if(coeff > mod):
                result[idx] = 0
            else:
                res = 1
                while(mod >= coeff * (res + 1)):
                    res = res + 1
                result[idx] = res
                mod = mod - result[idx] * coeff
    return result
    
def gen_tests_modulo_illegal():
    code = subprocess.getoutput('objdump -d -M intel_mnemonic polynomial_degree.o')

    regexed_numbers = re.findall("0x[0-9a-fA-F]*", code) # find all hex numbers in .o code
    regexed_numbers = [int(x, 16) for x in regexed_numbers] # convert from string to int
    regexed_numbers = [x for x in regexed_numbers if x != 0] # removing 0 from list
    regexed_numbers = list(dict.fromkeys(regexed_numbers)) # remove duplicates
    big_mod = functools.reduce((lambda x, y: x * y), regexed_numbers) # get product of all numbers
    return [get_antimod_sequence(big_mod)]

save_tests_to_file(gen_tests_modulo_illegal(), 'antihash_generated_test.c')
