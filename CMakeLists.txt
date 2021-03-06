cmake_minimum_required(VERSION 3.1)

#-----------------------------------------------------------------------------#
# Project configuration

project(cvc4)

set(CVC4_MAJOR   1) # Major component of the version of CVC4.
set(CVC4_MINOR   7) # Minor component of the version of CVC4.
set(CVC4_RELEASE 0) # Release component of the version of CVC4.

# Extraversion component of the version of CVC4.
set(CVC4_EXTRAVERSION "-prerelease")

# Shared library versioning. Increment SOVERSION for every new CVC4 release.
set(CVC4_SOVERSION 5)

# Full release string for CVC4.
if(CVC4_RELEASE)
  set(CVC4_RELEASE_STRING
      "${CVC4_MAJOR}.${CVC4_MINOR}.${CVC4_RELEASE}${CVC4_EXTRAVERSION}")
else()
  set(CVC4_RELEASE_STRING "${CVC4_MAJOR}.${CVC4_MINOR}${CVC4_EXTRAVERSION}")
endif()

set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 11)

# Generate compile_commands.json, which can be used for various code completion
# plugins.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Embed the installation prefix as an RPATH in the executable such that the
# linker can find our libraries (such as libcvc4parser) when executing the cvc4
# binary. This is for example useful when installing CVC4 with a custom prefix
# on macOS (e.g. when using homebrew in a non-standard directory). If we do not
# set this option, then the linker will not be able to find the required
# libraries when trying to run CVC4.
#
# More information on RPATH in CMake:
# https://gitlab.kitware.com/cmake/community/wikis/doc/cmake/RPATH-handling
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")

#-----------------------------------------------------------------------------#

include(Helpers)

#-----------------------------------------------------------------------------#
# User options

# License
option(ENABLE_GPL "Enable GPL dependencies")

# General build options
#
# >> 3-valued: IGNORE ON OFF
#    > allows to detect if set by user (default: IGNORE)
#    > only necessary for options set for build types
cvc4_option(ENABLE_ASAN          "Enable ASAN build")
cvc4_option(ENABLE_ASSERTIONS    "Enable assertions")
cvc4_option(ENABLE_DEBUG_SYMBOLS "Enable debug symbols")
cvc4_option(ENABLE_DUMPING       "Enable dumping")
cvc4_option(ENABLE_MUZZLE        "Suppress ALL non-result output")
cvc4_option(ENABLE_OPTIMIZED     "Enable optimization")
cvc4_option(ENABLE_PORTFOLIO     "Enable portfolio support")
cvc4_option(ENABLE_PROOFS        "Enable proof support")
cvc4_option(ENABLE_REPLAY        "Enable the replay feature")
cvc4_option(ENABLE_STATISTICS    "Enable statistics")
cvc4_option(ENABLE_TRACING       "Enable tracing")
cvc4_option(ENABLE_UNIT_TESTING  "Enable unit testing")
cvc4_option(ENABLE_VALGRIND      "Enable valgrind instrumentation")
cvc4_option(ENABLE_SHARED        "Build as shared library")
cvc4_option(ENABLE_STATIC_BINARY
            "Build static binaries with statically linked system libraries")
# >> 2-valued: ON OFF
#    > for options where we don't need to detect if set by user (default: OFF)
option(ENABLE_BEST             "Enable dependencies known to give best performance")
option(ENABLE_COVERAGE         "Enable support for gcov coverage testing")
option(ENABLE_DEBUG_CONTEXT_MM "Enable the debug context memory manager")
option(ENABLE_PROFILING        "Enable support for gprof profiling")

