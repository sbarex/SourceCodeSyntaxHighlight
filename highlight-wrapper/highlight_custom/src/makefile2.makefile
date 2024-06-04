# Simple Makefile for Highlight
# This file will compile the highlight library and binaries.
# See INSTALL for instructions.

# Add -DHL_DATA_DIR=\"/your/path/\" to CFLAGS if you want to define a
# custom installation directory not listed in INSTALL.
# Copy *.conf, ./langDefs, ./themes and ./plugins to /your/path/.
# See ../makefile for the definition of ${data_dir}

# Add -DHL_CONFIG_DIR=\"/your/path/\" to define the configuration directory
# (default: /etc/highlight)

# See src/gui-qt/highlight.pro for the Qt GUI compilation options

#CXX ?= clang++
CXX ?= g++

QMAKE ?= qmake

CFLAGS:=-Wall -O2 ${CFLAGS} ${MYCFLAGS} -std=c++17 -D_FILE_OFFSET_BITS=64 -Wno-unknown-warning-option

#CFLAGS:= -fPIC -O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -fasynchronous-unwind-tables -fstack-clash-protection

#CFLAGS:=-ggdb -O0 ${CFLAGS} -std=c++17

CFLAGS_DILU=-fno-strict-aliasing

SO_VERSION=4.0

# Source paths
CORE_DIR=./core/
CLI_DIR=./cli/
GUI_QT_DIR=./gui-qt/

# Include path
INCLUDE_DIR=./include/

# try to detect Lua versioning scheme
#LUA_PKG_NAME=lua5.3
#LUA_TEST=$(shell pkg-config --exists ${LUA_PKG_NAME}; echo $$?)

#ifeq (${LUA_TEST},1)
#LUA_PKG_NAME=lua
#endif

## Uses env to detect lua flags.
## LUA_CFLAGS=$(shell pkg-config --cflags ${LUA_PKG_NAME})
## LUA_LIBS=$(shell pkg-config --libs ${LUA_PKG_NAME})

# luajit lib
# LUA_LIBS=$(shell pkg-config --libs luajit)

# Third-Party software paths
ASTYLE_DIR=${CORE_DIR}astyle/
REGEX_DIR=${CORE_DIR}re/
DILU_DIR=${CORE_DIR}Diluculum/

ifndef HL_CONFIG_DIR
	HL_CONFIG_DIR = /etc/highlight/
endif
ifndef HL_DATA_DIR
	HL_DATA_DIR = /usr/share/highlight/
endif
ifndef HL_DOC_DIR
	HL_DOC_DIR = /usr/share/doc/highlight/
endif

ifdef PIC
	CFLAGS+=-fPIC
endif

ifndef BUILD_DIR
	BUILD_DIR = .
endif

LDFLAGS = -ldl ${MYLDFLAGS}
# Do not strip by default (Mac OS X lazy pointer issues)
# Add -static to avoid linking with shared libs (can cause trouble when highlight
# is run as service)
#LDFLAGS = ${LDFLAGS} -s
#LDFLAGS= -Wl,--as-needed

CXX_COMPILE=${CXX} ${CFLAGS} -c -I ${INCLUDE_DIR} ${LUA_CFLAGS}

# Data directories (data dir, configuration file dir)
CXX_DIR=-DHL_DATA_DIR=\"${HL_DATA_DIR}\" -DHL_CONFIG_DIR=\"${HL_CONFIG_DIR}\"

AR=ar
ARFLAGS=-crs

# objects files to build the library
CORE_OBJECTS:= ${BUILD_DIR}/stylecolour.o ${BUILD_DIR}/stringtools.o \
	${BUILD_DIR}/xhtmlgenerator.o ${BUILD_DIR}/latexgenerator.o ${BUILD_DIR}/texgenerator.o ${BUILD_DIR}/rtfgenerator.o \
	${BUILD_DIR}/htmlgenerator.o ${BUILD_DIR}/ansigenerator.o ${BUILD_DIR}/svggenerator.o ${BUILD_DIR}/codegenerator.o \
	${BUILD_DIR}/xterm256generator.o ${BUILD_DIR}/pangogenerator.o ${BUILD_DIR}/bbcodegenerator.o ${BUILD_DIR}/odtgenerator.o\
	${BUILD_DIR}/syntaxreader.o ${BUILD_DIR}/elementstyle.o ${BUILD_DIR}/themereader.o ${BUILD_DIR}/keystore.o ${BUILD_DIR}/lspclient.o\
	${BUILD_DIR}/datadir.o ${BUILD_DIR}/preformatter.o ${BUILD_DIR}/platform_fs.o\
	${BUILD_DIR}/ASStreamIterator.o ${BUILD_DIR}/ASResource.o ${BUILD_DIR}/ASFormatter.o ${BUILD_DIR}/ASBeautifier.o ${BUILD_DIR}/ASEnhancer.o

