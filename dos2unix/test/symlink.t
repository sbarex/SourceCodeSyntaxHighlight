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

# dos2unix skip symlink

system("cp -f dos.txt out_link.txt");
system("rm -f in_link.txt; ln -s out_link.txt in_link.txt");

system("$DOS2UNIX -v in_link.txt; cmp out_link.txt dos.txt");
ok( $? == 0, 'dos2unix, skip symlink, check symlink target.' );

if (-l "in_link.txt") {
  $symlink = "1";
} else {
  $symlink = "0";
}

ok( $symlink == 1, 'dos2unix, skip symlink, check symlink.' );


# dos2unix replace symlink


system("$DOS2UNIX -v -R in_link.txt; cmp out_link.txt dos.txt");
ok( $? == 0, 'dos2unix, replace symlink, check symlink target.' );

if (-l "in_link.txt") {
  $symlink = "1";
} else {
  $symlink = "0";
}

ok( $symlink == 0, 'dos2unix, replace symlink, check symlink.' );

system("cmp in_link.txt unix.txt");
ok( $? == 0, 'dos2unix, replace symlink, check conversion.' );


# dos2unix follow symlink


system("cp -f dos.txt out_link.txt");
system("rm -f in_link.txt; ln -s out_link.txt in_link.txt");

system("$DOS2UNIX -v -F in_link.txt; cmp out_link.txt unix.txt");
ok( $? == 0, 'dos2unix, follow symlink, check symlink target.' );

if (-l "in_link.txt") {
  $symlink = "1";
} else {
  $symlink = "0";
}

ok( $symlink == 1, 'dos2unix, follow symlink, check symlink.' );



# unix2dos skip symlink

system("cp -f unix.txt out_link.txt");
system("rm -f in_link.txt; ln -s out_link.txt in_link.txt");

system("$UNIX2DOS -v in_link.txt; cmp out_link.txt unix.txt");
ok( $? == 0, 'unix2dos, skip symlink, check symlink target.' );

if (-l "in_link.txt") {
  $symlink = "1";
} else {
  $symlink = "0";
}

ok( $symlink == 1, 'unix2dos, skip symlink, check symlink.' );


# unix2dos replace symlink


system("$UNIX2DOS -v -R in_link.txt; cmp out_link.txt unix.txt");
ok( $? == 0, 'unix2dos, replace symlink, check symlink target.' );

if (-l "in_link.txt") {
  $symlink = "1";
} else {
  $symlink = "0";
}

ok( $symlink == 0, 'unix2dos, replace symlink, check symlink.' );

system("cmp in_link.txt dos.txt");
ok( $? == 0, 'unix2dos, replace symlink, check conversion.' );


# unix2dos follow symlink


system("cp -f unix.txt out_link.txt");
system("rm -f in_link.txt; ln -s out_link.txt in_link.txt");

system("$UNIX2DOS -v -F in_link.txt; cmp out_link.txt dos.txt");
ok( $? == 0, 'unix2dos, follow symlink, check symlink target.' );

if (-l "in_link.txt") {
  $symlink = "1";
} else {
  $symlink = "0";
}

ok( $symlink == 1, 'unix2dos, follow symlink, check symlink.' );
