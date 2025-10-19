#include <gtest/gtest.h>
#include "math_operations.h"

TEST(MathOperationsTest, AddPositiveNumbers) {
    EXPECT_EQ(add(2, 3), 5);
    EXPECT_EQ(add(10, 20), 30);
}

TEST(MathOperationsTest, AddNegativeNumbers) {
    EXPECT_EQ(add(-2, -3), -5);
    EXPECT_EQ(add(-10, -20), -30);
}

TEST(MathOperationsTest, AddMixedNumbers) {
    EXPECT_EQ(add(-2, 3), 1);
    EXPECT_EQ(add(10, -4), 6);
}

TEST(MathOperationsTest, AddWithZero) {
    EXPECT_EQ(add(0, 0), 0);
    EXPECT_EQ(add(0, 5), 5);
    EXPECT_EQ(add(7, 0), 7);
}