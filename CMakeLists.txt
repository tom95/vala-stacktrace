cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
include (GraniteMVC)

granite_mvc_add_library (vala-stacktrace public 0.1 0.1
	EXTRA_DEPS
		gee-0.8
	EXTRA_VALA_LIBRARIES
		linux
		posix
	NO_GRANITE
)

set (TEST_VALA_FLAGS
	-g
	--vapidir=${CMAKE_BINARY_DIR})

set (TEST_C_FLAGS
	-ggdb
	-rdynamic)

add_definitions (${TEST_C_FLAGS})
link_directories (${CMAKE_BINARY_DIR})

pkg_check_modules (TEST_DEPS REQUIRED glib-2.0 gee-0.8)

link_directories (${TEST_DEPS_LIBRARY_DIRS})
add_definitions (${TEST_DEPS_CFLAGS})

set (segv_sources "samples/error_sigsegv.vala samples/vala_file.vala samples/module/OtherModule.vala")
set (tests "samples/error_colors.vala" "samples/error_sigabrt.vala" "samples/error_sigtrap.vala")
list (APPEND tests ${segv_sources})

foreach (test ${tests})
	string (REPLACE " " ";" test ${test})
	list (GET test 0 target)
	get_filename_component (target ${target} NAME)
	string (REPLACE ".vala" "" target ${target})
	message(${target})

	vala_precompile(vala_c ${target} ${test}
		PACKAGES vala-stacktrace
		OPTIONS ${TEST_VALA_FLAGS})

	add_executable (${target} ${vala_c})
	target_link_libraries (${target} vala-stacktrace)
endforeach()

