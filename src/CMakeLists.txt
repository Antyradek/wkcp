cmake_minimum_required(VERSION 3.18)

add_executable(view view.cpp)
set_property(TARGET view PROPERTY CXX_STANDARD 20)
set_property(TARGET view PROPERTY COMPILE_OPTIONS -Wall -Wextra -Werror -O2)
