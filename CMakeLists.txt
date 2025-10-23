cmake_minimum_required(VERSION 3.10)

# Назва проекту
project(Csad2526ki407LastoviakYaroslav14 VERSION 1.0 LANGUAGES CXX)

# Встановити стандарт C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Додати всі .cpp файли з поточної директорії
file(GLOB SOURCES "*.cpp")

# Створити виконуваний файл з джерел
add_executable(${PROJECT_NAME} ${SOURCES})

# Math operations library for unit testing
add_library(math_operations math_operations.cpp)

# Google Test setup
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/heads/main.zip
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

enable_testing()
# Додаємо папку з заголовочними файлами
include_directories(${CMAKE_SOURCE_DIR})

# Create unit test executable
add_executable(unit_tests tests/unit_tests.cpp)
target_link_libraries(unit_tests gtest_main math_operations)

include(GoogleTest)
gtest_discover_tests(unit_tests)