# Optional dependencies
#
# >> 3-valued: IGNORE ON OFF
#    > allows to detect if set by user (default: IGNORE)
#    > only necessary for options set for ENABLE_BEST
cvc4_option(USE_ABC      "Use ABC for AIG bit-blasting")
cvc4_option(USE_CLN      "Use CLN instead of GMP")
cvc4_option(USE_GLPK     "Use GLPK simplex solver")
cvc4_option(USE_READLINE "Use readline for better interactive support")
# >> 2-valued: ON OFF
#    > for options where we don't need to detect if set by user (default: OFF)
option(USE_CADICAL       "Use CaDiCaL SAT solver")
option(USE_CRYPTOMINISAT "Use CryptoMiniSat SAT solver")
option(USE_LFSC          "Use LFSC proof checker")
option(USE_SYMFPU        "Use SymFPU for floating point support")
option(USE_PYTHON2       "Prefer using Python 2 (for Python bindings)")
option(USE_PYTHON3       "Prefer using Python 3 (for Python bindings)")

# Custom install directories for dependencies
# If no directory is provided by the user, we first check if the dependency was
# installed via the corresponding contrib/get-* script and if not found, we
# check the intalled system version. If the user provides a directory we
# immediately fail if the dependency was not found at the specified location.
set(ABC_DIR           "" CACHE STRING "Set ABC install directory")
set(ANTLR_DIR         "" CACHE STRING "Set ANTLR3 install directory")
set(CADICAL_DIR       "" CACHE STRING "Set CaDiCaL install directory")
set(CRYPTOMINISAT_DIR "" CACHE STRING "Set CryptoMiniSat install directory")
set(CXXTEST_DIR       "" CACHE STRING "Set CxxTest install directory")
set(GLPK_DIR          "" CACHE STRING "Set GLPK install directory")
set(GMP_DIR           "" CACHE STRING "Set GMP install directory")
set(LFSC_DIR          "" CACHE STRING "Set LFSC install directory")
set(SYMFPU_DIR        "" CACHE STRING "Set SymFPU install directory")

# Prepend binaries with prefix on make install
set(PROGRAM_PREFIX    "" CACHE STRING "Program prefix on make install")

# Supported language bindings
option(BUILD_BINDINGS_JAVA   "Build Java bindings")
option(BUILD_BINDINGS_PYTHON "Build Python bindings")

#-----------------------------------------------------------------------------#
# Internal cmake variables

set(OPTIMIZATION_LEVEL 3)
set(GPL_LIBS "")

#-----------------------------------------------------------------------------#
# Determine number of threads available, used to configure (default) parallel
# execution of custom test targets (can be overriden with ARGS=-jN).

include(ProcessorCount)
ProcessorCount(CTEST_NTHREADS)
if(CTEST_NTHREADS EQUAL 0)
  set(CTEST_NTHREADS 1)
endif()

#-----------------------------------------------------------------------------#
# Build types

# Note: Module CodeCoverage requires the name of the debug build to conform
#       to cmake standards (first letter uppercase).
set(BUILD_TYPES Production Debug Testing Competition)

if(ENABLE_ASAN)
  set(CMAKE_BUILD_TYPE Debug)
endif()

# Set the default build type to Production
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE
      Production CACHE STRING "Options are: ${BUILD_TYPES}" FORCE)
  # Provide drop down menu options in cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${BUILD_TYPES})
endif()

# Check if specified build type is valid.
list(FIND BUILD_TYPES ${CMAKE_BUILD_TYPE} FOUND_BUILD_TYPE)
if(${FOUND_BUILD_TYPE} EQUAL -1)
  message(FATAL_ERROR
    "'${CMAKE_BUILD_TYPE}' is not a valid build type. "
    "Available builds are: ${BUILD_TYPES}")
endif()

message(STATUS "Building ${CMAKE_BUILD_TYPE} build")
include(Config${CMAKE_BUILD_TYPE})

#-----------------------------------------------------------------------------#
# Compiler flags

add_check_c_cxx_flag("-O${OPTIMIZATION_LEVEL}")
add_check_c_cxx_flag("-Wall")
add_check_c_flag("-fexceptions")
add_check_c_cxx_flag("-Wno-deprecated")
add_check_cxx_flag("-Wsuggest-override")
add_check_cxx_flag("-Wnon-virtual-dtor")

# Temporarily disable -Wclass-memaccess to suppress 'no trivial copy-assignment'
# cdlist.h warnings. Remove when fixed.
add_check_cxx_flag("-Wno-class-memaccess")

#-----------------------------------------------------------------------------#
# Option defaults (three-valued options (cvc4_option(...)))
#
# These options are only set if their value is IGNORE. Otherwise, the user
# already set the option, which we don't want to overwrite.

if(ENABLE_STATIC_BINARY)
  cvc4_set_option(ENABLE_SHARED OFF)
else()
  cvc4_set_option(ENABLE_SHARED ON)
endif()

#-----------------------------------------------------------------------------#
# Set options for best configuration

if(ENABLE_BEST)
  cvc4_set_option(USE_ABC ON)
  cvc4_set_option(USE_CADICAL ON)
  cvc4_set_option(USE_CLN ON)
  cvc4_set_option(USE_CRYPTOMINISAT ON)
  cvc4_set_option(USE_GLPK ON)
  cvc4_set_option(USE_READLINE ON)
endif()

# Only enable unit testing if assertions are enabled. Otherwise, unit tests
# that expect AssertionException to be thrown will fail.
if(NOT ENABLE_ASSERTIONS)
  set(ENABLE_UNIT_TESTING OFF)
endif()

# Never build unit tests as static binaries, otherwise we'll end up with
# ~300MB per unit test.
if(ENABLE_UNIT_TESTING)
  if(NOT ENABLE_SHARED)
    message(WARNING "Disabling static build since unit testing is enabled.")
  endif()
  set(ENABLE_SHARED ON)
endif()

#-----------------------------------------------------------------------------#
# Shared/static libraries
#
# This needs to be set before any find_package(...) command since we want to
# search for static libraries with suffix .a.

if(ENABLE_SHARED)
  set(BUILD_SHARED_LIBS ON)
  if(ENABLE_STATIC_BINARY)
    set(ENABLE_STATIC_BINARY OFF)
    message(WARNING "Disabling static binary since shared build is enabled.")
  endif()
else()
  set(CMAKE_FIND_LIBRARY_SUFFIXES ".a ${CMAKE_FIND_LIBRARY_SUFFIXES}")
  set(BUILD_SHARED_LIBS OFF)
  # This is required to force find_package(Boost) to use static libraries.
  set(Boost_USE_STATIC_LIBS ON)
  cvc4_set_option(ENABLE_STATIC_BINARY ON)
endif()

#-----------------------------------------------------------------------------#
# Enable the ctest testing framework

# This needs to be enabled here rather than in subdirectory test in order to
# allow calling ctest from the root build directory.
enable_testing()

