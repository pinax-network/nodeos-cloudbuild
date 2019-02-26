find_package(eosio.cdt)

cmake_minimum_required(VERSION 3.5)
project(battlefield VERSION 9.0.0)

add_contract(battlefield battlefield src/battlefield.cpp)

target_include_directories(battlefield.wasm PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_custom_command(TARGET battlefield.wasm POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:battlefield.wasm> "${CMAKE_CURRENT_SOURCE_DIR}/battlefield.wasm"
)

add_custom_command(TARGET battlefield.wasm POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_BINARY_DIR}/battlefield.abi" "${CMAKE_CURRENT_SOURCE_DIR}/battlefield.abi"
)