DILU_OBJECTS:=${BUILD_DIR}/InternalUtils.o ${BUILD_DIR}/LuaExceptions.o ${BUILD_DIR}/LuaFunction.o ${BUILD_DIR}/LuaState.o\
	${BUILD_DIR}/LuaUserData.o ${BUILD_DIR}/LuaUtils.o ${BUILD_DIR}/LuaValue.o ${BUILD_DIR}/LuaVariable.o ${BUILD_DIR}/LuaWrappers.o

# command line interface
CLI_OBJECTS:=${BUILD_DIR}/arg_parser.o ${BUILD_DIR}/cmdlineoptions.o ${BUILD_DIR}/main.o ${BUILD_DIR}/help.o

# Qt user interface
GUI_OBJECTS:=${GUI_QT_DIR}main.cpp ${GUI_QT_DIR}mainwindow.cpp ${GUI_QT_DIR}io_report.cpp\
	${GUI_QT_DIR}showtextfile.cpp

cli: $(BUILD_DIR) $(BUILD_DIR)/libhighlight.a ${CLI_OBJECTS}
	${CXX} ${LDFLAGS} -o ${BUILD_DIR}/highlight ${CLI_OBJECTS} -L${BUILD_DIR} -lhighlight ${LUA_LIBS} -Wl,-rpath,'@loader_path/'

lib-static $(BUILD_DIR)/libhighlight.a: $(BUILD_DIR) ${CORE_OBJECTS}
	${AR} ${ARFLAGS} ${BUILD_DIR}/libhighlight.a ${CORE_OBJECTS} ${DILU_OBJECTS}

lib-shared ${BUILD_DIR}/libhighlight.dylib: $(BUILD_DIR) ${CORE_OBJECTS}
	${CXX} -dynamiclib -Wl,-install_name,@loader_path/libhighlight.dylib ${LUA_LIBS} -o ${BUILD_DIR}/libhighlight.dylib -lc ${CORE_OBJECTS} ${DILU_OBJECTS} ${LDFLAGS}

gui-qt: highlight-gui

highlight-gui: ${BUILD_DIR}/libhighlight.a $(BUILD_DIR) ${GUI_OBJECTS}
	cd gui-qt && \
	${QMAKE} 'DEFINES+=DATA_DIR=\\\"${HL_DATA_DIR}\\\" CONFIG_DIR=\\\"${HL_CONFIG_DIR}\\\" DOC_DIR=\\\"${HL_DOC_DIR}\\\" ' && \
	$(MAKE)

$(OBJECTFILES) : makefile


${BUILD_DIR}/datadir.o: ${CORE_DIR}datadir.cpp ${INCLUDE_DIR}datadir.h ${INCLUDE_DIR}platform_fs.h
	${CXX_COMPILE} ${CORE_DIR}datadir.cpp ${CXX_DIR} -o $@

${BUILD_DIR}/platform_fs.o: ${CORE_DIR}platform_fs.cpp ${INCLUDE_DIR}platform_fs.h
	${CXX_COMPILE} ${CORE_DIR}platform_fs.cpp -o $@

${BUILD_DIR}/themereader.o: ${CORE_DIR}themereader.cpp ${INCLUDE_DIR}themereader.h \
	${INCLUDE_DIR}stringtools.h ${INCLUDE_DIR}elementstyle.h ${INCLUDE_DIR}stylecolour.h ${DILU_OBJECTS}
	${CXX_COMPILE} ${CORE_DIR}themereader.cpp -o $@

${BUILD_DIR}/elementstyle.o: ${CORE_DIR}elementstyle.cpp ${INCLUDE_DIR}elementstyle.h ${INCLUDE_DIR}stylecolour.h
	${CXX_COMPILE} ${CORE_DIR}elementstyle.cpp -o $@

${BUILD_DIR}/syntaxreader.o: ${CORE_DIR}syntaxreader.cpp ${INCLUDE_DIR}syntaxreader.h ${INCLUDE_DIR}keystore.h \
	${INCLUDE_DIR}platform_fs.h ${INCLUDE_DIR}enums.h ${INCLUDE_DIR}stringtools.h
	${CXX_COMPILE} ${CORE_DIR}syntaxreader.cpp -o $@

