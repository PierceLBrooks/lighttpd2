
IF(NOT RAGEL_EXECUTABLE)
	MESSAGE(STATUS "Looking for ragel")
	FIND_PROGRAM(RAGEL_EXECUTABLE ragel)
	IF(RAGEL_EXECUTABLE)
		EXECUTE_PROCESS(COMMAND "${RAGEL_EXECUTABLE}" -v OUTPUT_VARIABLE _version)
		STRING(REGEX MATCH "[0-9.]+" RAGEL_VERSION ${_version})
		SET(RAGEL_FOUND TRUE)
	ENDIF(RAGEL_EXECUTABLE)
ELSE(NOT RAGEL_EXECUTABLE)
  MACRO(STRING_UNQUOTE var str)
    # ';' and '\' are tricky, need to be encoded.
    # '\' => '#B'
    # '#' => '#H'
    # ';' => '#S'
    STRING(REGEX REPLACE "#" "#H" _ret "${str}")
    STRING(REGEX REPLACE "\\\\" "#B" _ret "${_ret}")
    STRING(REGEX REPLACE ";" "#S" _ret "${_ret}")

    IF(_ret MATCHES "^[ \t\r\n]+")
        STRING(REGEX REPLACE "^[ \t\r\n]+" "" _ret "${_ret}")
    ENDIF(_ret MATCHES "^[ \t\r\n]+")
    IF(_ret MATCHES "^\"")
        # Double quote
        STRING(REGEX REPLACE "\"\(.*\)\"[ \t\r\n]*$" "\\1" _ret "${_ret}")
    ELSEIF(_ret MATCHES "^'")
        # Single quote
        STRING(REGEX REPLACE "'\(.*\)'[ \t\r\n]*$" "\\1" _ret "${_ret}")
    ELSE(_ret MATCHES "^\"")
        SET(_ret "")
    ENDIF(_ret MATCHES "^\"")

    # Unencoding
    STRING(REGEX REPLACE "#B" "\\\\" _ret "${_ret}")
    STRING(REGEX REPLACE "#H" "#" _ret "${_ret}")
    STRING(REGEX REPLACE "#S" "\\\\;" ${var} "${_ret}")
  ENDMACRO(STRING_UNQUOTE var str)
  
  STRING_UNQUOTE(RAGEL_EXECUTABLE "${RAGEL_EXECUTABLE}")
	EXECUTE_PROCESS(COMMAND "${RAGEL_EXECUTABLE}" -v OUTPUT_VARIABLE _version)
	STRING(REGEX MATCH "[0-9.]+" RAGEL_VERSION ${_version})
	SET(RAGEL_FOUND TRUE)
ENDIF(NOT RAGEL_EXECUTABLE)

IF(RAGEL_FOUND)  
	IF (NOT Ragel_FIND_QUIETLY)
		MESSAGE(STATUS "Found ragel: ${RAGEL_EXECUTABLE} (${RAGEL_VERSION})")
	ENDIF (NOT Ragel_FIND_QUIETLY)

	IF(NOT RAGEL_FLAGS)
		SET(RAGEL_FLAGS "-T1")
	ENDIF(NOT RAGEL_FLAGS)

	MACRO(RAGEL_PARSER SRCFILE)
		GET_FILENAME_COMPONENT(SRCPATH "${SRCFILE}" PATH)
		GET_FILENAME_COMPONENT(SRCBASE "${SRCFILE}" NAME_WE)
		SET(OUTFILE "${CMAKE_CURRENT_BINARY_DIR}/${SRCPATH}/${SRCBASE}.c")
		FILE(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${SRCPATH}")
		SET(INFILE "${CMAKE_CURRENT_SOURCE_DIR}/${SRCFILE}")
		SET(_flags ${ARGV1})
		IF(NOT _flags)
			SET(_flags ${RAGEL_FLAGS})
		ENDIF(NOT _flags)
		ADD_CUSTOM_COMMAND(OUTPUT ${OUTFILE}
			COMMAND "${RAGEL_EXECUTABLE}"
			ARGS -C ${_flags} -o "${OUTFILE}" "${INFILE}"
			DEPENDS "${INFILE}"
			COMMENT "Generating ${SRCBASE}.c from ${SRCFILE}"
		)
	ENDMACRO(RAGEL_PARSER)

ELSE(RAGEL_FOUND)

	IF(Ragel_FIND_REQUIRED)
		MESSAGE(FATAL_ERROR "Could not find ragel")
	ENDIF(Ragel_FIND_REQUIRED)
ENDIF(RAGEL_FOUND)
