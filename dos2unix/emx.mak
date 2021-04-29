
# Author: Erwin Waterlander
# Copyright (C) 2009-2014 Erwin Waterlander
# This file is distributed under the same license as the dos2unix package.

prefix=c:/usr
ENABLE_NLS=
LDFLAGS_EXTRA = -Zargs-wild

ifdef ENABLE_NLS
LIBS_EXTRA += -lintl -liconv
endif
ZIPOBJ_EXTRA =

all:
	$(MAKE) all EXE=.exe ENABLE_NLS=$(ENABLE_NLS) LDFLAGS_EXTRA="$(LDFLAGS_EXTRA)" LIBS_EXTRA="$(LIBS_EXTRA)" prefix=$(prefix) LINK="cp -f" UCS=

install:
	$(MAKE) install EXE=.exe ENABLE_NLS=$(ENABLE_NLS) LDFLAGS_EXTRA="$(LDFLAGS_EXTRA)" LIBS_EXTRA="$(LIBS_EXTRA)" prefix=$(prefix) LINK="cp -f" UCS=

uninstall:
	$(MAKE) uninstall EXE=.exe prefix=$(prefix)

clean:
	$(MAKE) clean EXE=.exe ENABLE_NLS=$(ENABLE_NLS) prefix=$(prefix)

mostlyclean:
	$(MAKE) mostlyclean EXE=.exe ENABLE_NLS=$(ENABLE_NLS) prefix=$(prefix)

dist:
	$(MAKE) dist-zip EXE=.exe prefix=$(prefix) VERSIONSUFFIX="-os2" ZIPOBJ_EXTRA="${ZIPOBJ_EXTRA}" ENABLE_NLS=$(ENABLE_NLS)

strip:
	$(MAKE) strip LINK="cp -f" EXE=.exe

