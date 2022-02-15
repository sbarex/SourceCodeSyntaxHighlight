.DEFAULT_GOAL := all

SPACE     := $(null) $(null)
CURRENT_DIR := $(subst $(SPACE),"\\ ",$(CURDIR))

LUA_DIR=lua
HIGHLIGHT_DIR=highlight

ifeq ($(BUILT_PRODUCTS_DIR),)
	BUILD_DIR=${CURRENT_DIR}/build
else
	BUILD_DIR=${BUILT_PRODUCTS_DIR}
endif

ifeq ($(ONLY_ACTIVE_ARCH),)
	ONLY_ACTIVE_ARCH=NO
endif

BUILD_DIR := $(BUILD_DIR)/highlight

CXX=clang++
CFLAGS=-Wall -std=c++11 -D_FILE_OFFSET_BITS=64 \
       -I "${CURRENT_DIR}/${HIGHLIGHT_DIR}/src/include" \
       -I "${CURRENT_DIR}/${LUA_DIR}/src" \
       -I "${CURRENT_DIR}" \
       -I "${BUILD_DIR}"
LDFLAGS="-L${BUILD_DIR}"

CFLAGS_x86_64=-target x86_64-apple-macos10.15
CFLAGS_arm64=-target arm64-apple-macos11

# ifneq ($(wildcard /Library/Developer/CommandLineTools/SDKs/MacOSX10.15.sdk/.*),)
# 	CFLAGS_x86_64+=-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX10.15.sdk
# endif

LDFLAGS_x86_64=-target x86_64-apple-macos10.15
LDFLAGS_arm64=-target arm64-apple-macos11

ifeq ($(CONFIGURATION),Debug)
	CFLAGS_x86_64+= -g
	CFLAGS_arm64+= -g
else
	CFLAGS_x86_64+= -DNDEBUG
	CFLAGS_arm64+= -DNDEBUG
endif

bold := $(shell tput bold 2> /dev/null)
normal := $(shell tput sgr0 2> /dev/null)

ifndef NATIVE_ARCH
	NATIVE_ARCH := $(shell uname -m)
	# $(error NATIVE_ARCH is not set)
endif

VALID_ARCHS = x86_64 arm64

highlight_lib_static =
highlight_lib_shared =
highlight_cli =

wrapper_lib_shared =
wrapper_lib_static =
lua_libraries =

ifeq ($(NATIVE_ARCH),x86_64)
	lua_libraries    += ${BUILD_DIR}/liblua-x86_64.a

	highlight_lib_static += ${BUILD_DIR}/libhighlight-x86_64.a
	highlight_lib_shared += ${BUILD_DIR}/libhighlight-x86_64.dylib
	highlight_cli        += ${BUILD_DIR}/highlight-x86_64

	wrapper_lib_shared += ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib
	wrapper_lib_static += ${BUILD_DIR}/libwrapper_highlight-x86_64.a
else
	lua_libraries    += ${BUILD_DIR}/liblua-arm64.a

	highlight_lib_static += ${BUILD_DIR}/libhighlight-arm64.a
	highlight_lib_shared += ${BUILD_DIR}/libhighlight-arm64.dylib
	highlight_cli        += ${BUILD_DIR}/highlight-arm64

	wrapper_lib_shared += ${BUILD_DIR}/libwrapper_highlight-arm64.dylib
	wrapper_lib_static += ${BUILD_DIR}/libwrapper_highlight-arm64.a
endif

ifeq ($(ONLY_ACTIVE_ARCH),NO)
ifeq ($(NATIVE_ARCH),x86_64)
		# build arm code
		lua_libraries    += ${BUILD_DIR}/liblua-arm64.a

		highlight_lib_static += ${BUILD_DIR}/libhighlight-arm64.a
		highlight_lib_shared += ${BUILD_DIR}/libhighlight-arm64.dylib
		highlight_cli        += ${BUILD_DIR}/highlight-arm64

		wrapper_lib_shared += ${BUILD_DIR}/libwrapper_highlight-arm64.dylib
		wrapper_lib_static += ${BUILD_DIR}/libwrapper_highlight-arm64.a
