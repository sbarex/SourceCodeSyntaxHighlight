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
BUILD_DIR_ESCAPED := $(subst $(SPACE),\ ,$(BUILD_DIR))
CURRENT_DIR_ESCAPED := $(subst $(SPACE),\ ,$(CURRENT_DIR))

CXX=clang++
CFLAGS= \
       -I ${CURRENT_DIR_ESCAPED}/${HIGHLIGHT_DIR}/src/include \
       -I ${CURRENT_DIR_ESCAPED}/${LUA_DIR}/src \
       -I ${CURRENT_DIR_ESCAPED} \
       -I ${BUILD_DIR_ESCAPED} \
       -Wno-deprecated-declarations -Wno-unknown-pragmas
CXXFLAGS += -std=c++17
LDFLAGS=-L${BUILD_DIR_ESCAPED}

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
	lua_libraries        += ${BUILD_DIR_ESCAPED}/liblua-x86_64.a

	highlight_lib_static += ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a
	highlight_lib_shared += ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.dylib
	highlight_cli        += ${BUILD_DIR_ESCAPED}/highlight-x86_64

	wrapper_lib_shared   += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib
	wrapper_lib_static   += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.a
else
	lua_libraries        += ${BUILD_DIR_ESCAPED}/liblua-arm64.a

	highlight_lib_static += ${BUILD_DIR_ESCAPED}/libhighlight-arm64.a
	highlight_lib_shared += ${BUILD_DIR_ESCAPED}/libhighlight-arm64.dylib
	highlight_cli        += ${BUILD_DIR_ESCAPED}/highlight-arm64

	wrapper_lib_shared   += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib
	wrapper_lib_static   += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.a
endif

ifeq ($(ONLY_ACTIVE_ARCH),NO)
ifeq ($(NATIVE_ARCH),x86_64)
		# build arm code
		lua_libraries        += ${BUILD_DIR_ESCAPED}/liblua-arm64.a

		highlight_lib_static += ${BUILD_DIR_ESCAPED}/libhighlight-arm64.a
		highlight_lib_shared += ${BUILD_DIR_ESCAPED}/libhighlight-arm64.dylib
		highlight_cli        += ${BUILD_DIR_ESCAPED}/highlight-arm64

		wrapper_lib_shared   += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib
		wrapper_lib_static   += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.a
else
		# build intel code
		lua_libraries        += ${BUILD_DIR_ESCAPED}/liblua-x86_64.a

		highlight_lib_static += ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a
		highlight_lib_shared += ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.dylib
		highlight_cli        += ${BUILD_DIR_ESCAPED}/highlight-x86_64

		wrapper_lib_shared   += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib
		wrapper_lib_static   += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.a
endif
endif

check_arch: FORCE
# 	@echo NATIVE_ARCH IS $(NATIVE_ARCH)
ifeq ($(filter $(NATIVE_ARCH),$(VALID_ARCHS)),)
		$(error "Current arch ${NATIVE_ARCH} is not supported! Valid archs are: ${VALID_ARCHS}.")
endif
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}** BUILDING UNIVERSAL BINARY... ** ${normal}"
else
		@echo "\n${bold}** BUILDING $(NATIVE_ARCH) ARCHITECTURE... ** ${normal}"
endif
	@echo "Build dir: $(BUILD_DIR_ESCAPED)"
	@echo ""

build_dir:
	$(shell mkdir build 2> /dev/null)


# ################################
# LUA library
# ################################

lua_arm: ${BUILD_DIR_ESCAPED}/liblua-arm64.a
lua_intel: ${BUILD_DIR_ESCAPED}/liblua-x86_64.a
lua: ${BUILD_DIR_ESCAPED}/liblua.a

clean_lua:
	@echo "\n${bold}🗑️ CLEANING lua...${normal}"
	${MAKE} -C "${LUA_DIR}" clean
	@echo ""

