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

# ----------------- Підтримка GoogleTest та юніт-тестів -----------------

include(FetchContent)

# Отримуємо GoogleTest (без зовнішньої інсталяції)
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG release-1.14.0
)
# Для MSVC: використати спільний CRT (рекомендація GoogleTest)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Увімкнути ctest
enable_testing()

# Виконуваний файл з тестами
add_executable(unit_tests
  tests/unit_tests.cpp
  math_operations.cpp
)

# Додати інклуди з кореня (для math_operations.h)
target_include_directories(unit_tests PRIVATE
  ${PROJECT_SOURCE_DIR}
)

# Лінкування з GTest
target_link_libraries(unit_tests
  GTest::gtest_main
)

# (опціонально) явно зазначити стандарт для цілі тестів
set_property(TARGET unit_tests PROPERTY CXX_STANDARD 17)

# Автоматичне виявлення та реєстрація тестів
include(GoogleTest)
gtest_discover_tests(unit_tests)