else
		# build intel code
		lua_libraries    += ${BUILD_DIR}/liblua-x86_64.a

		highlight_lib_static += ${BUILD_DIR}/libhighlight-x86_64.a
		highlight_lib_shared += ${BUILD_DIR}/libhighlight-x86_64.dylib
		highlight_cli        += ${BUILD_DIR}/highlight-x86_64

		wrapper_lib_shared += ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib
		wrapper_lib_static += ${BUILD_DIR}/libwrapper_highlight-x86_64.a
endif
endif

check_arch: FORCE
# 	@echo NATIVE_ARCH IS $(NATIVE_ARCH)
ifeq ($(filter $(NATIVE_ARCH),$(VALID_ARCHS)),)
		$(error "Current arch ${NATIVE_ARCH} is not supported! Valid archs are: ${VALID_ARCHS}.")
endif
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Building universal binary...${normal}"
else
		@echo "${bold}Building $(NATIVE_ARCH) architecture...${normal}"
endif
	@echo "Build dir: $(BUILD_DIR)"
	@echo ""

build_dir:
	$(shell mkdir build 2> /dev/null)

# ################################
# LUA library
# ################################

lua_arm: ${BUILD_DIR}/liblua-arm64.a
lua_intel: ${BUILD_DIR}/liblua-x86_64.a
lua: ${BUILD_DIR}/liblua.a

clean_lua:
	@echo "${bold}Cleaning lua...${normal}"
	${MAKE} -C ${LUA_DIR} clean
	@echo ""

${BUILD_DIR}/liblua-arm64.a: | $(BUILD_DIR)
	@echo "${bold}Building lua for arm64 platform…${normal}"
	${MAKE} -C "${LUA_DIR}" clean
	${MAKE} CC="gcc -std=gnu99 -target arm64-apple-macos11" MYCFLAGS="$(CFLAGS_arm64)" MYLDFLAGS="$(LDFLAGS_arm64)" -C "${LUA_DIR}"
	@mkdir -p "${BUILD_DIR}"
	mv "${LUA_DIR}/src/liblua.a" "${BUILD_DIR}/liblua-arm64.a"
	@echo ""

${BUILD_DIR}/liblua-x86_64.a: | $(BUILD_DIR)
	@echo "${bold}Building lua for x86_64 platform…${normal}"
	${MAKE} -C "${LUA_DIR}" clean
	${MAKE} MYCFLAGS="$(CFLAGS_x86_64)" MYLDFLAGS="$(LDFLAGS_x86_64)" -C "${LUA_DIR}"
	@mkdir -p "${BUILD_DIR}"
	mv "${LUA_DIR}/src/liblua.a" "${BUILD_DIR}/liblua-x86_64.a"
	@echo ""