${BUILD_DIR_ESCAPED}/liblua-arm64.a: | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING lua FOR arm64 PLATFORM...${normal}"
	${MAKE} -C "${LUA_DIR}" clean
	${MAKE} CC="gcc -std=gnu99 -target arm64-apple-macos11" MYCFLAGS="$(CFLAGS_arm64)" MYLDFLAGS="$(LDFLAGS_arm64)" -C "${LUA_DIR}"
	@mkdir -p "${BUILD_DIR}"
	mv "${LUA_DIR}/src/liblua.a" "$@"
	@echo ""

${BUILD_DIR_ESCAPED}/liblua-x86_64.a: | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING lua FOR x86_64 PLATFORM...${normal}"
	${MAKE} -C "${LUA_DIR}" clean
	${MAKE} MYCFLAGS="$(CFLAGS_x86_64)" MYLDFLAGS="$(LDFLAGS_x86_64)" -C "${LUA_DIR}"
	@mkdir -p "${BUILD_DIR}"
	mv "${LUA_DIR}/src/liblua.a" "$@"
	@echo ""

${BUILD_DIR_ESCAPED}/liblua.a: $(BUILD_DIR_ESCAPED) ${lua_libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}CREATING lua UNIVERSAL LIBRARY...${normal}"
		lipo -create -output "$@" ${BUILD_DIR_ESCAPED}/liblua-x86_64.a ${BUILD_DIR_ESCAPED}/liblua-arm64.a
else
		@echo "\n${bold}CREATING lua LIBRARY FOR ${NATIVE_ARCH} PLATFORM...${normal}"
		@rm -f "$@" > /dev/null
		ln "${BUILD_DIR}/liblua-${NATIVE_ARCH}.a" "$@"
endif
	@echo ""



# ################################
# Highlight library
# ################################

highlight_static: ${BUILD_DIR_ESCAPED}/libhighlight.a
highlight_shared: ${BUILD_DIR_ESCAPED}/libhighlight.dylib
highlight_cli: highlight_shared ${BUILD_DIR_ESCAPED}/highlight ${BUILD_DIR_ESCAPED}/share

