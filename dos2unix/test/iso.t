#!/usr/bin/perl

# Requires perl-Test-Simple installation.
use Test::Simple tests => 14;

$suffix = "";
if (-e "../dos2unix.exe") {
  $suffix = ".exe";
}
$DOS2UNIX = "../dos2unix" . $suffix;
$MAC2UNIX = "../mac2unix" . $suffix;
$UNIX2DOS = "../unix2dos" . $suffix;
$UNIX2MAC = "../unix2mac" . $suffix;

# To check for instance cp850 to iso88591 conversion
# you can do a visual check like this (on Windows).
#
# In a Windows Command Prompt, set font to Lucida Console.
# Then set the code page to 850:
#    chcp 850
# Display complete cp850 code page:
#    type chardos.txt
#
# In a Cygwin Mintty terminal, under Options->Text
# set Character set to ISO-8859-1
# Display converted character set:
#    cat iso_850.txt
#
# You now see the same characters as in the Windows Command Prompt
# with the non-convertable characters replaced with a dot.

system("$DOS2UNIX -v -iso -437 -n chardos.txt out_unix.txt; cmp out_unix.txt iso_437.txt");
ok( $? == 0, 'DOS to Unix conversion, cp437 to iso88591 with option -iso' );

system("$DOS2UNIX -v -437 -n chardos.txt out_unix.txt; cmp out_unix.txt iso_437.txt");
ok( $? == 0, 'DOS to Unix conversion, cp437 to iso88591 without option -iso' );

system("$DOS2UNIX -v -850 -n chardos.txt out_unix.txt; cmp out_unix.txt iso_850.txt");
ok( $? == 0, 'DOS to Unix conversion, cp850 to iso88591' );

system("$DOS2UNIX -v -860 -n chardos.txt out_unix.txt; cmp out_unix.txt iso_860.txt");
ok( $? == 0, 'DOS to Unix conversion, cp860 to iso88591' );

system("$DOS2UNIX -v -863 -n chardos.txt out_unix.txt; cmp out_unix.txt iso_863.txt");
ok( $? == 0, 'DOS to Unix conversion, cp863 to iso88591' );

system("$DOS2UNIX -v -865 -n chardos.txt out_unix.txt; cmp out_unix.txt iso_865.txt");
ok( $? == 0, 'DOS to Unix conversion, cp865 to iso88591' );

system("$DOS2UNIX -v -1252 -n chardos.txt out_unix.txt; cmp out_unix.txt iso_1252.txt");
ok( $? == 0, 'DOS to Unix conversion, cp1252 to iso88591' );


# To check for instance iso88591 to cp850 conversion
# you can do a visual check like this (on Windows).
#
# In a Cygwin Mintty terminal, under Options->Text
# set Character set to ISO-8859-1
# Display complete ISO-8859-1 character set:
#    cat charunix.txt
#
# In a Windows Command Prompt, set font to Lucida Console.
# Then set the code page to 850:
#    chcp 850
# Display converted cp850 code page:
#    type cp_850.txt
#
# You now see the same characters as in the Mintty terminal
# with the non-convertable characters replaced with a dot.

system("$UNIX2DOS -v -iso -437 -n charunix.txt out_dos.txt; cmp out_dos.txt cp_437.txt");
ok( $? == 0, 'Unix to DOS conversion, iso88591 to cp437 with option -iso' );

system("$UNIX2DOS -v -437 -n charunix.txt out_dos.txt; cmp out_dos.txt cp_437.txt");
ok( $? == 0, 'Unix to DOS conversion, iso88591 to cp437 without option -iso' );

system("$UNIX2DOS -v -850 -n charunix.txt out_dos.txt; cmp out_dos.txt cp_850.txt");
ok( $? == 0, 'Unix to DOS conversion, iso88591 to cp850' );

system("$UNIX2DOS -v -860 -n charunix.txt out_dos.txt; cmp out_dos.txt cp_860.txt");
ok( $? == 0, 'Unix to DOS conversion, iso88591 to cp860' );

system("$UNIX2DOS -v -863 -n charunix.txt out_dos.txt; cmp out_dos.txt cp_863.txt");
ok( $? == 0, 'Unix to DOS conversion, iso88591 to cp863' );

system("$UNIX2DOS -v -865 -n charunix.txt out_dos.txt; cmp out_dos.txt cp_865.txt");
ok( $? == 0, 'Unix to DOS conversion, iso88591 to cp865' );

system("$UNIX2DOS -v -1252 -n charunix.txt out_dos.txt; cmp out_dos.txt cp_1252.txt");
ok( $? == 0, 'Unix to DOS conversion, iso88591 to cp1252' );
