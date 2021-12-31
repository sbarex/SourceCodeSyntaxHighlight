.DEFAULT_GOAL := cli

null      :=
SPACE     := $(null) $(null)
CURRENT_DIR := $(subst $(SPACE),"\\ ",$(CURDIR))


ifeq ($(BUILT_PRODUCTS_DIR),)
	BUILD_DIR :="${CURRENT_DIR}/build"
else
	BUILD_DIR :=${BUILT_PRODUCTS_DIR}
endif

ifeq ($(ONLY_ACTIVE_ARCH),)
	ONLY_ACTIVE_ARCH=NO
endif

CFLAGS_x86_64 := -target x86_64-apple-macos10.15
CFLAGS_arm64 := -target arm64-apple-macos11

LDFLAGS_x86_64 := -target x86_64-apple-macos10.15
LDFLAGS_arm64 := -target arm64-apple-macos11

bold := $(shell tput bold 2> /dev/null)
normal := $(shell tput sgr0 2> /dev/null)

ifeq ($(CONFIGURATION),Debug)
	CFLAGS_x86_64 += -g
	CFLAGS_arm64 += -g
	DEBUG=1
else
	CFLAGS_x86_64 += -DNDEBUG
	CFLAGS_arm64 += -DNDEBUG
endif

ifndef NATIVE_ARCH
	NATIVE_ARCH := $(shell uname -m)
	# $(error NATIVE_ARCH is not set)
endif
VALID_ARCHS:=x86_64 arm64

dos2unix_cli :=

ifeq ($(NATIVE_ARCH),x86_64)
	dos2unix_cli += ${BUILD_DIR}/dos2unix-x86_64
else
	dos2unix_cli += ${BUILD_DIR}/dos2unix-arm64
endif

ifeq ($(ONLY_ACTIVE_ARCH),NO)
ifeq ($(NATIVE_ARCH),x86_64)
		# build arm code
		dos2unix_cli += ${BUILD_DIR}/dos2unix-arm64
else
		# build intel code
		dos2unix_cli += ${BUILD_DIR}/dos2unix-x86_64
endif
endif

check_arch:
# 	@echo NATIVE_ARCH IS $(NATIVE_ARCH)
ifeq ($(filter $(NATIVE_ARCH),$(VALID_ARCHS)),)
		$(error "Current arch ${NATIVE_ARCH} is not supported! Valid archs are: ${VALID_ARCHS}.")
endif
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Building universal binary...${normal}"
else
		@echo "${bold}Building $(NATIVE_ARCH) architecture...${normal}"
endif
	@echo ""
	
#dos2unix_arm: ${BUILD_DIR}/arm/dos2unix
#dos2unix_intel: ${BUILD_DIR}/intel/dos2unix
cli: ${BUILD_DIR}/dos2unix

install: ${BUILD_DIR}/dos2unix

clean_dos2unix:
	@echo "${bold}Cleaning dos2unix...${normal}"
	${MAKE} -e "Makefile" clean
	@echo ""

${BUILD_DIR}/dos2unix-arm64: | $(BUILD_DIR)
	@echo "${bold}Building dos2unix for arm64 platform...${normal}"
	@#${MAKE} -e "Makefile" clean
	${MAKE} BUILD_DIR="build-arm-$(CONFIGURATION)" ENABLE_NLS= CC="gcc -std=gnu99 -target arm64-apple-macos11" CFLAGS="$(CFLAGS_arm64)" LDFLAGS="$(LDFLAGS_arm64)" -f "$(CURRENT_DIR)/build.makefile"
	cp "build-arm-$(CONFIGURATION)/dos2unix" $@
	@echo "${bold}... OK${normal}"
	@echo ""

${BUILD_DIR}/dos2unix-x86_64: | $(BUILD_DIR)
	@echo "${bold}Building dos2unix for intel platform...${normal}"
	@#${MAKE} -e "Makefile" clean
	${MAKE} BUILD_DIR="build-intel-$(CONFIGURATION)" ENABLE_NLS= CFLAGS="$(CFLAGS_x86_64)" LDFLAGS="$(LDFLAGS_x86_64)" -f "$(CURRENT_DIR)/build.makefile"
	cp "build-intel-$(CONFIGURATION)/dos2unix" $@
	@echo "${bold}... OK${normal}"
	@echo ""

${BUILD_DIR}/dos2unix: $(BUILD_DIR) ${dos2unix_cli}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
	@#echo $(dos2unix_cli)
	@echo "${bold}Creating universal dos2unix...${normal}"
	lipo -create -output $@ "${BUILD_DIR}/dos2unix-x86_64" "${BUILD_DIR}/dos2unix-arm64"
else
	@echo "${bold}Creating dos2unix for ${NATIVE_ARCH}...${normal}"
	@rm $@ > /dev/null
ifeq ($(NATIVE_ARCH),x86_64)
		ln -f "${BUILD_DIR}/dos2unix-x86_64" $@
else
		ln -f "${BUILD_DIR}/dos2unix-arm64" $@
endif
endif
	@echo "${bold}... OK${normal}"

$(BUILD_DIR):
	@echo "Current dir: $(CURRENT_DIR)."

	@echo "Creating build dir $(BUILD_DIR) ..."
	mkdir -p $(BUILD_DIR)
	@echo ""