#-----------------------------------------------------------------------------#
# Check GCC version.
#
# GCC version 4.5.1 builds MiniSat incorrectly with -O2, which results in
# incorrect answers.

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  execute_process(
    COMMAND ${CMAKE_CXX_COMPILER} -dumpversion
    OUTPUT_VARIABLE GCC_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(GCC_VERSION VERSION_EQUAL "4.5.1")
    message(FATAL_ERROR
      "GCC 4.5.1's optimizer is known to build MiniSat incorrectly "
      "(and by extension CVC4).")
  endif()
endif()

#-----------------------------------------------------------------------------#
# Check options, find packages and configure build.

if(USE_PYTHON2)
  find_package(PythonInterp 2.7 REQUIRED)
elseif(USE_PYTHON3)
  find_package(PythonInterp 3 REQUIRED)
else()
  find_package(PythonInterp REQUIRED)
endif()

set(GMP_HOME ${GMP_DIR})
find_package(GMP REQUIRED)

if(ENABLE_ASAN)
  # -fsanitize=address requires CMAKE_REQUIRED_FLAGS to be explicitely set,
  # otherwise the -fsanitize=address check will fail while linking.
  set(CMAKE_REQUIRED_FLAGS -fsanitize=address)
  add_required_c_cxx_flag("-fsanitize=address")
  unset(CMAKE_REQUIRED_FLAGS)
  add_required_c_cxx_flag("-fno-omit-frame-pointer")
  add_check_c_cxx_flag("-fsanitize-recover=address")
endif()

if(ENABLE_ASSERTIONS)
  add_definitions(-DCVC4_ASSERTIONS)
else()
  add_definitions(-DNDEBUG)
endif()

if(ENABLE_COVERAGE)
  include(CodeCoverage)
  APPEND_COVERAGE_COMPILER_FLAGS()
  add_definitions(-DCVC4_COVERAGE)
  # Note: The ctest command returns a non-zero exit code if tests fail or run
  # into a timeout. As a consequence, the coverage report is not generated. To
  # prevent this we always return with exit code 0 after the ctest command has
  # finished.
  setup_target_for_coverage_gcovr_html(
    NAME coverage
    EXECUTABLE
      ctest -j${CTEST_NTHREADS} -LE "example"
        --output-on-failure $(ARGS) || exit 0
    DEPENDS
      build-tests)
endif()

if(ENABLE_DEBUG_CONTEXT_MM)
  add_definitions(-DCVC4_DEBUG_CONTEXT_MEMORY_MANAGER)
endif()

if(ENABLE_DEBUG_SYMBOLS)
  add_check_c_cxx_flag("-ggdb3")
endif()

if(ENABLE_MUZZLE)
  add_definitions(-DCVC4_MUZZLE)
endif()

# This check needs to come before the USE_CLN check.
if(ENABLE_PORTFOLIO)
  find_package(Boost 1.50.0 REQUIRED COMPONENTS thread)
  if (ENABLE_DUMPING)
    message(FATAL_ERROR "Dumping not supported with a portfolio build.")
  endif()
  # Disable CLN for portfolio builds since it is not thread safe (uses an
  # unlocked hash table internally).
  if(USE_CLN)
    message(WARNING "Disabling CLN support since portfolio is enabled.")
    set(USE_CLN OFF)
  endif()
  set(THREADS_PREFER_PTHREAD_FLAG ON)
  find_package(Threads REQUIRED)
  if(THREADS_HAVE_PTHREAD_ARG)
    add_c_cxx_flag(-pthread)
  endif()
  add_definitions(-DCVC4_PORTFOLIO)
  set(BOOST_HAS_THREAD_ATTR 1)
endif()

# This has to be processed after ENABLE_PORTFOLIO (disables dumping support).
if(ENABLE_DUMPING)
  add_definitions(-DCVC4_DUMPING)
endif()

if(ENABLE_PROFILING)
  add_definitions(-DCVC4_PROFILING)
  add_check_c_cxx_flag("-pg")
endif()

if(ENABLE_PROOFS)
  set(RUN_REGRESSION_ARGS ${RUN_REGRESSION_ARGS} --enable-proof)
  add_definitions(-DCVC4_PROOF)
endif()

if(ENABLE_REPLAY)
  add_definitions(-DCVC4_REPLAY)
endif()

if(ENABLE_TRACING)
  add_definitions(-DCVC4_TRACING)
endif()

if(ENABLE_STATISTICS)
  add_definitions(-DCVC4_STATISTICS_ON)
endif()

if(ENABLE_VALGRIND)
  find_package(Valgrind REQUIRED)
  add_definitions(-DCVC4_VALGRIND)
endif()

if(USE_ABC)
  set(ABC_HOME "${ABC_DIR}")
  find_package(ABC REQUIRED)
  add_definitions(-DCVC4_USE_ABC ${ABC_ARCH_FLAGS})
endif()

if(USE_CADICAL)
  set(CaDiCaL_HOME ${CADICAL_DIR})
  find_package(CaDiCaL REQUIRED)
  add_definitions(-DCVC4_USE_CADICAL)
endif()

if(USE_CLN)
  set(GPL_LIBS "${GPL_LIBS} cln")
  find_package(CLN 1.2.2 REQUIRED)
  set(CVC4_USE_CLN_IMP 1)
  set(CVC4_USE_GMP_IMP 0)
else()
  set(CVC4_USE_CLN_IMP 0)
  set(CVC4_USE_GMP_IMP 1)
endif()

if(USE_CRYPTOMINISAT)
  # CryptoMiniSat requires pthreads support
  set(THREADS_PREFER_PTHREAD_FLAG ON)
  find_package(Threads REQUIRED)
  if(THREADS_HAVE_PTHREAD_ARG)
    add_c_cxx_flag(-pthread)
  endif()
  set(CryptoMiniSat_HOME ${CRYPTOMINISAT_DIR})
  find_package(CryptoMiniSat REQUIRED)
  add_definitions(-DCVC4_USE_CRYPTOMINISAT)
endif()

if(USE_GLPK)
  set(GPL_LIBS "${GPL_LIBS} glpk")
  set(GLPK_HOME ${GLPK_DIR})
  find_package(GLPK REQUIRED)
  add_definitions(-DCVC4_USE_GLPK)
endif()

if(USE_LFSC)
  set(RUN_REGRESSION_ARGS ${RUN_REGRESSION_ARGS} --with-lfsc)
  set(LFSC_HOME ${LFSC_DIR})
  find_package(LFSC REQUIRED)
  add_definitions(-DCVC4_USE_LFSC)
endif()

if(USE_READLINE)
  set(GPL_LIBS "${GPL_LIBS} readline")
  find_package(Readline REQUIRED)
  set(HAVE_LIBREADLINE 1)
  if(Readline_COMPENTRY_FUNC_RETURNS_CHARPTR)
    set(READLINE_COMPENTRY_FUNC_RETURNS_CHARP 1)
  endif()
endif()

if(USE_SYMFPU)
  set(SymFPU_HOME ${SYMFPU_DIR})
  find_package(SymFPU REQUIRED)
  add_definitions(-DCVC4_USE_SYMFPU)
  set(CVC4_USE_SYMFPU 1)
else()
  set(CVC4_USE_SYMFPU 0)
endif()

if(GPL_LIBS)
  if(NOT ENABLE_GPL)
    message(FATAL_ERROR
      "Bad configuration detected: BSD-licensed code only, but also requested "
      "GPLed libraries: ${GPL_LIBS}")
  endif()
  set(CVC4_GPL_DEPS 1)
endif()

#-----------------------------------------------------------------------------#
# Generate CVC4's cvc4autoconfig.h header

include(ConfigureCVC4)
configure_file(cvc4autoconfig.h.in cvc4autoconfig.h)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

#-----------------------------------------------------------------------------#
# Add subdirectories

# signatures needs to come before src since it adds source files to libcvc4.
if(ENABLE_PROOFS)
  add_subdirectory(proofs/signatures)
endif()

add_subdirectory(doc)
add_subdirectory(examples EXCLUDE_FROM_ALL)  # excluded from all target
add_subdirectory(src)
add_subdirectory(test)

if(BUILD_BINDINGS_JAVA OR BUILD_BINDINGS_PYTHON)
  add_subdirectory(src/bindings)
endif()

#-----------------------------------------------------------------------------#
# Print build configuration

# Convert build type to lower case.
string(TOLOWER ${CMAKE_BUILD_TYPE} CVC4_BUILD_PROFILE_STRING)

# Get all definitions added via add_definitions.
get_directory_property(CVC4_DEFINITIONS COMPILE_DEFINITIONS)
string(REPLACE ";" " " CVC4_DEFINITIONS "${CVC4_DEFINITIONS}")

message("CVC4 ${CVC4_RELEASE_STRING}")
message("")
message("Build profile        : ${CVC4_BUILD_PROFILE_STRING}")
message("")
print_config("GPL                  :" ENABLE_GPL)
print_config("Best configuration   :" ENABLE_BEST)
print_config("Optimized            :" ENABLE_OPTIMIZED)
print_config("Optimization level   :" OPTIMIZATION_LEVEL)
message("")
print_config("Assertions           :" ENABLE_ASSERTIONS)
print_config("Debug symbols        :" ENABLE_DEBUG_SYMBOLS)
print_config("Debug context mem mgr:" ENABLE_DEBUG_CONTEXT_MM)
message("")
print_config("Dumping              :" ENABLE_DUMPING)
print_config("Muzzle               :" ENABLE_MUZZLE)
print_config("Proofs               :" ENABLE_PROOFS)
print_config("Replay               :" ENABLE_REPLAY)
print_config("Statistics           :" ENABLE_STATISTICS)
print_config("Tracing              :" ENABLE_TRACING)
message("")
print_config("Asan                 :" ENABLE_ASAN)
print_config("Coverage (gcov)      :" ENABLE_COVERAGE)
print_config("Profiling (gprof)    :" ENABLE_PROFILING)
print_config("Unit tests           :" ENABLE_UNIT_TESTING)
print_config("Valgrind             :" ENABLE_VALGRIND)
message("")
print_config("Shared libs          :" ENABLE_SHARED)
print_config("Static binary        :" ENABLE_STATIC_BINARY)
print_config("Java bindings        :" BUILD_BINDINGS_JAVA)
print_config("Python bindings      :" BUILD_BINDINGS_PYTHON)
print_config("Python2              :" USE_PYTHON2)
print_config("Python3              :" USE_PYTHON3)
message("")
print_config("Portfolio            :" ENABLE_PORTFOLIO)
message("")
print_config("ABC                  :" USE_ABC)
print_config("CaDiCaL              :" USE_CADICAL)
print_config("CryptoMiniSat        :" USE_CRYPTOMINISAT)
print_config("GLPK                 :" USE_GLPK)
print_config("LFSC                 :" USE_LFSC)

if(CVC4_USE_CLN_IMP)
  message("MP library           : cln")
else()
  message("MP library           : gmp")
endif()
print_config("Readline             :" ${USE_READLINE})
print_config("SymFPU               :" ${USE_SYMFPU})
message("")
if(ABC_DIR)
  message("ABC dir              : ${ABC_DIR}")
endif()
if(ANTLR_DIR)
  message("ANTLR dir            : ${ANTLR_DIR}")
endif()
if(CADICAL_DIR)
  message("CADICAL dir          : ${CADICAL_DIR}")
endif()
if(CRYPTOMINISAT_DIR)
  message("CRYPTOMINISAT dir    : ${CRYPTOMINISAT_DIR}")
endif()
if(GLPK_DIR)
  message("GLPK dir             : ${GLPK_DIR}")
endif()
if(GMP_DIR)
  message("GMP dir              : ${GMP_DIR}")
endif()
if(LFSC_DIR)
  message("LFSC dir             : ${LFSC_DIR}")
endif()
if(SYMFPU_DIR)
  message("SYMFPU dir           : ${SYMFPU_DIR}")
endif()
message("")
message("CPPLAGS (-D...)      : ${CVC4_DEFINITIONS}")
message("CXXFLAGS             : ${CMAKE_CXX_FLAGS}")
message("CFLAGS               : ${CMAKE_C_FLAGS}")
message("")
message("Install prefix       : ${CMAKE_INSTALL_PREFIX}")
message("")

if(GPL_LIBS)
  message(
  "CVC4 license         : GPLv3 (due to optional libraries; see below)"
  "\n"
  "\n"
  "Please note that CVC4 will be built against the following GPLed libraries:"
  "\n"
  "${GPL_LIBS}"
  "\n"
  "As these libraries are covered under the GPLv3, so is this build of CVC4."
  "\n"
  "CVC4 is also available to you under the terms of the (modified) BSD license."
  "\n"
  "If you prefer to license CVC4 under those terms, please configure CVC4 to"
  "\n"
  "disable all optional GPLed library dependencies (-DENABLE_BSD_ONLY=ON)."
  )
else()
  message(
  "CVC4 license         : modified BSD"
  "\n"
  "\n"
  "Note that this configuration is NOT built against any GPL'ed libraries, so"
  "\n"
  "it is covered by the (modified) BSD license.  This is, however, not the best"
  "\n"
  "performing configuration of CVC4.  To build against GPL'ed libraries which"
  "\n"
  "improve CVC4's performance, re-configure with '-DENABLE_GPL -DENABLE_BEST'."
  )
endif()

message("")
message("Now just type make, followed by make check or make install.")
message("")
