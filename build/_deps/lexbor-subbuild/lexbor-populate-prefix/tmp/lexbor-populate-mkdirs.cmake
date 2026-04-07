# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-src")
  file(MAKE_DIRECTORY "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-src")
endif()
file(MAKE_DIRECTORY
  "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-build"
  "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-subbuild/lexbor-populate-prefix"
  "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-subbuild/lexbor-populate-prefix/tmp"
  "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-subbuild/lexbor-populate-prefix/src/lexbor-populate-stamp"
  "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-subbuild/lexbor-populate-prefix/src"
  "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-subbuild/lexbor-populate-prefix/src/lexbor-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-subbuild/lexbor-populate-prefix/src/lexbor-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/reaan/ReanUI/ReanUI/build/_deps/lexbor-subbuild/lexbor-populate-prefix/src/lexbor-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
