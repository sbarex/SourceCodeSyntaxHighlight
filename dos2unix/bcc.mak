!include version.mk

CC      = bcc
DEFINES = -DVER_REVISION="$(DOS2UNIX_VERSION)" -DVER_DATE="$(DOS2UNIX_DATE)"
CFLAGS  = $(DEFINES) -Z -O -w -mc -1
WILDARGS = c:/bc4/lib/16bit/wildargs.obj

all: dos2unix.exe unix2dos.exe mac2unix.exe unix2mac.exe

dos2unix.exe: dos2unix.obj querycp.obj common.obj
	bcc -mc dos2unix.obj querycp.obj common.obj $(WILDARGS) noehc.lib

unix2dos.exe: unix2dos.obj querycp.obj common.obj
	bcc -mc unix2dos.obj querycp.obj common.obj $(WILDARGS) noehc.lib

# remove noehc.lib if you are using Borland C version prior
# to 4.0. noeh?.lib, where ? stands for the memory model,
# removes the C++ exception handling from the startup-code
# which is included by default since Borland 4.0 and
# higher. Including noeh?.lib reduces the executable size
# significant, provided your source is C only.


#.c.obj:
#	$(CC) -c $(CFLAGS) $<

dos2unix.obj :  dos2unix.c dos2unix.h querycp.h common.h
	$(CC) -c $(CFLAGS) -o$@ dos2unix.c

unix2dos.obj :  unix2dos.c unix2dos.h querycp.h common.h
	$(CC) -c $(CFLAGS) -o$@ unix2dos.c

querycp.obj :  querycp.c querycp.h querycp.h
	$(CC) -c $(CFLAGS) -o$@ querycp.c

common.obj :  querycp.c querycp.h common.h
	$(CC) -c $(CFLAGS) -o$@ common.c

mac2unix.exe: dos2unix.exe
	copy /v dos2unix.exe mac2unix.exe

unix2mac.exe: unix2dos.exe
	copy /v unix2dos.exe unix2mac.exe


strip :
	tdstrip dos2unix.exe
	tdstrip unix2dos.exe
	tdstrip mac2unix.exe
	tdstrip unix2mac.exe

clean:
	del *.obj
	del *.exe

