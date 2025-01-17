# - Try to find the OpenSSL encryption library
# Once done this will define
#
#  OPENSSL_ROOT_DIR - Set this variable to the root installation of OpenSSL
#
# Read-Only variables:
#  OPENSSL_FOUND - system has the OpenSSL library
#  OPENSSL_INCLUDE_DIR - the OpenSSL include directory
#  OPENSSL_LIBRARIES - The libraries needed to use OpenSSL

#=============================================================================
# Copyright 2006-2009 Kitware, Inc.
# Copyright 2006 Alexander Neundorf <neundorf@kde.org>
# Copyright 2009-2010 Mathieu Malaterre <mathieu.malaterre@gmail.com>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distributed this file outside of CMake, substitute the full
#  License text for the above reference.)

# http://www.slproweb.com/products/Win32OpenSSL.html

set(OPENSSL_EXPECTED_VERSION "1.0")
set(OPENSSL_MAX_VERSION "1.2")

SET(_OPENSSL_ROOT_HINTS
  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenSSL (32-bit)_is1;Inno Setup: App Path]"
  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenSSL (64-bit)_is1;Inno Setup: App Path]"
  )

set(_OPENSSL_MSI_INSTALL_GUID "")

IF(PLATFORM EQUAL 64)
  set(_OPENSSL_MSI_INSTALL_GUID "117551DB-A110-4BBD-BB05-CFE0BCB3ED31")
  SET(_OPENSSL_ROOT_PATHS
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenSSL (64-bit)_is1;InstallLocation]"
    "C:/OpenSSL-Win64/"
    "C:/OpenSSL/"
  )
ELSE()
  set(_OPENSSL_MSI_INSTALL_GUID "A1EEC576-43B9-4E75-9E02-03DA542D2A38")
  SET(_OPENSSL_ROOT_PATHS
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenSSL (32-bit)_is1;InstallLocation]"
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OpenSSL (32-bit)_is1;InstallLocation]"
    "C:/OpenSSL/"
  )
ENDIF()

# If OpenSSL was installed using .msi package instead of .exe, Inno Setup registry values are not written to Uninstall\OpenSSL
# but because it is only a shim around Inno Setup it does write the location of uninstaller which we can use to determine path
get_filename_component(_OPENSSL_MSI_INSTALL_PATH "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Inno Setup MSIs\\${_OPENSSL_MSI_INSTALL_GUID};]" DIRECTORY)
if(NOT _OPENSSL_MSI_INSTALL_PATH STREQUAL "/")
  list(APPEND _OPENSSL_ROOT_PATHS ${_OPENSSL_MSI_INSTALL_PATH})
endif()

FIND_PATH(OPENSSL_ROOT_DIR
  NAMES
    include/openssl/ssl.h
  HINTS
    ${_OPENSSL_ROOT_HINTS}
  PATHS
    ${_OPENSSL_ROOT_PATHS}
)
MARK_AS_ADVANCED(OPENSSL_ROOT_DIR)

# Re-use the previous path:
FIND_PATH(OPENSSL_INCLUDE_DIR openssl/ssl.h
  ${OPENSSL_ROOT_DIR}/include
)

