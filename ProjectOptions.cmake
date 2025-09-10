include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(LearnCppBestPractice_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(LearnCppBestPractice_setup_options)
  option(LearnCppBestPractice_ENABLE_HARDENING "Enable hardening" ON)
  option(LearnCppBestPractice_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    LearnCppBestPractice_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    LearnCppBestPractice_ENABLE_HARDENING
    OFF)

  LearnCppBestPractice_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR LearnCppBestPractice_PACKAGING_MAINTAINER_MODE)
    option(LearnCppBestPractice_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(LearnCppBestPractice_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(LearnCppBestPractice_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(LearnCppBestPractice_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(LearnCppBestPractice_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(LearnCppBestPractice_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(LearnCppBestPractice_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(LearnCppBestPractice_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(LearnCppBestPractice_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(LearnCppBestPractice_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(LearnCppBestPractice_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(LearnCppBestPractice_ENABLE_PCH "Enable precompiled headers" OFF)
    option(LearnCppBestPractice_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(LearnCppBestPractice_ENABLE_IPO "Enable IPO/LTO" ON)
    option(LearnCppBestPractice_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(LearnCppBestPractice_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(LearnCppBestPractice_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(LearnCppBestPractice_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(LearnCppBestPractice_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(LearnCppBestPractice_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(LearnCppBestPractice_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(LearnCppBestPractice_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(LearnCppBestPractice_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(LearnCppBestPractice_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(LearnCppBestPractice_ENABLE_PCH "Enable precompiled headers" OFF)
    option(LearnCppBestPractice_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      LearnCppBestPractice_ENABLE_IPO
      LearnCppBestPractice_WARNINGS_AS_ERRORS
      LearnCppBestPractice_ENABLE_USER_LINKER
      LearnCppBestPractice_ENABLE_SANITIZER_ADDRESS
      LearnCppBestPractice_ENABLE_SANITIZER_LEAK
      LearnCppBestPractice_ENABLE_SANITIZER_UNDEFINED
      LearnCppBestPractice_ENABLE_SANITIZER_THREAD
      LearnCppBestPractice_ENABLE_SANITIZER_MEMORY
      LearnCppBestPractice_ENABLE_UNITY_BUILD
      LearnCppBestPractice_ENABLE_CLANG_TIDY
      LearnCppBestPractice_ENABLE_CPPCHECK
      LearnCppBestPractice_ENABLE_COVERAGE
      LearnCppBestPractice_ENABLE_PCH
      LearnCppBestPractice_ENABLE_CACHE)
  endif()

  LearnCppBestPractice_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (LearnCppBestPractice_ENABLE_SANITIZER_ADDRESS OR LearnCppBestPractice_ENABLE_SANITIZER_THREAD OR LearnCppBestPractice_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(LearnCppBestPractice_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(LearnCppBestPractice_global_options)
  if(LearnCppBestPractice_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    LearnCppBestPractice_enable_ipo()
  endif()

  LearnCppBestPractice_supports_sanitizers()

  if(LearnCppBestPractice_ENABLE_HARDENING AND LearnCppBestPractice_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR LearnCppBestPractice_ENABLE_SANITIZER_UNDEFINED
       OR LearnCppBestPractice_ENABLE_SANITIZER_ADDRESS
       OR LearnCppBestPractice_ENABLE_SANITIZER_THREAD
       OR LearnCppBestPractice_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${LearnCppBestPractice_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${LearnCppBestPractice_ENABLE_SANITIZER_UNDEFINED}")
    LearnCppBestPractice_enable_hardening(LearnCppBestPractice_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(LearnCppBestPractice_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(LearnCppBestPractice_warnings INTERFACE)
  add_library(LearnCppBestPractice_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  LearnCppBestPractice_set_project_warnings(
    LearnCppBestPractice_warnings
    ${LearnCppBestPractice_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(LearnCppBestPractice_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    LearnCppBestPractice_configure_linker(LearnCppBestPractice_options)
  endif()

  include(cmake/Sanitizers.cmake)
  LearnCppBestPractice_enable_sanitizers(
    LearnCppBestPractice_options
    ${LearnCppBestPractice_ENABLE_SANITIZER_ADDRESS}
    ${LearnCppBestPractice_ENABLE_SANITIZER_LEAK}
    ${LearnCppBestPractice_ENABLE_SANITIZER_UNDEFINED}
    ${LearnCppBestPractice_ENABLE_SANITIZER_THREAD}
    ${LearnCppBestPractice_ENABLE_SANITIZER_MEMORY})

  set_target_properties(LearnCppBestPractice_options PROPERTIES UNITY_BUILD ${LearnCppBestPractice_ENABLE_UNITY_BUILD})

  if(LearnCppBestPractice_ENABLE_PCH)
    target_precompile_headers(
      LearnCppBestPractice_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(LearnCppBestPractice_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    LearnCppBestPractice_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(LearnCppBestPractice_ENABLE_CLANG_TIDY)
    LearnCppBestPractice_enable_clang_tidy(LearnCppBestPractice_options ${LearnCppBestPractice_WARNINGS_AS_ERRORS})
  endif()

  if(LearnCppBestPractice_ENABLE_CPPCHECK)
    LearnCppBestPractice_enable_cppcheck(${LearnCppBestPractice_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(LearnCppBestPractice_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    LearnCppBestPractice_enable_coverage(LearnCppBestPractice_options)
  endif()

  if(LearnCppBestPractice_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(LearnCppBestPractice_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(LearnCppBestPractice_ENABLE_HARDENING AND NOT LearnCppBestPractice_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR LearnCppBestPractice_ENABLE_SANITIZER_UNDEFINED
       OR LearnCppBestPractice_ENABLE_SANITIZER_ADDRESS
       OR LearnCppBestPractice_ENABLE_SANITIZER_THREAD
       OR LearnCppBestPractice_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    LearnCppBestPractice_enable_hardening(LearnCppBestPractice_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