${BUILD_DIR_ESCAPED}/libhighlight-arm64.a: lua | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING highlight STATIC LIB FOR arm64 PLATFORM...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	
	@if [ -f "${HIGHLIGHT_DIR}/src/htmlgenerator.o" ]; then \
		if ! lipo -archs "${HIGHLIGHT_DIR}/src/htmlgenerator.o" 2>/dev/null | grep -qw arm64; then \
			echo "Clean…"; \
			${MAKE} \
				-C ${HIGHLIGHT_DIR} \
				-f makefile2.makefile \
				clean; \
		fi; \
	fi
	
	${MAKE} \
		BUILD_DIR=${BUILD_DIR_ESCAPED}/build_arm64-$(CONFIGURATION) \
		LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" \
		LUA_LIBS="-L$(BUILD_DIR_ESCAPED) -llua -lm" \
		CFLAGS="${CFLAGS} ${CFLAGS_arm64}" \
		LDFLAGS="$(LDFLAGS) $(LDFLAGS_arm64) -Wl,-rpath,'@loader_path/'" \
		-C ${HIGHLIGHT_DIR} \
		-f makefile2.makefile \
		lib-static install-lib-static
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/libhighlight-arm64.dylib: lua | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING highlight SHARED LIB FOR arm64 PLATFORM...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	
	@if [ -f "${HIGHLIGHT_DIR}/src/htmlgenerator.o" ]; then \
		if ! lipo -archs "${HIGHLIGHT_DIR}/src/htmlgenerator.o" 2>/dev/null | grep -qw arm64; then \
			echo "Clean…"; \
			${MAKE} \
				-C ${HIGHLIGHT_DIR} \
				-f makefile2.makefile \
				clean; \
		fi; \
	fi
	
	${MAKE} \
		BUILD_DIR="$(BUILD_DIR)/build_arm64-$(CONFIGURATION)" \
		LUA_CFLAGS="-I$(CURRENT_DIR_ESCAPED)/$(LUA_DIR)/src" \
		LUA_LIBS="-L$(BUILD_DIR_ESCAPED) -llua -lm" \
		CFLAGS="${CFLAGS} ${CFLAGS_arm64}" \
		LDFLAGS="$(LDFLAGS) $(LDFLAGS_arm64) -Wl,-rpath,'@loader_path/'" \
		-C "${HIGHLIGHT_DIR}" \
		-f makefile2.makefile \
		lib-shared install-lib-shared
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/highlight-arm64: lua | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING highlight FOR arm64 PLATFORM...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	
	@if [ -f "${HIGHLIGHT_DIR}/src/htmlgenerator.o" ]; then \
		if ! lipo -archs "${HIGHLIGHT_DIR}/src/htmlgenerator.o" 2>/dev/null | grep -qw arm64; then \
			echo "Clean…"; \
			${MAKE} \
				-C ${HIGHLIGHT_DIR} \
				-f makefile2.makefile \
				clean; \
		fi; \
	fi
	
	${MAKE} \
		BUILD_DIR=${BUILD_DIR_ESCAPED}/build_arm64-$(CONFIGURATION) \
		LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" \
		LUA_LIBS="-L$(BUILD_DIR_ESCAPED) -llua -lm" \
		CFLAGS="${CFLAGS} ${CFLAGS_arm64}" \
		LDFLAGS="$(LDFLAGS) $(LDFLAGS_arm64) -Wl,-rpath,'@loader_path/'" \
		-C ${HIGHLIGHT_DIR} \
		-f makefile2.makefile \
		cli install
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a: lua | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING highlight STATIC LIB FOR X86_64 PLATFORM...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	
	@if [ -f "${HIGHLIGHT_DIR}/src/htmlgenerator.o" ]; then \
		if ! lipo -archs "${HIGHLIGHT_DIR}/src/htmlgenerator.o" 2>/dev/null | grep -qw x86_64; then \
			echo "Clean…"; \
			${MAKE} \
				-C ${HIGHLIGHT_DIR} \
				-f makefile2.makefile \
				clean; \
		fi; \
	fi
	
	${MAKE} \
		BUILD_DIR=${BUILD_DIR_ESCAPED}/build_intel-$(CONFIGURATION) \
		LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" \
		LUA_LIBS="-L$(BUILD_DIR_ESCAPED) -llua -lm" \
		CFLAGS="${CFLAGS} ${CFLAGS_x86_64}" \
		LDFLAGS="$(LDFLAGS) $(LDFLAGS_x86_64) -Wl,-rpath,'@loader_path/'" \
		-C ${HIGHLIGHT_DIR} \
		-f makefile2.makefile \
		lib-static install-lib-static
	
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/libhighlight-x86_64.dylib: lua | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING highlight SHARED LIB FOR x86_64 PLATFORM...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	
	@if [ -f "${HIGHLIGHT_DIR}/src/htmlgenerator.o" ]; then \
		if ! lipo -archs "${HIGHLIGHT_DIR}/src/htmlgenerator.o" 2>/dev/null | grep -qw x86_64; then \
			echo "Clean…"; \
			${MAKE} \
				-C ${HIGHLIGHT_DIR} \
				-f makefile2.makefile \
				clean; \
		fi; \
	fi
	
	${MAKE} \
		BUILD_DIR=${BUILD_DIR_ESCAPED}/build_intel-$(CONFIGURATION) \
		LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" \
		LUA_LIBS="-L$(BUILD_DIR_ESCAPED) -llua -lm" \
		CFLAGS="${CFLAGS} ${CFLAGS_x86_64}" \
		LDFLAGS="$(LDFLAGS) $(LDFLAGS_x86_64) -Wl,-rpath,'@loader_path/'" \
		-C ${HIGHLIGHT_DIR} \
		-f makefile2.makefile \
		lib-shared install-lib-shared
		
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/highlight-x86_64: lua | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING highlight FOR x86_64 PLATFORM...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	
	@if [ -f "${HIGHLIGHT_DIR}/src/htmlgenerator.o" ]; then \
		if ! lipo -archs "${HIGHLIGHT_DIR}/src/htmlgenerator.o" 2>/dev/null | grep -qw x86_64; then \
			echo "Clean…"; \
			${MAKE} \
				-C ${HIGHLIGHT_DIR} \
				-f makefile2.makefile \
				clean; \
		fi; \
	fi
	
	${MAKE} \
		BUILD_DIR=${BUILD_DIR_ESCAPED}/build_intel-$(CONFIGURATION) \
		LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" \
		LUA_LIBS="-L$(BUILD_DIR_ESCAPED) -llua -lm" \
		CFLAGS="${CFLAGS} ${CFLAGS_x86_64}" \
		LDFLAGS="$(LDFLAGS) $(LDFLAGS_x86_64) -Wl,-rpath,'@loader_path/'" \
		-C ${HIGHLIGHT_DIR} \
		-f makefile2.makefile \
		cli install
		
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/libhighlight.a: ${highlight_lib_static} lua | $(BUILD_DIR_ESCAPED)
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}CREATING UNIVERSAL STATIC highlight LIB...${normal}"
		lipo -create -output "$@" \
			"${BUILD_DIR}/build_intel-$(CONFIGURATION)/lib/libhighlight.a" \
			"${BUILD_DIR}/build_arm64-$(CONFIGURATION)/lib/libhighlight.a"
