cmake_minimum_required(VERSION 2.8)
project(ObjectiveGitFramework)

add_custom_target(
    libgit2.a 
    COMMAND scripts/update_libgit2.sh
    COMMAND cp ${ObjectiveGitFramework_SOURCE_DIR}/libgit2.a ${CMAKE_BINARY_DIR} 
    WORKING_DIRECTORY ${ObjectiveGitFramework_SOURCE_DIR}
    COMMENT "Updating libgit2..."
)

# Collect sourcefiles
file(GLOB_RECURSE SRC Classes/*.m)
file(GLOB_RECURSE SRC_H Classes/*.h)

set(XCODE_FRAMEWORKS /Applications/Xcode.app/Contents/Developer/Library/Frameworks/)

set(CMAKE_C_COMPILER   "clang")    #minimum required version clang 3.2
set(CMAKE_CXX_COMPILER "clang++")  #minimum required version clang 3.2

set(CMAKE_CXX_FLAGS "")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fconstant-string-class=NSConstantString")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fmessage-length=0")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fblocks")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fobjc-arc")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fasm-blocks")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -include ${ObjectiveGitFramework_SOURCE_DIR}/ObjectiveGitFramework_Prefix.pch")


# CpHeaders into build dir ---------------------------------------------------# 
set(HEADER_DIR ${ObjectiveGitFramework_BINARY_DIR}/Headers)

execute_process (
    COMMAND ${CMAKE_COMMAND} -E make_directory ${HEADER_DIR} 
    COMMAND ${CMAKE_COMMAND} -E make_directory ${HEADER_DIR}/ObjectiveGit 
)

execute_process(
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${ObjectiveGitFramework_SOURCE_DIR}/libgit2/include ${HEADER_DIR} 
)

foreach(header ${SRC_H})
    execute_process (
        COMMAND ${CMAKE_COMMAND} -E copy ${header} ${HEADER_DIR}/ObjectiveGit
    )
endforeach()


# Create library ObjectiveGit ------------------------------------------------#
add_library(ObjectiveGit SHARED ${SRC})
set_target_properties(
    ObjectiveGit 
    PROPERTIES PREFIX 
    ""
)

include_directories(
    Classes 
    Classes/Categories/ 
    libgit2/include 
    ${HEADER_DIR}
)

target_link_libraries(
    ObjectiveGit
    "-framework Foundation"
    z ssl crypto "${CMAKE_BINARY_DIR}/libgit2.a"
)

add_dependencies(ObjectiveGit libgit2.a)
