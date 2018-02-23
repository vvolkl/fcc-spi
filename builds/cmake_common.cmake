# FCC Common Dashboard Script
#
# Based on: CMake Common Dashboard Script
# https://gitlab.kitware.com/cmake/dashboard-scripts/blob/master/cmake_common.cmake
#
# This script contains basic dashboard driver code common to all
# clients.
#
# Put this script in a directory such as "~/Dashboards/Scripts" or
# "c:/Dashboards/Scripts".  Create a file next to this script, say
# 'my_dashboard.cmake', with code of the following form:
#
#   # Client maintainer: me@mydomain.net
#   set(CTEST_SITE "machine.site")
#   set(CTEST_BUILD_NAME "Platform-Compiler")
#   set(CTEST_BUILD_CONFIGURATION Debug)
#   set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
#   include(${CTEST_SCRIPT_DIRECTORY}/cmake_common.cmake)
#
# Then run a scheduled task (cron job) with a command line such as
#
#   ctest -S ~/Dashboards/Scripts/my_dashboard.cmake -V
#
# By default the source and build trees will be placed in the path
# "../My Tests/" relative to your script location.
#
# The following variables may be set before including this script
# to configure it:
#
#   dashboard_model       = Nightly | Experimental | Continuous | ...
#   dashboard_root_name   = Change name of "My Tests" directory
#   dashboard_source_name = Name of source directory (CMake)
#   dashboard_binary_name = Name of binary directory (CMake-build)
#   CTEST_GIT_COMMAND     = path to git command-line client
#   CTEST_DASHBOARD_ROOT  = Where to put source and build trees
#   CTEST_TEST_CTEST      = Whether to run long CTestTest* tests
#   CTEST_TEST_TIMEOUT    = Per-test timeout length

cmake_minimum_required(VERSION 2.8.2 FATAL_ERROR)

# Select the top dashboard directory.
if(NOT DEFINED dashboard_root_name)
  set(dashboard_root_name "My Tests")
endif()
if(NOT DEFINED CTEST_DASHBOARD_ROOT)
  get_filename_component(CTEST_DASHBOARD_ROOT "${CTEST_SCRIPT_DIRECTORY}/../${dashboard_root_name}" ABSOLUTE)
endif()

# Select the model (Nightly, Experimental, Continuous).
if(NOT DEFINED dashboard_model)
  set(dashboard_model Nightly)
endif()

# Limit type of models
# if(NOT "${dashboard_model}" MATCHES "^(Nightly|Experimental|Continuous)$")
#   message(FATAL_ERROR "dashboard_model must be Nightly, Experimental, or Continuous")
# endif()

# Default to a Debug build
if(NOT DEFINED CTEST_BUILD_CONFIGURATION)
  set(CTEST_BUILD_CONFIGURATION Debug)
endif()

# Configure testing.
# Run tests by default
if(NOT DEFINED CTEST_TEST_CTEST)
  set(CTEST_TEST_CTEST 1)
endif()
if(NOT CTEST_TEST_TIMEOUT)
  set(CTEST_TEST_TIMEOUT 1500)
endif()

# Look for a GIT command-line client.
if(NOT DEFINED CTEST_GIT_COMMAND)
  set(git_names git git.cmd)

  # First search the PATH.
  find_program(CTEST_GIT_COMMAND NAMES ${git_names})
endif()
if(NOT CTEST_GIT_COMMAND)
  message(FATAL_ERROR "CTEST_GIT_COMMAND not available!")
endif()

set(CTEST_UPDATE_COMMAND ${CTEST_GIT_COMMAND})

# If using Jenkins, GIT_COMMIT will be defined
if(NOT DEFINED CTEST_GIT_UPDATE_CUSTOM)
  if(NOT "$ENV{GIT_COMMIT}" STREQUAL "")
    set(CTEST_GIT_UPDATE_CUSTOM  ${CTEST_GIT_COMMAND} checkout -f $ENV{GIT_COMMIT})
  endif()
endif()

# Select a source directory name.
if(NOT DEFINED CTEST_SOURCE_DIRECTORY)
  if(DEFINED dashboard_source_name)
    set(CTEST_SOURCE_DIRECTORY ${CTEST_DASHBOARD_ROOT}/${dashboard_source_name})
  else()
    set(CTEST_SOURCE_DIRECTORY ${CTEST_DASHBOARD_ROOT}/CMake)
  endif()
endif()

# Select a build directory name.
if(NOT DEFINED CTEST_BINARY_DIRECTORY)
  if(DEFINED dashboard_binary_name)
    set(CTEST_BINARY_DIRECTORY ${CTEST_DASHBOARD_ROOT}/${dashboard_binary_name})
  else()
    set(CTEST_BINARY_DIRECTORY ${CTEST_SOURCE_DIRECTORY}-build)
  endif()
endif()

# Check for required variables.
foreach(req
    CTEST_CMAKE_GENERATOR
    CTEST_SITE
    CTEST_BUILD_NAME
    )
  if(NOT DEFINED ${req})
    message(FATAL_ERROR "The containing script must set ${req}")
  endif()
endforeach(req)

# Print summary information.
set(vars "")
foreach(v
    CTEST_SITE
    CTEST_BUILD_NAME
    CTEST_SOURCE_DIRECTORY
    CTEST_BINARY_DIRECTORY
    CTEST_CMAKE_GENERATOR
    CTEST_BUILD_CONFIGURATION
    CTEST_GIT_COMMAND
    CTEST_CHECKOUT_COMMAND
    CTEST_CONFIGURE_COMMAND
    CTEST_SCRIPT_DIRECTORY
    CTEST_USE_LAUNCHERS
    )
  set(vars "${vars}  ${v}=[${${v}}]\n")
endforeach(v)
message("Dashboard script configuration:\n${vars}\n")

ctest_start(${dashboard_model} TRACK ${dashboard_model})
ctest_update()
ctest_configure(BUILD   ${CTEST_BINARY_DIRECTORY}
                SOURCE  ${CTEST_SOURCE_DIRECTORY})
ctest_build(BUILD ${CTEST_BINARY_DIRECTORY}
            RETURN_VALUE BUILD_STATUS)

# Run tests only if build step succeeded
message("Build result: ${BUILD_STATUS}")
if(BUILD_STATUS EQUAL 0)
  if(DEFINED CTEST_TEST_PARALLEL_LEVEL)
    ctest_test(PARALLEL_LEVEL ${CTEST_TEST_PARALLEL_LEVEL})
  else()
    ctest_test()
  endif()
else()
  message("Build failed, skipping tests...")
endif()

# Submit results
ctest_upload()
ctest_submit()