${BUILD_DIR}/liblua.a: $(BUILD_DIR) ${lua_libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating lua universal library...${normal}"
		lipo -create -output "${BUILD_DIR}/liblua.a" "${BUILD_DIR}/liblua-x86_64.a" "${BUILD_DIR}/liblua-arm64.a"
else
		@echo "${bold}Creating lua library for ${NATIVE_ARCH}...${normal}"
		@rm -f "${BUILD_DIR}/liblua.a" > /dev/null
		ln "${BUILD_DIR}/liblua-${NATIVE_ARCH}.a" "${BUILD_DIR}/liblua.a"
endif
	@echo ""



# ################################
# Highlight library
# ################################

highlight_static: ${BUILD_DIR}/libhighlight.a
highlight_shared: ${BUILD_DIR}/libhighlight.dylib
highlight_cli: ${BUILD_DIR}/highlight ${BUILD_DIR}/share

${BUILD_DIR}/libhighlight-arm64.a: | $(BUILD_DIR) lua
	@echo "${bold}Building static highlight lib for arm64 platform...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	${MAKE} BUILD_DIR=build_arm-$(CONFIGURATION) LUA_CFLAGS="-I\"$(CURRENT_DIR)/$(LUA_DIR)/src\"" LUA_LIBS="-L\"$(BUILD_DIR)\" -llua -lm" MYCFLAGS="${CFLAGS_arm64} -I$(CURRENT_DIR)/" MYLDFLAGS="$(LDFLAGS_arm64)" -C "${HIGHLIGHT_DIR}" -f makefile2.makefile lib-static
	cp "${HIGHLIGHT_DIR}/src/build_arm-$(CONFIGURATION)/libhighlight.a" "${BUILD_DIR}/libhighlight-arm64.a"
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/libhighlight-arm64.dylib: | $(BUILD_DIR) lua
	@echo "${bold}Building shared highlight lib for arm64 platform...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	${MAKE} BUILD_DIR=build_arm-$(CONFIGURATION) LUA_CFLAGS="-I\"$(CURRENT_DIR)/$(LUA_DIR)/src\"" LUA_LIBS="-L\"$(BUILD_DIR)\" -llua -lm" MYCFLAGS="${CFLAGS_arm64} -I\"$(CURRENT_DIR)/\"" MYLDFLAGS="$(LDFLAGS_arm64)" -C "${HIGHLIGHT_DIR}" -f makefile2.makefile lib-shared
	cp "${HIGHLIGHT_DIR}/src/build_arm-$(CONFIGURATION)/libhighlight.dylib" "${BUILD_DIR}/libhighlight-arm64.dylib"
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/highlight-arm64: | $(BUILD_DIR) lua
	@echo "${bold}Building highlight for arm64 platform...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	${MAKE} BUILD_DIR=build_arm-$(CONFIGURATION) LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" LUA_LIBS="-L$(BUILD_DIR) -llua -lm" MYCFLAGS="${CFLAGS_arm64} -I$(CURRENT_DIR)/" MYLDFLAGS="$(LDFLAGS_arm64)" -C ${HIGHLIGHT_DIR} -f makefile2.makefile cli
	cp "${HIGHLIGHT_DIR}/src/build_arm-$(CONFIGURATION)/highlight" "${BUILD_DIR}/highlight-arm64"
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/libhighlight-x86_64.a: | $(BUILD_DIR) lua
	@echo "${bold}Building static highlight lib for x86_64 platform...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	${MAKE} BUILD_DIR=build_intel-$(CONFIGURATION) LUA_CFLAGS="-I\"$(CURRENT_DIR)/$(LUA_DIR)/src\"" LUA_LIBS="-L\"$(BUILD_DIR)\" -llua -lm" MYCFLAGS="${CFLAGS_x86_64} -I\"$(CURRENT_DIR)/\"" MYLDFLAGS="$(LDFLAGS_x86_64)" -C "${HIGHLIGHT_DIR}" -f makefile2.makefile lib-static
	cp "${HIGHLIGHT_DIR}/src/build_intel-$(CONFIGURATION)/libhighlight.a" "${BUILD_DIR}/libhighlight-x86_64.a"
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/libhighlight-x86_64.dylib: | $(BUILD_DIR) lua
	@echo "${bold}Building shared highlight lib for x86_64 platform...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	${MAKE} BUILD_DIR=build_intel-$(CONFIGURATION) LUA_CFLAGS="-I\"$(CURRENT_DIR)/$(LUA_DIR)/src\"" LUA_LIBS="-L\"$(BUILD_DIR)\" -llua -lm" MYCFLAGS="${CFLAGS_x86_64} -I\"$(CURRENT_DIR)/\"" MYLDFLAGS="$(LDFLAGS_x86_64)" -C "${HIGHLIGHT_DIR}" -f makefile2.makefile lib-shared
	cp "${HIGHLIGHT_DIR}/src/build_intel-$(CONFIGURATION)/libhighlight.dylib" "${BUILD_DIR}/libhighlight-x86_64.dylib"
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/highlight-x86_64: | $(BUILD_DIR) lua
	@echo "${bold}Building highlight for x86_64 platform...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	${MAKE} BUILD_DIR=build_intel-$(CONFIGURATION) LUA_CFLAGS="-I\"$(CURRENT_DIR)/$(LUA_DIR)/src\"" LUA_LIBS="-L\"$(BUILD_DIR)\" -llua -lm" MYCFLAGS="${CFLAGS_x86_64} -I\"$(CURRENT_DIR)/\"" MYLDFLAGS="$(LDFLAGS_x86_64)" -C "${HIGHLIGHT_DIR}" -f makefile2.makefile cli
	${MAKE} PREFIX=build-$(CONFIGURATION) BUILD_DIR=build_intel-$(CONFIGURATION) LUA_CFLAGS="-I\"$(CURRENT_DIR)/$(LUA_DIR)/src\"" LUA_LIBS="-L\"$(BUILD_DIR)\" -llua -lm" MYCFLAGS="${CFLAGS_x86_64} -I\"$(CURRENT_DIR)/\"" -C "${HIGHLIGHT_DIR}" -f makefile2.makefile install
	cp "${HIGHLIGHT_DIR}/src/build_intel-$(CONFIGURATION)/highlight" "${BUILD_DIR}/highlight-x86_64"
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/libhighlight.a: $(BUILD_DIR) ${highlight_lib_static} | lua
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating universal static highlight lib...${normal}"
		lipo -create -output "${BUILD_DIR}/libhighlight.a" "${BUILD_DIR}/libhighlight-x86_64.a" "${BUILD_DIR}/libhighlight-arm64.a"
else
		@echo "${bold}Creating ${NATIVE_ARCH} static highlight lib...${normal}"
		@rm -f "${BUILD_DIR}/libhighlight.a" > /dev/null
		ln "${BUILD_DIR}/libhighlight-${NATIVE_ARCH}.a" "${BUILD_DIR}/libhighlight.a"
endif
	@echo ""

${BUILD_DIR}/libhighlight.dylib: $(BUILD_DIR) ${highlight_lib_shared} | lua
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating universal shared highlight lib...${normal}"
		lipo -create -output "${BUILD_DIR}/libhighlight.dylib" "${BUILD_DIR}/libhighlight-x86_64.dylib" "${BUILD_DIR}/libhighlight-arm64.dylib"
else
		@echo "${bold}Creating ${NATIVE_ARCH} shared highlight lib...${normal}"
		@rm -f "${BUILD_DIR}/libhighlight.dylib" > /dev/null
		ln "${BUILD_DIR}/libhighlight-${NATIVE_ARCH}.dylib" "${BUILD_DIR}/libhighlight.dylib"
endif
	@echo ""

${BUILD_DIR}/highlight: $(BUILD_DIR) $(highlight_cli) | lua
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating universal highlight...${normal}"
		lipo -create -output "${BUILD_DIR}/highlight" "${BUILD_DIR}/highlight-x86_64" "${BUILD_DIR}/highlight-arm64"
else
		@echo "${bold}Creating ${NATIVE_ARCH} highlight...${normal}"
		@rm -f "${BUILD_DIR}/highlight" > /dev/null
		ln "${BUILD_DIR}/highlight-${NATIVE_ARCH}" "${BUILD_DIR}/highlight"
endif
	@echo ""

${BUILD_DIR}/share: $(BUILD_DIR) ${BUILD_DIR}/highlight
	cp -R "${HIGHLIGHT_DIR}/build-$(CONFIGURATION)/share/highlight/" "${BUILD_DIR}/share/"
	cp "${HIGHLIGHT_DIR}/build-$(CONFIGURATION)/etc/highlight/filetypes.conf" "${BUILD_DIR}/share/filetypes.conf"

clean_highlight:
	@echo "${bold}Cleaning highlight…${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	@${MAKE} -C "${HIGHLIGHT_DIR}" -f makefile2.makefile clean
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""


# ################################
# Highlight wrapper
# ################################

highlight-wrapper_intel: ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib
highlight-wrapper_arm: ${BUILD_DIR}/libwrapper_highlight-arm64.dylib
highlight-wrapper: ${BUILD_DIR}/libwrapper_highlight.dylib

clean_highlight-wrapper:
	@echo "${bold}Cleaning highlight wrapper…${normal}"
	@rm -f "${BUILD_DIR}/wrapper_highlight-x86_64.o"
	@rm -f "${BUILD_DIR}/wrapper_highlight-arm64.o"
	@echo ""

${BUILD_DIR}/libwrapper_highlight-x86_64.dylib: $(BUILD_DIR) ${BUILD_DIR}/liblua.a ${BUILD_DIR}/libhighlight-x86_64.a wrapper_highlight.cpp
	@echo "${bold}Compiling highlight wrapper for x86_64 platform...${normal}"
	@echo "current dir: ${CURRENT_DIR}"
	${CXX} ${CFLAGS} ${CFLAGS_x86_64} ${LDFLAGS} ${LDFLAGS_x86_64} \
-static \
-c wrapper_highlight.cpp -o "${BUILD_DIR}/wrapper_highlight-x86_64.o"
	@echo ""

	@echo "${bold}Creating highlight wrapper shared library for x86_64 platform...${normal}"
	${CXX} ${CFLAGS} ${CFLAGS_x86_64} ${LDFLAGS} ${LDFLAGS_x86_64} \
-ldl -lhighlight -llua \
-dynamiclib \
-install_name @rpath/libwrapper_highlight.dylib \
-o "${BUILD_DIR}/libwrapper_highlight-x86_64.dylib" "${BUILD_DIR}/wrapper_highlight-x86_64.o"
	@echo ""

${BUILD_DIR}/libwrapper_highlight-arm64.dylib: $(BUILD_DIR) ${BUILD_DIR}/liblua.a  ${BUILD_DIR}/libhighlight-arm64.a wrapper_highlight.cpp
	@echo "${bold}Compiling highlight wrapper for arm64 platform...${normal}"
	${CXX} ${CFLAGS} ${CFLAGS_arm64} \
-static \
-c wrapper_highlight.cpp -o "${BUILD_DIR}/wrapper_highlight-arm64.o"
	@echo ""
	@echo "${bold}Creating highlight wrapper shared library for arm64 platform...${normal}"
	${CXX} ${CFLAGS} ${CFLAGS_arm64} ${LDFLAGS} ${LDFLAGS_arm64} \
-ldl -lhighlight -llua -framework CoreFoundation \
-dynamiclib \
-install_name @rpath/libwrapper_highlight.dylib \
-o "${BUILD_DIR}/libwrapper_highlight-arm64.dylib" "${BUILD_DIR}/wrapper_highlight-arm64.o"
	@echo ""

${BUILD_DIR}/libwrapper_highlight.dylib: $(BUILD_DIR) ${wrapper_lib_shared} wrapper_highlight.cpp
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating highlight wrapper universal shared library...${normal}"
		lipo -create -output "${BUILD_DIR}/libwrapper_highlight.dylib" "${BUILD_DIR}/libwrapper_highlight-x86_64.dylib" "${BUILD_DIR}/libwrapper_highlight-arm64.dylib"
		@echo ""
else
		@echo "${bold}Creating highlight wrapper library for ${NATIVE_ARCH}...${normal}"
		cp "${BUILD_DIR}/libwrapper_highlight-${NATIVE_ARCH}.dylib" "${BUILD_DIR}/libwrapper_highlight.dylib"
endif


$(BUILD_DIR): FORCE
	@echo "Creating build dir $(BUILD_DIR)..."
	mkdir -p "$(BUILD_DIR)"
	
all: $(BUILD_DIR) check_arch build_dir lua highlight_cli highlight_shared highlight-wrapper

install: $(BUILD_DIR) check_arch build_dir lua highlight_cli highlight_shared highlight-wrapper

clean_intermediate: clean_lua clean_highlight clean_highlight-wrapper

clean: clean_intermediate
	@rm "${BUILD_DIR}/libwrapper_highlight.dylib" 2> /dev/null
	@rm "${BUILD_DIR}/libwrapper_highlight-x86_64.dylib" 2> /dev/null
	@rm "${BUILD_DIR}/libwrapper_highlight-arm64.dylib" 2> /dev/null
	@rm "${BUILD_DIR}/libhighlight.a" 2> /dev/null
	@rm "${BUILD_DIR}/libhighlight-x86_64.a" 2> /dev/null
	@rm "${BUILD_DIR}/libhighlight-arm64.a" 2> /dev/null
	@rm "${BUILD_DIR}/libhighlight-x86_64.so" 2> /dev/null
	@rm "${BUILD_DIR}/libhighlight-arm64.so" 2> /dev/null
	@rm "${BUILD_DIR}/libhighlight.dylib" 2> /dev/null
	@rm "${BUILD_DIR}/libhighlight-x86_64.dylib" 2> /dev/null
	@rm "${BUILD_DIR}/libhighlight-arm64.dylib" 2> /dev/null
	@rm "${BUILD_DIR}/highlight" 2> /dev/null
	@rm "${BUILD_DIR}/highlight-x86_64" 2> /dev/null
	@rm "${BUILD_DIR}/highlight-arm64" 2> /dev/null
	@rm "${BUILD_DIR}/liblua.a" 2> /dev/null
	@rm "${BUILD_DIR}/liblua-x86_64.a" 2> /dev/null
	@rm "${BUILD_DIR}/liblua-arm64.a" 2> /dev/null
	@rm -r "${BUILD_DIR}/share" 2> /dev/null

FORCE:

