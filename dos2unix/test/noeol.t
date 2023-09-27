#!/usr/bin/perl

# Requires perl-Test-Simple installation.
use Test::Simple tests => 25;

$suffix = "";
if (-e "../dos2unix.exe") {
  $suffix = ".exe";
}
$DOS2UNIX = "../dos2unix" . $suffix;
$MAC2UNIX = "../mac2unix" . $suffix;
$UNIX2DOS = "../unix2dos" . $suffix;
$UNIX2MAC = "../unix2mac" . $suffix;

$ENV{'LC_ALL'} = 'C';

system("$DOS2UNIX -v -e -n noeol_dos.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'dos2unix add eol' );

system("$DOS2UNIX -v -e -n noeol_unix.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'dos2unix add eol' );

system("$DOS2UNIX -v -e -n noeol_mac.txt out_unix.txt; cmp out_unix.txt eol_macunix.txt");
ok( $? == 0, 'dos2unix add eol' );

system("$DOS2UNIX -v -e -n noeol_dos_utf16.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'dos2unix add eol' );

# ---------------

system("$DOS2UNIX -v -e -n eol_dos.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'dos2unix add eol' );

system("$DOS2UNIX -v -e -n eol_unix.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'dos2unix add eol' );

system("$DOS2UNIX -v -e -n eol_mac.txt out_unix.txt; cmp out_unix.txt eol_macunix2.txt");
ok( $? == 0, 'dos2unix add eol' );

# ===============

system("$MAC2UNIX -v -e -n noeol_mac.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'mac2unix add eol' );

system("$MAC2UNIX -v -e -n noeol_dos.txt out_unix.txt; cmp out_unix.txt eol_dosunix.txt");
ok( $? == 0, 'mac2unix add eol' );

system("$MAC2UNIX -v -e -n noeol_unix.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'mac2unix add eol' );

# ---------------

system("$MAC2UNIX -v -e -n eol_mac.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'mac2unix add eol' );

system("$MAC2UNIX -v -e -n eol_dos.txt out_unix.txt; cmp out_unix.txt eol_dos.txt");
ok( $? == 0, 'mac2unix add eol' );

system("$MAC2UNIX -v -e -n eol_unix.txt out_unix.txt; cmp out_unix.txt eol_unix.txt");
ok( $? == 0, 'mac2unix add eol' );

# ===============

system("$UNIX2DOS -v -e -n noeol_unix.txt out_dos.txt; cmp out_dos.txt eol_dos.txt");
ok( $? == 0, 'unix2dos add eol' );

system("$UNIX2DOS -v -e -n noeol_dos.txt out_dos.txt; cmp out_dos.txt eol_dos.txt");
ok( $? == 0, 'unix2dos add eol' );

system("$UNIX2DOS -v -e -n noeol_mac.txt out_dos.txt; cmp out_dos.txt eol_macdos.txt");
ok( $? == 0, 'unix2dos add eol' );

# ---------------

system("$UNIX2DOS -v -e -n eol_unix.txt out_dos.txt; cmp out_dos.txt eol_dos.txt");
ok( $? == 0, 'unix2dos add eol' );

system("$UNIX2DOS -v -e -n eol_dos.txt out_dos.txt; cmp out_dos.txt eol_dos.txt");
ok( $? == 0, 'unix2dos add eol' );

system("$UNIX2DOS -v -e -n eol_mac.txt out_dos.txt; cmp out_dos.txt eol_macdos2.txt");
ok( $? == 0, 'unix2dos add eol' );

# ===============

system("$UNIX2MAC -v -e -n noeol_unix.txt out_mac.txt; cmp out_mac.txt eol_mac.txt");
ok( $? == 0, 'unix2mac add eol' );

system("$UNIX2MAC -v -e -n noeol_dos.txt out_mac.txt; cmp out_mac.txt eol_dosmac.txt");
ok( $? == 0, 'unix2mac add eol' );

system("$UNIX2MAC -v -e -n noeol_mac.txt out_mac.txt; cmp out_mac.txt eol_mac.txt");
ok( $? == 0, 'unix2mac add eol' );

# ---------------

system("$UNIX2MAC -v -e -n eol_unix.txt out_mac.txt; cmp out_mac.txt eol_mac.txt");
ok( $? == 0, 'unix2mac add eol' );

system("$UNIX2MAC -v -e -n eol_dos.txt out_mac.txt; cmp out_mac.txt eol_dos.txt");
ok( $? == 0, 'unix2mac add eol' );

system("$UNIX2MAC -v -e -n eol_mac.txt out_mac.txt; cmp out_mac.txt eol_mac.txt");
ok( $? == 0, 'unix2mac add eol' );
