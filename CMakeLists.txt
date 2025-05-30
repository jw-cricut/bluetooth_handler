file(GLOB BLUETOOTH_HANDLER_SRC "*.cpp")
add_library(bluetooth_handler STATIC ${BLUETOOTH_HANDLER_SRC})

target_include_directories(bluetooth_handler PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

