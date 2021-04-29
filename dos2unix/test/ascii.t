#!/usr/bin/perl

# Requires perl-Test-Simple installation.
use Test::Simple tests => 30;

$suffix = "";
if (-e "../dos2unix.exe") {
  $suffix = ".exe";
}
$DOS2UNIX = "../dos2unix" . $suffix;
$MAC2UNIX = "../mac2unix" . $suffix;
$UNIX2DOS = "../unix2dos" . $suffix;
$UNIX2MAC = "../unix2mac" . $suffix;

system("$DOS2UNIX -v -n dos.txt out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'DOS to Unix conversion' );

system("$MAC2UNIX -v -n mac.txt out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'DOS to Unix conversion' );

system("$UNIX2DOS -v -n unix.txt out_dos.txt; cmp out_dos.txt dos.txt");
ok( $? == 0, 'Unix to DOS conversion' );

system("$UNIX2MAC -v -n unix.txt out_mac.txt; cmp out_mac.txt mac.txt");
ok( $? == 0, 'Unix to Mac conversion' );

system("cp -f dos.txt out_unix.txt; $DOS2UNIX -v out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'DOS to Unix conversion, old file mode' );

system("cp -f unix.txt out_dos.txt; $UNIX2DOS -v out_dos.txt; cmp out_dos.txt dos.txt");
ok( $? == 0, 'Unix to DOS conversion, old file mode' );

system("$DOS2UNIX -v -n unix.txt out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'dos2unix must not change unix line breaks');
system("$DOS2UNIX -v -n mac.txt out_unix.txt; cmp out_unix.txt mac.txt");
ok( $? == 0, 'dos2unix must not change mac line breaks');
system("$MAC2UNIX -v -n unix.txt out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'mac2unix must not change unix line breaks');
system("$MAC2UNIX -v -n dos.txt out_unix.txt; cmp out_unix.txt dos.txt");
ok( $? == 0, 'mac2unix must not change dos line breaks');
system("$UNIX2DOS -v -n dos.txt out_dos.txt; cmp out_dos.txt dos.txt");
ok( $? == 0, 'unix2dos must not change dos line breaks');
system("$UNIX2DOS -v -n mac.txt out_dos.txt; cmp out_dos.txt mac.txt");
ok( $? == 0, 'unix2dos must not change mac line breaks');
system("$UNIX2MAC -v -n dos.txt out_mac.txt; cmp out_mac.txt dos.txt");
ok( $? == 0, 'unix2mac must not change dos line breaks');
system("$UNIX2MAC -v -n mac.txt out_mac.txt; cmp out_mac.txt mac.txt");
ok( $? == 0, 'unix2mac must not change mac line breaks');

system("$DOS2UNIX -v -n mixed.txt out.txt; cmp out.txt mixedd2u.txt");
ok( $? == 0, 'DOS to Unix conversion mixed');
system("$MAC2UNIX -v -n mixed.txt out.txt; cmp out.txt mixedm2u.txt");
ok( $? == 0, 'DOS to Unix conversion mixed');
system("$UNIX2DOS -v -n mixed.txt out.txt; cmp out.txt mixedu2d.txt");
ok( $? == 0, 'Unix to DOS conversion mixed');
system("$UNIX2MAC -v -n mixed.txt out.txt; cmp out.txt mixedu2m.txt");
ok( $? == 0, 'Unix to Mac conversion mixed');

system("$DOS2UNIX -v -l -n dos.txt out_unix.txt; cmp out_unix.txt unix_dbl.txt");
ok( $? == 0, 'DOS to Unix conversion with line doubling');
system("$MAC2UNIX -v -l -n mac.txt out_unix.txt; cmp out_unix.txt unix_dbl.txt");
ok( $? == 0, 'DOS to Unix conversion with line doubling');
system("$UNIX2DOS -v -l -n unix.txt out_dos.txt; cmp out_dos.txt dos_dbl.txt");
ok( $? == 0, 'Unix to DOS conversion with line doubling');
system("$UNIX2MAC -v -l -n unix.txt out_mac.txt; cmp out_mac.txt mac_dbl.txt");
ok( $? == 0, 'Unix to Mac conversion with line doubling');

system("$DOS2UNIX -v -l -n unix.txt out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'dos2unix -l must not change unix line breaks');
system("$DOS2UNIX -v -l -n mac.txt out_unix.txt; cmp out_unix.txt mac.txt");
ok( $? == 0, 'dos2unix -l must not change mac line breaks');
system("$MAC2UNIX -v -l -n unix.txt out_unix.txt; cmp out_unix.txt unix.txt");
ok( $? == 0, 'mac2unix -l must not change unix line breaks');
system("$MAC2UNIX -v -l -n dos.txt out_unix.txt; cmp out_unix.txt dos.txt");
ok( $? == 0, 'mac2unix -l must not change dos line breaks');
system("$UNIX2DOS -v -l -n dos.txt out_dos.txt; cmp out_dos.txt dos.txt");
ok( $? == 0, 'unix2dos -l must not change dos line breaks');
system("$UNIX2DOS -v -l -n mac.txt out_dos.txt; cmp out_dos.txt mac.txt");
ok( $? == 0, 'unix2dos -l must not change mac line breaks');
system("$UNIX2MAC -v -l -n dos.txt out_mac.txt; cmp out_mac.txt dos.txt");
ok( $? == 0, 'unix2mac -l must not change dos line breaks');
system("$UNIX2MAC -v -l -n mac.txt out_mac.txt; cmp out_mac.txt mac.txt");
ok( $? == 0, 'unix2mac -l must not change mac line breaks');