else
		@echo "\n${bold}CREATING ${NATIVE_ARCH} STATIC highlight LIB...${normal}"
		@rm -f "$@" > /dev/null
		ln "${BUILD_DIR}/build_${NATIVE_ARCH}-$(CONFIGURATION)/lib/libhighlight.a" "$@"
endif
	@echo ""

${BUILD_DIR_ESCAPED}/libhighlight.dylib: ${highlight_lib_shared} lua | $(BUILD_DIR_ESCAPED)
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}CREATING UNIVERSAL SHARED highlight LIB...${normal}"
		lipo -create -output "$@" \
			"${BUILD_DIR}/build_intel-$(CONFIGURATION)/lib/libhighlight.dylib" \
			"${BUILD_DIR}/build_arm64-$(CONFIGURATION)/lib/libhighlight.dylib"
else
		@echo "\n${bold}CREATING ${NATIVE_ARCH} SHARED highlight LIB...${normal}"
		@rm -f "$@" > /dev/null
		ln "${BUILD_DIR}/build_${NATIVE_ARCH}-$(CONFIGURATION)/lib/libhighlight.dylib" "$@"
endif
	@echo ""

${BUILD_DIR_ESCAPED}/highlight: $(highlight_cli) lua | $(BUILD_DIR_ESCAPED)
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}CREATING UNIVERSAL highlight...${normal}"
		lipo -create -output "$@" \
			"${BUILD_DIR}/build_intel-$(CONFIGURATION)/bin/highlight" \
			"${BUILD_DIR}/build_arm64-$(CONFIGURATION)/bin/highlight"
else
		@echo "\n${bold}CREATING ${NATIVE_ARCH} highlight...${normal}"
		@rm -f "$@" > /dev/null
		ln "${BUILD_DIR}/build_${NATIVE_ARCH}-$(CONFIGURATION)/bin/highlight" "$@"
endif
	@echo "🖋️ CODE SIGNING THE HIGHLIGHT APP"
	/usr/bin/codesign --force --deep --sign "$(CODE_SIGN_IDENTITY)" \
	--options runtime \
	--entitlements $(CURRENT_DIR)/entitlements.entitlements \
	${OTHER_CODE_SIGN_FLAGS} \
	"$@"
	@echo ""

${BUILD_DIR_ESCAPED}/share: ${BUILD_DIR_ESCAPED}/highlight | $(BUILD_DIR_ESCAPED)
	cp -R "${BUILD_DIR}/build_${NATIVE_ARCH}-$(CONFIGURATION)/share/highlight/" "${BUILD_DIR}/share/"
	cp "${BUILD_DIR}/build_${NATIVE_ARCH}-$(CONFIGURATION)/etc/highlight/filetypes.conf" "${BUILD_DIR}/share/filetypes.conf"

clean_highlight:
	@echo "\n${bold}🗑️ CLEANING highlight...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	@${MAKE} -C "${HIGHLIGHT_DIR}" -f makefile2.makefile clean
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""


