#!/usr/bin/perl

# Requires perl-Test-Simple installation.
use Test::Simple tests => 3;

$suffix = "";
if (-e "../dos2unix.exe") {
  $suffix = ".exe";
}
$DOS2UNIX = "../dos2unix" . $suffix;
$MAC2UNIX = "../mac2unix" . $suffix;
$UNIX2DOS = "../unix2dos" . $suffix;
$UNIX2MAC = "../unix2mac" . $suffix;

if ($ENV{'MSYSTEM'} =~ /^MINGW/)
{
  $GB_OPT = '-gb';
}
else
{
  $GB_OPT = '';
  $ENV{'LC_ALL'} = 'zh_CN.GB18030';
}


system("$DOS2UNIX $GB_OPT -v -n utf16le.txt out_unix.txt; cmp out_unix.txt gb18030u.txt");
ok( $? == 0, 'dos2unix convert DOS UTF-16LE to Unix GB18030' );

system("$DOS2UNIX $GB_OPT -b -v -n utf16le.txt out_unix.txt; cmp out_unix.txt gb18030b.txt");
ok( $? == 0, 'dos2unix convert DOS UTF-16LE to Unix GB18030, keep BOM' );

system("$UNIX2DOS $GB_OPT -v -n utf16be.txt out_dos.txt; cmp out_dos.txt gb18030.txt");
ok( $? == 0, 'unix2dos convert DOS UTF-16BE to DOS GB18030, keep BOM' );
