# Author: Erwin Waterlander
#
#   Copyright (C) 2009-2020 Erwin Waterlander
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions
#   are met:
#   1. Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright
#      notice in the documentation and/or other materials provided with
#      the distribution.
#
#   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
#   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE
#   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
#   OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
#   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#   Description
#
#       This is a GNU Makefile that uses GNU compilers, linkers and cpp. The
#       platform specific issues are determined by the various OS teets that
#       rely on the uname(1) command and directory locations.
#
#       Set additional flags for the build with variables CFLAGS_USER,
#       DEFS_USER and LDFLAGS_USER.

include version.mk

.PHONY: doc man txt html pdf mofiles tags merge test check

.PRECIOUS: %.1 %.pod

CC              ?= gcc
CPP             ?= cpp
CPP_FLAGS_POD   = ALL
STRIP           = strip

PACKAGE         = dos2unix
UNIX2DOS        = unix2dos
MAC2UNIX        = mac2unix
UNIX2MAC        = unix2mac

# Native Language Support (NLS)
ENABLE_NLS      = 1
# Large File Support (LFS)
LFS             = 1
# DEBUG=1 adds the -g option to CFLAGS, for adding debug symbols.
DEBUG = 0
# DEBUGMSG=1 adds -DDEBUG=1 to CFLAGS, for extra verbose messages.
DEBUGMSG = 0
UCS = 1
DIST_TARGET = dist-tgz

EXE=

BIN             = $(PACKAGE)$(EXE)
UNIX2DOS_BIN    = $(UNIX2DOS)$(EXE)
MAC2UNIX_BIN    = $(MAC2UNIX)$(EXE)
UNIX2MAC_BIN    = $(UNIX2MAC)$(EXE)

LINK            = ln -sf
LINK_MAN        = $(LINK)

prefix          = /usr
exec_prefix     = $(prefix)
bindir          = $(exec_prefix)/bin
datarootdir     = $(prefix)/share
datadir         = $(datarootdir)

docsubdir       = $(PACKAGE)-$(DOS2UNIX_VERSION)
docdir          = $(datarootdir)/doc/$(docsubdir)
localedir       = $(datarootdir)/locale
mandir          = $(datarootdir)/man
man1dir         = $(mandir)/man1
manext          = .1
man1ext         = .1