${BUILD_DIR}/codegenerator.o: ${CORE_DIR}codegenerator.cpp ${INCLUDE_DIR}codegenerator.h ${INCLUDE_DIR}syntaxreader.h \
	${INCLUDE_DIR}stringtools.h ${INCLUDE_DIR}enums.h ${INCLUDE_DIR}themereader.h ${INCLUDE_DIR}keystore.h \
	${INCLUDE_DIR}elementstyle.h ${INCLUDE_DIR}stylecolour.h ${INCLUDE_DIR}preformatter.h ${INCLUDE_DIR}lspclient.h \
	${INCLUDE_DIR}htmlgenerator.h ${INCLUDE_DIR}version.h ${INCLUDE_DIR}charcodes.h ${INCLUDE_DIR}xhtmlgenerator.h ${INCLUDE_DIR}rtfgenerator.h \
	${INCLUDE_DIR}latexgenerator.h ${INCLUDE_DIR}texgenerator.h ${INCLUDE_DIR}ansigenerator.h
	${CXX_COMPILE} ${CORE_DIR}codegenerator.cpp -o $@

${BUILD_DIR}/ansigenerator.o: ${CORE_DIR}ansigenerator.cpp ${INCLUDE_DIR}ansigenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}ansigenerator.cpp -o $@

${BUILD_DIR}/htmlgenerator.o: ${CORE_DIR}htmlgenerator.cpp ${INCLUDE_DIR}htmlgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}htmlgenerator.cpp -o $@

${BUILD_DIR}/latexgenerator.o: ${CORE_DIR}latexgenerator.cpp ${INCLUDE_DIR}latexgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}latexgenerator.cpp -o $@

${BUILD_DIR}/bbcodegenerator.o: ${CORE_DIR}bbcodegenerator.cpp ${INCLUDE_DIR}bbcodegenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}bbcodegenerator.cpp -o $@

${BUILD_DIR}/pangogenerator.o: ${CORE_DIR}pangogenerator.cpp ${INCLUDE_DIR}pangogenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}pangogenerator.cpp -o $@

${BUILD_DIR}/odtgenerator.o: ${CORE_DIR}odtgenerator.cpp ${INCLUDE_DIR}odtgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}odtgenerator.cpp -o $@

${BUILD_DIR}/rtfgenerator.o: ${CORE_DIR}rtfgenerator.cpp ${INCLUDE_DIR}rtfgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}rtfgenerator.cpp -o $@

${BUILD_DIR}/texgenerator.o: ${CORE_DIR}texgenerator.cpp ${INCLUDE_DIR}texgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}texgenerator.cpp -o $@

${BUILD_DIR}/xhtmlgenerator.o: ${CORE_DIR}xhtmlgenerator.cpp ${INCLUDE_DIR}xhtmlgenerator.h ${INCLUDE_DIR}htmlgenerator.h \
	${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}xhtmlgenerator.cpp -o $@

${BUILD_DIR}/svggenerator.o: ${CORE_DIR}svggenerator.cpp ${INCLUDE_DIR}svggenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}svggenerator.cpp -o $@

${BUILD_DIR}/xterm256generator.o: ${CORE_DIR}xterm256generator.cpp ${INCLUDE_DIR}xterm256generator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}xterm256generator.cpp -o $@

${BUILD_DIR}/preformatter.o: ${CORE_DIR}preformatter.cpp ${INCLUDE_DIR}preformatter.h ${INCLUDE_DIR}stringtools.h
	${CXX_COMPILE} ${CORE_DIR}preformatter.cpp -o $@

${BUILD_DIR}/stringtools.o: ${CORE_DIR}stringtools.cpp ${INCLUDE_DIR}stringtools.h
	${CXX_COMPILE} ${CORE_DIR}stringtools.cpp -o $@

${BUILD_DIR}/stylecolour.o: ${CORE_DIR}stylecolour.cpp ${INCLUDE_DIR}stylecolour.h ${INCLUDE_DIR}enums.h ${INCLUDE_DIR}stringtools.h
	${CXX_COMPILE} ${CORE_DIR}stylecolour.cpp -o $@

${BUILD_DIR}/keystore.o: ${CORE_DIR}keystore.cpp ${INCLUDE_DIR}keystore.h
	${CXX_COMPILE} ${CORE_DIR}keystore.cpp -o $@

${BUILD_DIR}/lspclient.o: ${CORE_DIR}lspclient.cpp ${INCLUDE_DIR}lspclient.h
	${CXX_COMPILE} ${CORE_DIR}lspclient.cpp -o $@

