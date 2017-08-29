# Minimal version of CMake
cmake_minimum_required (VERSION 2.6)

include(GNUInstallDirs)

# Define project name
project (loafr)

# Set up directory with 3rd party cmake modules
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

include(systemd)

# The version number
set (${PROJECT_NAME}_VERSION_MAJOR 1)
set (${PROJECT_NAME}_VERSION_MINOR 0)
set (${PROJECT_NAME}_PATCH_LEVEL 0)

set (${PROJECT_NAME}_VERSION "${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}")


configure_file(${CMAKE_SOURCE_DIR}/loafrd.service.in
  ${CMAKE_BINARY_DIR}/loafrd.service
  @ONLY)

if (SYSTEMD_FOUND)
  install(FILES ${CMAKE_BINARY_DIR}/loafrd.service DESTINATION
    ${SYSTEMD_SERVICES_INSTALL_DIR}
    )
endif()

install(PROGRAMS loafrc.sh
  DESTINATION ${CMAKE_INSTALL_BINDIR}
  )

install(PROGRAMS loafrd.sh
  DESTINATION ${CMAKE_INSTALL_BINDIR}
  )