IF(WIN32 AND NOT CYGWIN)
  # MINGW should go here too
  IF(MSVC)
    # /MD and /MDd are the standard values - if someone wants to use
    # others, the libnames have to change here too
    # use also ssl and ssleay32 in debug as fallback for openssl < 0.9.8b
    # TODO: handle /MT and static lib
    # In Visual C++ naming convention each of these four kinds of Windows libraries has it's standard suffix:
    #   * MD for dynamic-release
    #   * MDd for dynamic-debug
    #   * MT for static-release
    #   * MTd for static-debug

    # Implementation details:
    # We are using the libraries located in the VC subdir instead of the parent directory eventhough :
    # libeay32MD.lib is identical to ../libeay32.lib, and
    # ssleay32MD.lib is identical to ../ssleay32.lib

    # Since OpenSSL 1.1, lib names are like libcrypto32MTd.lib and libssl32MTd.lib
    if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "8")
        set(_OPENSSL_MSVC_ARCH_SUFFIX "64")
    else()
        set(_OPENSSL_MSVC_ARCH_SUFFIX "32")
    endif()

    FIND_LIBRARY(LIB_EAY_DEBUG
      NAMES
        libcrypto${_OPENSSL_MSVC_ARCH_SUFFIX}MDd libeay32MDd libeay32
      PATHS
        ${OPENSSL_ROOT_DIR}/lib/VC
    )

    FIND_LIBRARY(LIB_EAY_RELEASE
      NAMES
        libcrypto${_OPENSSL_MSVC_ARCH_SUFFIX}MD libeay32MD libeay32
      PATHS
        ${OPENSSL_ROOT_DIR}/lib/VC
    )

    FIND_LIBRARY(SSL_EAY_DEBUG
      NAMES
        libssl${_OPENSSL_MSVC_ARCH_SUFFIX}MDd ssleay32MDd ssleay32 ssl
      PATHS
        ${OPENSSL_ROOT_DIR}/lib/VC
    )

    FIND_LIBRARY(SSL_EAY_RELEASE
      NAMES
        libssl${_OPENSSL_MSVC_ARCH_SUFFIX}MD ssleay32MD ssleay32 ssl
      PATHS
        ${OPENSSL_ROOT_DIR}/lib/VC
    )

    if(CMAKE_CONFIGURATION_TYPES OR CMAKE_BUILD_TYPE)
      set(OPENSSL_LIBRARIES
        optimized ${SSL_EAY_RELEASE} ${LIB_EAY_RELEASE}
        debug ${SSL_EAY_DEBUG} ${LIB_EAY_DEBUG}
      )
    else()
      set(OPENSSL_LIBRARIES
        ${SSL_EAY_RELEASE}
        ${LIB_EAY_RELEASE}
      )
    endif()

    MARK_AS_ADVANCED(SSL_EAY_DEBUG SSL_EAY_RELEASE LIB_EAY_DEBUG LIB_EAY_RELEASE)
  ELSEIF(MINGW)

    # same player, for MingW
    FIND_LIBRARY(LIB_EAY
      NAMES
        libeay32
      PATHS
        ${OPENSSL_ROOT_DIR}/lib/MinGW
    )

    FIND_LIBRARY(SSL_EAY NAMES
      NAMES
        ssleay32
      PATHS
        ${OPENSSL_ROOT_DIR}/lib/MinGW
    )

    MARK_AS_ADVANCED(SSL_EAY LIB_EAY)

    set(OPENSSL_LIBRARIES
      ${SSL_EAY}
      ${LIB_EAY}
    )
  ELSE(MSVC)
    # Not sure what to pick for -say- intel, let's use the toplevel ones and hope someone report issues:
    FIND_LIBRARY(LIB_EAY
      NAMES
        libeay32
      PATHS
        ${OPENSSL_ROOT_DIR}/lib
        ${OPENSSL_ROOT_DIR}/lib/VC
    )

    FIND_LIBRARY(SSL_EAY
      NAMES
        ssleay32
      PATHS
        ${OPENSSL_ROOT_DIR}/lib
        ${OPENSSL_ROOT_DIR}/lib/VC
    )
    MARK_AS_ADVANCED(SSL_EAY LIB_EAY)

    SET(OPENSSL_LIBRARIES ${SSL_EAY} ${LIB_EAY})
  ENDIF(MSVC)
ELSE(WIN32 AND NOT CYGWIN)
  FIND_LIBRARY(OPENSSL_SSL_LIBRARIES NAMES ssl ssleay32 ssleay32MD)
  FIND_LIBRARY(OPENSSL_CRYPTO_LIBRARIES NAMES crypto)
  MARK_AS_ADVANCED(OPENSSL_CRYPTO_LIBRARIES OPENSSL_SSL_LIBRARIES)

  SET(OPENSSL_LIBRARIES ${OPENSSL_SSL_LIBRARIES} ${OPENSSL_CRYPTO_LIBRARIES})

ENDIF(WIN32 AND NOT CYGWIN)

if(NOT OPENSSL_INCLUDE_DIR)
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(OpenSSL DEFAULT_MSG
    OPENSSL_LIBRARIES
    OPENSSL_INCLUDE_DIR
  )
endif()
function(from_hex HEX DEC)
  string(TOUPPER "${HEX}" HEX)
  set(_res 0)
  string(LENGTH "${HEX}" _strlen)

  while (_strlen GREATER 0)
    math(EXPR _res "${_res} * 16")
    string(SUBSTRING "${HEX}" 0 1 NIBBLE) 
    string(SUBSTRING "${HEX}" 1 -1 HEX) 
    if (NIBBLE STREQUAL "A")
      math(EXPR _res "${_res} + 10")
    elseif (NIBBLE STREQUAL "B")
      math(EXPR _res "${_res} + 11")
    elseif (NIBBLE STREQUAL "C")
      math(EXPR _res "${_res} + 12")
    elseif (NIBBLE STREQUAL "D")
      math(EXPR _res "${_res} + 13")
    elseif (NIBBLE STREQUAL "E")
      math(EXPR _res "${_res} + 14")
    elseif (NIBBLE STREQUAL "F")
      math(EXPR _res "${_res} + 15")
    else()  
      math(EXPR _res "${_res} + ${NIBBLE}")
    endif() 

    string(LENGTH "${HEX}" _strlen)
  endwhile()

  set(${DEC} ${_res} PARENT_SCOPE)
