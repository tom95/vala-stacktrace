
find_package (PkgConfig REQUIRED)
find_package (Vala REQUIRED)

include (ParseArguments)
include (ValaVersion)
include (ValaPrecompile)
include (GNUInstallDirs)

macro (granite_mvc_project project_name) 
	project (${project_name} C)

	parse_arguments (ARGS "EXTRA_OPTIONS;EXTRA_LIBRARIES;EXTRA_DEPS;EXTRA_SOURCES;GETTEXT_PACKAGE;VALA_VERSION" "" ${ARGN})

	# gettext package, fallback to project name
	if (ARGS_GETTEXT_PACKAGE)
		set (gettext_package ${ARGS_GETTEXT_PACKAGE})
	else(ARGS_GETTEXT_PACKAGE)
		set (gettext_package ${project_name})
	endif(ARGS_GETTEXT_PACKAGE)

	# minimal vala version, default to 0.22
	if (ARGS_VALA_VERSION)
		ensure_vala_version (${ARGS_VALA_VERSION} MINIMUM)
	else (ARGS_VALA_VERSION)
		ensure_vala_version ("0.22" MINIMUM)
	endif (ARGS_VALA_VERSION)

	# sources, every vala and vapi in src/
	file (GLOB_RECURSE sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} src/*.vala src/*.vapi)
	set (sources ${sources} ${ARGS_EXTRA_SOURCES})

	# options for valac, vapidir is set to vapi/ by default
	set (vala_options --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi --vapidir=${CMAKE_BINARY_DIR} ${ARGS_EXTRA_OPTIONS})

	# required packages, granite is added by default
	set (deps granite ${ARGS_EXTRA_DEPS})

	pkg_check_modules (DEPS REQUIRED ${deps})
	vala_precompile (vala_c ${project_name} ${sources} PACKAGES ${deps} ${ARGS_EXTRA_LIBRARIES} OPTIONS ${vala_options})

	add_executable (${project_name} ${vala_c})

	set_target_properties (${project_name} PROPERTIES
		COMPILE_OPTIONS "${DEPS_CFLAGS}"
		COMPILE_DEFINITIONS "GETTEXT_PACKAGE=\"${gettext_package}\"")
	target_link_libraries (${project_name} m ${DEPS_LIBRARIES} ${ARGS_EXTRA_LIBRARIES})

	install (TARGETS ${project_name} RUNTIME DESTINATION bin)
endmacro()

macro (granite_mvc_add_settings settings)
	include (GSettings)
	add_schema (${ARGS_GSETTINGS})
endmacro (granite_mvc_add_settings)

macro (granite_mvc_add_library library_name type version so_version)
	parse_arguments (ARGS "EXTRA_OPTIONS;EXTRA_LIBRARIES;EXTRA_DEPS;EXTRA_SOURCES;GETTEXT_PACKAGE;VALA_VERSION;DESCRIPTION;NO_GRANITE;EXTRA_VALA_LIBRARIES" "" ${ARGN})

	# gettext package, fallback to project name
	if (ARGS_GETTEXT_PACKAGE)
		set (gettext_package ${ARGS_GETTEXT_PACKAGE})
	else(ARGS_GETTEXT_PACKAGE)
		set (gettext_package ${project_name})
	endif(ARGS_GETTEXT_PACKAGE)

	# sources, every vala and vapi in src/
	file (GLOB_RECURSE sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${library_name}/*.vala ${library_name}/*.vapi)
	set (sources ${sources} ${ARGS_EXTRA_SOURCES})

	# options for valac, vapidir is set to vapi/ by default
	set (vala_options --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi ${ARGS_EXTRA_OPTIONS})

	# required packages, granite is added by default unless otherwise requested
	if (ARGS_NO_GRANITE)
		set (deps ${ARGS_EXTRA_DEPS})
	else(ARGS_NO_GRANITE)
		set (deps granite ${ARGS_EXTRA_DEPS})
	endif(ARGS_NO_GRANITE)

	pkg_check_modules (DEPS REQUIRED ${deps})
	vala_precompile (vala_c ${library_name} ${sources}
		PACKAGES ${deps} ${ARGS_EXTRA_LIBRARIES} ${ARGS_EXTRA_VALA_LIBRARIES}
		OPTIONS ${vala_options}
		GENERATE_VAPI ${library_name}
		GENERATE_HEADER ${library_name})

	file (WRITE ${CMAKE_BINARY_DIR}/${library_name}.pc
		"prefix=${CMAKE_INSTALL_PREFIX}\n"
		"exec_prefix=\${prefix}\n"
		"libdir=${CMAKE_INSTALL_FULL_LIBDIR}\n"
		"includedir=\${prefix}/include/\n"
		"\n"
		"Name: ${library_name}\n"
		"Description: ${ARGS_DESCRIPTION}\n"
		"Version: ${version}\n"
		"Libs: -L\${libdir} -l${library_name}\n"
		"Cflags: -I\${includedir}/${library_name}\n"
		"Requires: ${deps}")

	string (REPLACE ";" "\n" depslist "${deps};${VALA_EXTRA_VALA_LIBRARIES}")
	file (WRITE ${CMAKE_BINARY_DIR}/${library_name}.deps
		${depslist})

	if ("${type}" STREQUAL "public")
		add_library (${library_name} SHARED ${vala_c})
		install (TARGETS ${library_name} DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})
		install (FILES ${CMAKE_BINARY_DIR}/${library_name}.vapi DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi)
		install (FILES ${CMAKE_BINARY_DIR}/${library_name}.pc DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig/)
		install (FILES ${CMAKE_BINARY_DIR}/${library_name}.deps DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
		install (FILES ${CMAKE_BINARY_DIR}/${library_name}.h DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/${library_name}/)
	else ()
		add_library (${library_name} STATIC ${vala_c})
	endif ()

	set_target_properties (${library_name} PROPERTIES
		COMPILE_OPTIONS "${DEPS_CFLAGS} -DGETTEXT_PACKAGE=\"${gettext_package}}\""
		VERSION ${version}
		SOVERSION ${so_version})
	target_link_libraries (${library_name} m ${ARGS_EXTRA_LIBRARIES} ${DEPS_LIBRARIES})

endmacro (granite_mvc_add_library)