# ################################
# Highlight wrapper
# ################################

highlight-wrapper_intel: ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib
highlight-wrapper_arm: ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib
highlight-wrapper: ${BUILD_DIR_ESCAPED}/libwrapper_highlight.dylib

clean_highlight-wrapper:
	@echo "\n${bold}🗑️ CLEANING highlight wrapper...${normal}"
	@rm -f "${BUILD_DIR}/wrapper_highlight-x86_64.o"
	@rm -f "${BUILD_DIR}/wrapper_highlight-arm64.o"
	@echo ""

${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib: ${BUILD_DIR_ESCAPED}/liblua.a ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a wrapper_highlight.cpp | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING highlight WRAPPER FOR x86_64 PLATFORM...${normal}"
	@echo "current dir: ${CURRENT_DIR}"
	${CXX} ${CFLAGS} -Wall -O2 -std=c++17 -D_FILE_OFFSET_BITS=64 -MMD -MP ${CFLAGS_x86_64} ${LDFLAGS} ${LDFLAGS_x86_64} \
		-static \
		-c wrapper_highlight.cpp -o "${BUILD_DIR}/wrapper_highlight-x86_64.o"
	@echo ""

	@echo "\n${bold}CREATING highlight wrapper SHARED LIBRARY FOR x86_64 PLATFORM...${normal}"
	${CXX} ${CFLAGS} ${CFLAGS_x86_64} ${LDFLAGS} ${LDFLAGS_x86_64} \
		-ldl -lhighlight -llua \
		-dynamiclib \
		-install_name @rpath/libwrapper_highlight.dylib \
		-o "$@" "${BUILD_DIR}/wrapper_highlight-x86_64.o"
	@echo ""

${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib: ${BUILD_DIR_ESCAPED}/liblua.a  ${BUILD_DIR_ESCAPED}/libhighlight-arm64.a wrapper_highlight.cpp | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING highlight wrapper FOR arm64 PLATFORM...${normal}"
	${CXX} ${CFLAGS} -Wall -O2 -std=c++17 -D_FILE_OFFSET_BITS=64 -MMD -MP ${CFLAGS_arm64} \
		-static \
		-c wrapper_highlight.cpp -o "${BUILD_DIR}/wrapper_highlight-arm64.o"
	@echo ""
	@echo "\n${bold}CREATING highlight wrapper SHARED LIBRARY FOR arm64 PLATFORM...${normal}"
	${CXX} ${CFLAGS} ${CFLAGS_arm64} ${LDFLAGS} ${LDFLAGS_arm64} \
		-ldl -lhighlight -llua -framework CoreFoundation \
		-dynamiclib \
		-install_name @rpath/libwrapper_highlight.dylib \
		-o "$@" "${BUILD_DIR}/wrapper_highlight-arm64.o"
	@echo ""

${BUILD_DIR_ESCAPED}/libwrapper_highlight.dylib: ${wrapper_lib_shared} wrapper_highlight.cpp | $(BUILD_DIR_ESCAPED)
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}CREATING highlight wrapper UNIVERSAL SHARED LIBRARY...${normal}"
		lipo -create -output "$@" "${BUILD_DIR}/libwrapper_highlight-x86_64.dylib" "${BUILD_DIR}/libwrapper_highlight-arm64.dylib"
		@echo ""
else
		@echo "\n${bold}CREATING highlight wrapper LIBRARY FOR ${NATIVE_ARCH} PLATFORM...${normal}"
		cp "${BUILD_DIR}/libwrapper_highlight-${NATIVE_ARCH}.dylib" "$@"
endif


$(BUILD_DIR_ESCAPED): FORCE
	@echo "CREATING BUILD DIR $(BUILD_DIR_ESCAPED)..."
	mkdir -p "$(BUILD_DIR)"
	
all: check_arch build_dir lua highlight_cli highlight_shared highlight-wrapper | $(BUILD_DIR_ESCAPED)

install: check_arch build_dir lua highlight_cli highlight_shared highlight-wrapper | $(BUILD_DIR_ESCAPED)

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