endfunction(from_hex)

if(OPENSSL_INCLUDE_DIR)
  message(STATUS "Found OpenSSL library: ${OPENSSL_LIBRARIES}")
  message(STATUS "Found OpenSSL headers: ${OPENSSL_INCLUDE_DIR}")
  if(_OPENSSL_VERSION)
    set(OPENSSL_VERSION "${_OPENSSL_VERSION}")
  else(_OPENSSL_VERSION)
    file(STRINGS "${OPENSSL_INCLUDE_DIR}/openssl/opensslv.h" openssl_version_str
         REGEX "^# *define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x[0-9][0-9][0-9][0-9][0-9][0-9].*")

    # The version number is encoded as 0xMNNFFPPS: major minor fix patch status
    # The status gives if this is a developer or prerelease and is ignored here.
    # Major, minor, and fix directly translate into the version numbers shown in
    # the string. The patch field translates to the single character suffix that
    # indicates the bug fix state, which 00 -> nothing, 01 -> a, 02 -> b and so
    # on.

    string(REGEX REPLACE "^.*OPENSSL_VERSION_NUMBER[\t ]+0x([0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f]).*$"
           "\\1;\\2;\\3;\\4;\\5" OPENSSL_VERSION_LIST "${openssl_version_str}")
    list(GET OPENSSL_VERSION_LIST 0 OPENSSL_VERSION_MAJOR)
    list(GET OPENSSL_VERSION_LIST 1 OPENSSL_VERSION_MINOR)
    from_hex("${OPENSSL_VERSION_MINOR}" OPENSSL_VERSION_MINOR)
    list(GET OPENSSL_VERSION_LIST 2 OPENSSL_VERSION_FIX)
    from_hex("${OPENSSL_VERSION_FIX}" OPENSSL_VERSION_FIX)
    list(GET OPENSSL_VERSION_LIST 3 OPENSSL_VERSION_PATCH)

    string(REGEX REPLACE "^0(.)" "\\1" OPENSSL_VERSION_MINOR "${OPENSSL_VERSION_MINOR}")
    string(REGEX REPLACE "^0(.)" "\\1" OPENSSL_VERSION_FIX "${OPENSSL_VERSION_FIX}")

    if(NOT OPENSSL_VERSION_PATCH STREQUAL "00")
      from_hex("${OPENSSL_VERSION_PATCH}" _tmp)
      # 96 is the ASCII code of 'a' minus 1
      math(EXPR OPENSSL_VERSION_PATCH_ASCII "${_tmp} + 96")
      unset(_tmp)
      # Once anyone knows how OpenSSL would call the patch versions beyond 'z'
      # this should be updated to handle that, too. This has not happened yet
      # so it is simply ignored here for now.
      string(ASCII "${OPENSSL_VERSION_PATCH_ASCII}" OPENSSL_VERSION_PATCH_STRING)
    endif(NOT OPENSSL_VERSION_PATCH STREQUAL "00")

    set(OPENSSL_VERSION "${OPENSSL_VERSION_MAJOR}.${OPENSSL_VERSION_MINOR}.${OPENSSL_VERSION_FIX}${OPENSSL_VERSION_PATCH_STRING}")
  endif(_OPENSSL_VERSION)

  include(EnsureVersion)
  ENSURE_VERSION_RANGE("${OPENSSL_EXPECTED_VERSION}" "${OPENSSL_VERSION}" "${OPENSSL_MAX_VERSION}" OPENSSL_VERSION_OK)
  if(NOT OPENSSL_VERSION_OK)
      message(FATAL_ERROR "TrinityCore needs OpenSSL version ${OPENSSL_EXPECTED_VERSION} but found too new version ${OPENSSL_VERSION}. TrinityCore needs OpenSSL 1.0.x or 1.1.x to work properly. If you still have problems please install OpenSSL 1.0.x if you still have problems search on forum for TCE00022")
  endif()
endif(OPENSSL_INCLUDE_DIR)

MARK_AS_ADVANCED(OPENSSL_INCLUDE_DIR OPENSSL_LIBRARIES)
