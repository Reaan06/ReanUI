cmake_minimum_required(VERSION 3.14)
project(ReanUI C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Fetching Lexbor for CSS Parsing
include(FetchContent)
FetchContent_Declare(
  lexbor
  GIT_REPOSITORY https://github.com/lexbor/lexbor.git
  GIT_TAG master
)
FetchContent_MakeAvailable(lexbor)

# Finding Lua dependency
find_package(Lua REQUIRED)

add_library(reanui SHARED
    src/core/memory.c
    src/css/parser.c
    src/layout/box_model.c
    src/dom/node.c
    src/bridge/lua_bridge.c
)

target_include_directories(reanui PUBLIC include)
target_include_directories(reanui PRIVATE src)
target_include_directories(reanui PRIVATE ${LUA_INCLUDE_DIR})

target_link_libraries(reanui PRIVATE lexbor)
target_link_libraries(reanui PRIVATE ${LUA_LIBRARIES})

# To test independently if we compile it
# add_executable(test_exe src/main_test.c)
# target_link_libraries(test_exe reanui)
