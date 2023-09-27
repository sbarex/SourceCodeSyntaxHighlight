#!/usr/bin/perl

# Requires perl-Test-Simple installation.
use Test::Simple tests => 7;

$suffix = "";
if (-e "../dos2unix.exe") {
  $suffix = ".exe";
}
$DOS2UNIX = "../dos2unix" . $suffix;
$MAC2UNIX = "../mac2unix" . $suffix;
$UNIX2DOS = "../unix2dos" . $suffix;
$UNIX2MAC = "../unix2mac" . $suffix;

$ENV{'LC_ALL'} = 'C';

system("$DOS2UNIX -v < dos.txt > out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'DOS to Unix conversion, stdin/out' );

system("$UNIX2DOS -v < unix.txt > out_dos.txt; cmp out_dos.txt dos.txt");
ok( $? == 0, 'Unix to DOS conversion, stdin/out' );

system("$DOS2UNIX -v -O dos.txt > out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'DOS to Unix conversion, to stdout' );

system("$UNIX2DOS -v -O unix.txt > out_dos.txt; cmp out_dos.txt dos.txt");
ok( $? == 0, 'Unix to DOS conversion, to stdout' );

system("$DOS2UNIX -v -e -O noeol_dos_utf8.txt noeol_dos_utf8.txt > out_unix.txt; cmp out_unix.txt eol_unix2.txt");
ok( $? == 0, 'convert and concatenate two utf8 files' );

system("$DOS2UNIX -v -e -O noeol_dos_utf16.txt noeol_dos_utf16.txt > out_unix.txt; cmp out_unix.txt eol_unix2.txt");
ok( $? == 0, 'convert and concatenate two utf16 files' );

system("$DOS2UNIX -v -n dos.txt out1.txt -O dos.txt > out2.txt; cmp out2.txt unix.txt");
ok( $? == 0, 'To stdout after paired conversion' );
