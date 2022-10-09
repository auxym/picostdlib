cmake_minimum_required(VERSION 3.13)

# initialize pico-sdk from GIT
# (note this can come from environment, CMake cache etc)
#set(PICO_SDK_FETCH_FROM_GIT on)

# pico_sdk_import.cmake is a single file copied from this SDK
# note: this must happen before project()
include(pico_sdk_import.cmake)

project(usb_hid_cdc)
# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

set(Imports imports.cmake)

if(EXISTS "../${Imports}")

# add program file(s)
file(GLOB NimSources build/nimcache/*.c)

# Suppress gcc warnings for nim-generated files
set_source_files_properties(${NimSources} PROPERTIES COMPILE_OPTIONS "-w")

add_executable(usb_hid_cdc ${NimSources})
target_include_directories(usb_hid_cdc PUBLIC ${CMAKE_CURRENT_LIST_DIR}/build/nimcache)

# Add directory containing this CMakeLists file to include search path.
# This is required so that the nimbase.h file is found. Other headers
# required for a project can also be placed here.
target_include_directories(usb_hid_cdc PUBLIC ${CMAKE_CURRENT_LIST_DIR})
target_link_libraries(usb_hid_cdc tinyusb_board tinyusb_device)

include(${Imports}) # Include our generated file
link_imported_libs(usb_hid_cdc) # call our generated function to import all libs we're using

# disable default usb output, since we are implementing our own USB device
pico_enable_stdio_usb(usb_hid_cdc 0)
pico_enable_stdio_uart(usb_hid_cdc 0)

# create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(usb_hid_cdc)

# add url via pico_set_program_url
pico_set_program_url(usb_hid_cdc 1)
endif()

