#include "foo.h"
#include "bar.h"

int baz(int a) {
    return foo(a + bar());
}

