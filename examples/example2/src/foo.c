#include <stdio.h>

int foo(int a) {
    printf("%s: %d", __func__, a);
    return a * 2;
}