# cli stuff
${BUILD_DIR}/arg_parser.o: ${CLI_DIR}arg_parser.cc
	${CXX_COMPILE} ${CLI_DIR}arg_parser.cc -o $@

${BUILD_DIR}/cmdlineoptions.o: ${CLI_DIR}cmdlineoptions.cpp ${CLI_DIR}cmdlineoptions.h
	${CXX_COMPILE} ${CLI_DIR}cmdlineoptions.cpp -o $@

${BUILD_DIR}/help.o: ${CLI_DIR}help.cpp ${CLI_DIR}help.h
	${CXX_COMPILE} ${CLI_DIR}help.cpp -o $@

${BUILD_DIR}/main.o: ${CLI_DIR}main.cpp ${CLI_DIR}main.h ${CLI_DIR}cmdlineoptions.h ${INCLUDE_DIR}platform_fs.h \
	${INCLUDE_DIR}datadir.h ${INCLUDE_DIR}enums.h ${INCLUDE_DIR}codegenerator.h \
	${INCLUDE_DIR}syntaxreader.h ${INCLUDE_DIR}themereader.h ${INCLUDE_DIR}elementstyle.h \
	${INCLUDE_DIR}stylecolour.h  ${INCLUDE_DIR}preformatter.h \
	${CLI_DIR}help.h ${INCLUDE_DIR}version.h
	${CXX_COMPILE} ${CLI_DIR}main.cpp ${CXX_DIR} -o $@


#3rd party libs

${BUILD_DIR}/ASBeautifier.o: ${ASTYLE_DIR}ASBeautifier.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASBeautifier.cpp -o $@

${BUILD_DIR}/ASFormatter.o: ${ASTYLE_DIR}ASFormatter.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASFormatter.cpp -o $@

${BUILD_DIR}/ASResource.o: ${ASTYLE_DIR}ASResource.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASResource.cpp -o $@

${BUILD_DIR}/ASEnhancer.o: ${ASTYLE_DIR}ASResource.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASEnhancer.cpp -o $@

${BUILD_DIR}/ASStreamIterator.o: ${ASTYLE_DIR}ASStreamIterator.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASStreamIterator.cpp -o $@

${BUILD_DIR}/InternalUtils.o: ${DILU_DIR}InternalUtils.cpp
	${CXX_COMPILE}  ${DILU_DIR}InternalUtils.cpp -o $@
${BUILD_DIR}/LuaExceptions.o: ${DILU_DIR}LuaExceptions.cpp
	${CXX_COMPILE}  ${DILU_DIR}LuaExceptions.cpp -o $@
${BUILD_DIR}/LuaFunction.o: ${DILU_DIR}LuaFunction.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaFunction.cpp -o $@
${BUILD_DIR}/LuaState.o: ${DILU_DIR}LuaState.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaState.cpp -o $@
${BUILD_DIR}/LuaUserData.o: ${DILU_DIR}LuaUserData.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaUserData.cpp -o $@
${BUILD_DIR}/LuaUtils.o: ${DILU_DIR}LuaUtils.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaUtils.cpp -o $@
${BUILD_DIR}/LuaValue.o: ${DILU_DIR}LuaValue.cpp
	${CXX_COMPILE} ${CFLAGS_DILU} ${DILU_DIR}LuaValue.cpp -o $@
${BUILD_DIR}/LuaVariable.o: ${DILU_DIR}LuaVariable.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaVariable.cpp -o $@
${BUILD_DIR}/LuaWrappers.o: ${DILU_DIR}LuaWrappers.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaWrappers.cpp -o $@

.PHONY: ${GUI_OBJECTS}

$(BUILD_DIR):
	@echo "Creating build dir $(BUILD_DIR)..."
	mkdir -p $@

clean:
	@rm -f ${BUILD_DIR}/*.o
	@rm -f ${BUILD_DIR}/highlight
	@rm -f ${BUILD_DIR}/highlight-gui
	@rm -f ${BUILD_DIR}/libhighlight.a
	@rm -f ${BUILD_DIR}/libhighlight.so.*
	@rm -f ${BUILD_DIR}/.deps/*
	@rm -f gui-qt/*.o
	@rm -f gui-qt/Makefile*
	@rm -f gui-qt/object_script.*
	@rm -f gui-qt/ui_*.h gui-qt/qrc_*.cpp gui-qt/moc_*.cpp
	@rm -rf gui-qt/highlight-gui.gch/
	@rm -f gui-qt/.qmake.stash

# for SWIG makefile
clean-obj:
	@rm -f ${BUILD_DIR}/*.o
