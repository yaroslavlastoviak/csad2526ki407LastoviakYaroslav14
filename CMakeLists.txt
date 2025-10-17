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
