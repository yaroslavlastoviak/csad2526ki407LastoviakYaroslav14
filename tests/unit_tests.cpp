#include <cassert>
#include <iostream>
#include "../math_operations.h"

static void test_add_positive_numbers() {
    assert(add(2, 3) == 5);
    assert(add(1000, 2000) == 3000);
}

static void test_add_with_negatives() {
    assert(add(-2, 3) == 1);
    assert(add(2, -3) == -1);
    assert(add(-2, -3) == -5);
}

static void test_add_with_zero() {
    assert(add(0, 0) == 0);
    assert(add(0, 5) == 5);
    assert(add(5, 0) == 5);
}

static void test_add_large_values() {
    assert(add(123456, 654321) == 777777);
}

int main() {
    test_add_positive_numbers();
    test_add_with_negatives();
    test_add_with_zero();
    test_add_large_values();

    std::cout << "All unit tests passed\n";
    return 0;
}