ifdef ENABLE_NLS
        POT             = po/$(PACKAGE).pot
        POFILES         = $(wildcard po/*.po)
        MOFILES         = $(patsubst %.po,%.mo,$(POFILES))
        NLSSUFFIX       = -nls
endif

# On some systems (e.g. GNU Win32) GNU mkdir is installed as `gmkdir'.
MKDIR           = mkdir

VERSIONSUFFIX   = -bin

# ......................................................... OS flags ...


ifndef D2U_OS
        d2u_os=$(shell uname -s)

ifeq ($(findstring CYGWIN,$(d2u_os)),CYGWIN)
        D2U_OS = cygwin
endif

ifndef D2U_OS
ifeq ($(findstring MSYS,$(d2u_os)),MSYS)
        D2U_OS = msys
endif
endif

ifndef D2U_OS
ifeq ($(findstring MINGW32,$(d2u_os)),MINGW32)
        D2U_OS = mingw32
endif
endif

ifndef D2U_OS
ifeq ($(findstring MINGW64,$(d2u_os)),MINGW64)
        D2U_OS = mingw64
endif
endif

ifndef D2U_OS
ifneq ($(DJGPP),)
        D2U_OS = msdos
endif
endif

ifndef D2U_OS
ifneq (, $(wildcard /opt/csw))
        D2U_OS = sun
endif
endif

ifndef D2U_OS
        D2U_OS=$(shell echo $(d2u_os) | tr [A-Z] [a-z])
endif

endif

ifeq (cygwin,$(D2U_OS))
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
endif
        LDFLAGS_EXTRA = -Wl,--enable-auto-import
        EXE = .exe
        # allow non-cygwin clients which do not understand cygwin
        # symbolic links to launch applications...
        LINK = ln -f
        # but use symbolic links for man pages, since man client
        # IS a cygwin app and DOES understand symlinks.
        LINK_MAN = ln -fs
        # Cygwin packaging standard avoids version numbers on
        # documentation directories.
        docsubdir       = $(PACKAGE)
        MACHINE := $(subst -pc-cygwin,,$(shell gcc -dumpmachine))
        VERSIONSUFFIX   = -cygwin-$(MACHINE)
endif

ifeq (msys,$(D2U_OS))
        CC=gcc
        EXE = .exe
        MACHINE := $(subst -pc-msys,,$(shell gcc -dumpmachine))
# MSYS 1 does not support locales and no Unicode.
ifeq ($(shell ./test/chk_loc.sh en_US.utf8),no)
        UCS =
        VERSIONSUFFIX = -msys1-$(MACHINE)
else
        VERSIONSUFFIX = -msys2-$(MACHINE)
endif
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
endif
endif

ifeq (mingw32,$(D2U_OS))
        CC=gcc
        prefix=c:/usr/local
        EXE = .exe
        VERSIONSUFFIX = -win32
        LINK = cp -f
        UNIFILE=1
        DIST_TARGET = dist-zip
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
        ZIPOBJ_EXTRA = bin/libintl-8.dll bin/libiconv-2.dll
endif
ifeq ($(findstring w64-mingw32,$(shell gcc -dumpmachine)),w64-mingw32)
# Mingw-w64
        CFLAGS_COMPILER = -DD2U_COMPILER=MINGW32_W64
ifdef ENABLE_NLS
        ZIPOBJ_EXTRA += bin/libgcc_s_dw2-1.dll bin/libwinpthread-1.dll
endif
        CRT_GLOB_OBJ = /mingw32/i686-w64-mingw32/lib/CRT_glob.o
        LIBS_EXTRA += $(CRT_GLOB_OBJ)
        CFLAGS_OS=-I/mingw32/include
else
        CFLAGS_OS=-D_O_U16TEXT=0x20000
endif
endif

ifeq (mingw64,$(D2U_OS))
        CC=gcc
        prefix=c:/usr/local64
        EXE = .exe
        VERSIONSUFFIX = -win64
        LINK = cp -f
        UNIFILE=1
        DIST_TARGET = dist-zip
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
        ZIPOBJ_EXTRA = bin/libintl-8.dll bin/libiconv-2.dll
endif
        CRT_GLOB_OBJ = /mingw64/x86_64-w64-mingw32/lib/CRT_glob.o
        LIBS_EXTRA += $(CRT_GLOB_OBJ)
        CFLAGS_OS=-I/mingw64/include
endif

ifeq (msdos,$(D2U_OS))
        prefix=c:/dos32
        EXE = .exe
        VERSIONSUFFIX = pm
        LINK_MAN = cp -f
        docsubdir = dos2unix
        UCS =
        ZIPOBJ_EXTRA = bin/cwsdpmi.exe
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
endif
endif

ifeq (os/2,$(D2U_OS))
        prefix=c:/usr
        EXE = .exe
        VERSIONSUFFIX = -os2
        LINK_MAN = cp -f
        UCS =
        LDFLAGS_EXTRA = -Zargs-wild
        DIST_TARGET = dist-zip
ifdef ENABLE_NLS
        LIBS_EXTRA += -lintl -liconv
endif
endif

ifeq (freemint,$(D2U_OS))
        prefix=/usr
        EXE =
        VERSIONSUFFIX = -freemint
        UCS=
        ENABLE_NLS=
ifdef ENABLE_NLS
        LIBS_EXTRA += -lintl -liconv
endif
        EXTRA_DEFS += -Dfreemint -D__OS=\"freemint\"
endif

ifeq (freebsd,$(D2U_OS))
ifdef ENABLE_NLS
        CFLAGS_OS     = -I/usr/local/include
        LDFLAGS_EXTRA = -L/usr/local/lib
        LIBS_EXTRA    = -lintl
endif
endif

ifeq (darwin,$(D2U_OS))
ifdef ENABLE_NLS
        CFLAGS_OS     = -I/usr/local/include
        LDFLAGS_EXTRA = -L/usr/local/lib
        LIBS_EXTRA    = -lintl
endif
endif

ifeq (sun,$(D2U_OS))
        # Running under SunOS/Solaris
        LIBS_EXTRA = -lintl
endif

ifeq (hp-ux,$(D2U_OS))
        # Running under HP-UX
        EXTRA_DEFS += -Dhpux -D_HPUX_SOURCE
endif


# ............................................................ flags ...

# PostScript and PDF generation from UTF-8 manuals is not working,
# or I don't know how to do it.

CFLAGS_USER     =
ifeq ($(DEBUG), 1)
CFLAGS          ?= -O0
else
CFLAGS          ?= -O2
endif
CFLAGS          += -Wall -Wextra -Wconversion $(RPM_OPT_FLAGS) $(CPPFLAGS) $(CFLAGS_USER)

EXTRA_CFLAGS    = -DVER_REVISION=\"$(DOS2UNIX_VERSION)\" \
                  -DVER_DATE=\"$(DOS2UNIX_DATE)\" \
                  -DVER_AUTHOR=\"$(DOS2UNIX_AUTHOR)\" \
                  -DDEBUG=$(DEBUGMSG) \
                  $(CFLAGS_OS) \
                  $(CFLAGS_COMPILER)

ifeq ($(DEBUG), 1)
        EXTRA_CFLAGS += -g
endif

ifdef STATIC
        EXTRA_CFLAGS += -static
endif

ifdef UCS
        EXTRA_CFLAGS += -DD2U_UNICODE
endif
ifdef UNIFILE
        EXTRA_CFLAGS += -DD2U_UNIFILE
endif


ifdef LFS
        EXTRA_CFLAGS += -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
endif

LDFLAGS_USER    =
LDFLAGS = $(RPM_LD_FLAGS) $(LDFLAGS_EXTRA) $(LDFLAGS_USER)
LIBS    = $(LIBS_EXTRA)

DEFS_USER       =
DEFS            = $(EXTRA_DEFS) $(DEFS_USER)

# .......................................................... targets ...

all: $(BUILD_DIR) $(BIN)

status:
	@echo "D2U_OS       = $(D2U_OS)"
	@echo "UCS          = $(UCS)"
	@echo "CFLAGS       = $(CFLAGS)"
	@echo "EXTRA_CFLAGS = $(EXTRA_CFLAGS)"
	@echo "LDFLAGS      = $(LDFLAGS)"
	@echo "LIBS         = $(LIBS)"

${BUILD_DIR}/common.o : common.c common.h dos2unix.h unix2dos.h version.mk
	@echo "compiling common.o…"
	$(CC) $(DEFS) $(EXTRA_CFLAGS) $(DOS2UNIX_NLSDEFS) $(CFLAGS) -c $< -o $@

${BUILD_DIR}/querycp.o : querycp.c querycp.h
	@echo "compiling querycp.o…"
	$(CC) $(DEFS) $(EXTRA_CFLAGS) $(DOS2UNIX_NLSDEFS) $(CFLAGS) -c $< -o $@

${BUILD_DIR}/dos2unix.o : dos2unix.c dos2unix.h querycp.h common.h
	@echo "compiling dos2unix.o…"
	$(CC) $(DEFS) $(EXTRA_CFLAGS) $(DOS2UNIX_NLSDEFS) $(CFLAGS) -c $< -o $@

${BUILD_DIR}/unix2dos.o : unix2dos.c unix2dos.h querycp.h common.h
	@echo "compiling unix2dos.o…"
	$(CC) $(DEFS) $(EXTRA_CFLAGS) $(DOS2UNIX_NLSDEFS) $(CFLAGS) -c $< -o $@

$(BIN): ${BUILD_DIR}/dos2unix.o ${BUILD_DIR}/querycp.o ${BUILD_DIR}/common.o
	@echo "compiling $(BIN) (bin)…"
	$(CC) $+ $(LDFLAGS) $(LIBS) -o ${BUILD_DIR}/$@

$(UNIX2DOS_BIN): ${BUILD_DIR}/unix2dos.o ${BUILD_DIR}/querycp.o ${BUILD_DIR}/common.o
	@echo "compiling $(UNIX2DOS_BIN) (bin)…"
	$(CC) $+ $(LDFLAGS) $(LIBS) -o  -v${BUILD_DIR}/$@

# DJGPP supports linking of .EXEs via 'stubify'.
# See djgpp.mak and http://www.delorie.com/djgpp/v2faq/faq22_5.html
# ln -s does automatic stubify in DJGPP 2.03.
# This changed in DJGPP 2.05. DJGPP 2.05 emulates symbolic links.

$(MAC2UNIX_BIN) : $(BIN)
ifneq ($(DJGPP),)
	stubify -g ${BUILD_DIR}/$@ ; stubedit ${BUILD_DIR}/$@ runfile=$<
else
	$(LINK) $< ${BUILD_DIR}/$@
endif


$(UNIX2MAC_BIN) : $(UNIX2DOS_BIN)
ifneq ($(DJGPP),)
	stubify -g ${BUILD_DIR}/$@ ; stubedit ${BUILD_DIR}/$@ runfile=$<
else
	$(LINK) $< ${BUILD_DIR}/$@
endif


test: all
ifneq ($(DJGPP),)
	cd test; $(MAKE) test UCS= SHELL=$(shell which sh)
else
	cd test; $(MAKE) test UCS=$(UCS)
endif

check: test

mostlyclean:
	rm -f *.o
	rm -f $(BIN) $(UNIX2DOS_BIN) $(MAC2UNIX_BIN) $(UNIX2MAC_BIN)
	rm -f *.bak *~
	rm -f *.tmp
	rm -f man/man1/*.bak man/man1/*~
	rm -f man/*/man1/*.bak man/*/man1/*~
	rm -f po/*.bak po/*~
	rm -f po/*.mo po-man/*~
	cd test; $(MAKE) clean

# Don't distribute PostScript and PDF manuals in the source package.
# We don't want binary PDF files in the source package, because
# some packagers check in the source files. PostScript is not used
# a lot.

clean: mostlyclean
	rm -f man/man1/*.ps
	rm -f man/man1/*.pdf
	rm -f man/*/man1/*.ps
	rm -f man/*/man1/*.pdf

distclean: clean

# Because there is so much trouble with generating man pages with
# pod2man, due to old Perl versions (< 5.10.1) on many systems, I include the
# man pages in the source tar file.
# Old pod2man versions do not have the --utf8 option. Old pod2man, pod2text,
# and pod2html do not support the =encoding command.
# Perl 5.18 pod2man demands an =encoding command for Latin-1 encoded POD files.
#
# Newer perl/pod2man versions produce better output. It is better to include
# man pages in the source package, than that people generate them themselves
# with old perl versions.

maintainer-clean: distclean
	@echo 'This command is intended for maintainers to use; it'
	@echo 'deletes files that may need special tools to rebuild.'
	rm -f man/man1/*.1
	rm -f man/man1/*.txt
	rm -f man/man1/*.$(HTMLEXT)
	rm -f po-man/dos2unix-man.pot
	rm -f man/*/man1/*.1
	rm -f man/*/man1/*.txt
	rm -f man/*/man1/*.pod
	rm -f man/*/man1/*.$(HTMLEXT)

realclean: maintainer-clean

$(BUILD_DIR):
	@echo "Creating build dir $(BUILD_DIR)..."
	mkdir -p $@
	
# End of file
