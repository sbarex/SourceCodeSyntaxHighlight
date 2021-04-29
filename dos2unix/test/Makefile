TESTS = ascii.t iso.t misc.t bom.t

d2u_os=$(shell uname -s)
UCS = 1

# Checking WIN32 version in MSYS shell.
ifeq ($(findstring MINGW,$(d2u_os)),MINGW)
TESTS += gb18030.t
else
ifneq ($(findstring FreeBSD,$(d2u_os)),FreeBSD)
# Unix/Linux/Cygwin. Check if zh_CN.gb18030 locale is supported.
ifeq ($(shell ./chk_loc.sh zh_CN.gb18030),yes)
TESTS += gb18030.t
endif
endif
endif

# DOS and Windows version do not support symlinks like the Unix version.
ifeq ($(DJGPP),)
ifneq ($(findstring MINGW,$(d2u_os)),MINGW)
TESTS += symlink.t
endif
endif

ifeq ($(UCS),1)

# Check for UTF-8 locale. Try C.UTF-8 and en_US.UTF-8.
ifeq ($(shell ./chk_loc.sh C.UTF-8),yes)
TESTS += utf16.t
export D2U_UTF8_LOCALE = C.UTF-8
else
ifeq ($(shell ./chk_loc.sh en_US.UTF-8),yes)
TESTS += utf16.t
export D2U_UTF8_LOCALE = en_US.UTF-8
endif
endif

# Checking WIN32 version in MSYS shell.
ifeq ($(findstring MINGW,$(d2u_os)),MINGW)
TESTS += utf16_gb.t
else
ifneq ($(findstring FreeBSD,$(d2u_os)),FreeBSD)
# Unix/Linux/Cygwin. Check if zh_CN.gb18030 locale is supported.
ifeq ($(shell ./chk_loc.sh zh_CN.gb18030),yes)
TESTS += utf16_gb.t
endif
endif
endif

endif

ifndef DJGPP
PROVE_OPT ?= --nocolor
endif

all: test

check: test

test:
	prove -v $(PROVE_OPT) $(TESTS)


ascii:
	prove -v $(PROVE_OPT) $@.t

iso:
	prove -v $(PROVE_OPT) $@.t

misc:
	prove -v $(PROVE_OPT) $@.t

bom:
	prove -v $(PROVE_OPT) $@.t

utf16:
	@echo "D2U_UTF8_LOCALE=$(D2U_UTF8_LOCALE)"
	prove -v $(PROVE_OPT) $@.t

gb18030:
	prove -v $(PROVE_OPT) $@.t

utf16_gb:
	prove -v $(PROVE_OPT) $@.t

symlink:
	prove -v $(PROVE_OPT) $@.t

wcstombs:
	$(CC) -Wall -Wextra wcstombs_test.c -o wcstombs_test
	@echo "====> test wcstombs() UTF-8"
	LC_ALL=en_US.UTF-8 ./wcstombs_test
	@echo "====> test wcstombs() GB18030"
	LC_ALL=zh_CN.GB18030 ./wcstombs_test

testu16: testu16.c
	gcc $< -o $@

clean:
	rm -f out*.txt in_link.txt wcstombs_test
