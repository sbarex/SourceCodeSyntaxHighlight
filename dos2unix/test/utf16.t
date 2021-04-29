#!/usr/bin/perl

# Requires perl-Test-Simple installation.
use Test::Simple tests => 32;

$suffix = "";
if (-e "../dos2unix.exe") {
  $suffix = ".exe";
}

$system = `uname -s`;
if ($system =~ m/MINGW/)
{
  $unix=0;
} else {
  $unix=1;
}

$DOS2UNIX = "../dos2unix" . $suffix;
$MAC2UNIX = "../mac2unix" . $suffix;
$UNIX2DOS = "../unix2dos" . $suffix;
$UNIX2MAC = "../unix2mac" . $suffix;

if (defined $ENV{'D2U_UTF8_LOCALE'}) {
  $ENV{'LC_ALL'} = $ENV{'D2U_UTF8_LOCALE'};
} else {
  print "error: Environment variable D2U_UTF8_LOCALE is not set.";
  exit 1;
}

system("$DOS2UNIX -v -n utf16le.txt out_unix.txt; cmp out_unix.txt utf8unix.txt");
ok( $? == 0, 'DOS UTF-16LE to Unix UTF-8' );
system("$DOS2UNIX -v -n utf16be.txt out_unix.txt; cmp out_unix.txt utf8unix.txt");
ok( $? == 0, 'DOS UTF-16BE to Unix UTF-8' );
system("$UNIX2DOS -v -n utf16le.txt out_dos.txt; cmp out_dos.txt utf8dos.txt");
ok( $? == 0, 'DOS UTF-16LE to DOS UTF-8' );
system("$UNIX2DOS -v -n utf16be.txt out_dos.txt; cmp out_dos.txt utf8dos.txt");
ok( $? == 0, 'DOS UTF-16BE to DOS UTF-8' );

system("$DOS2UNIX -v -ul -n utf16len.txt out_unix.txt; cmp out_unix.txt utf8unix.txt");
ok( $? == 0, 'UTF-16LE without BOM to UTF-8' );
system("$DOS2UNIX -v -ub -n utf16ben.txt out_unix.txt; cmp out_unix.txt utf8unix.txt");
ok( $? == 0, 'UTF-16BE without BOM to UTF-8' );
system("$DOS2UNIX -v -ul -n utf16be.txt out_unix.txt; cmp out_unix.txt utf8unix.txt");
ok( $? == 0, 'BOM overrides -ul' );
system("$DOS2UNIX -v -ub -n utf16le.txt out_unix.txt; cmp out_unix.txt utf8unix.txt");
ok( $? == 0, 'BOM overrides -ub' );

system("$DOS2UNIX -v -b -n utf16le.txt out_unix.txt; cmp out_unix.txt utf8unxb.txt");
ok( $? == 0, 'DOS UTF-16LE to Unix UTF-8, keep BOM' );
system("$UNIX2DOS -v -r -n utf16le.txt out_dos.txt; cmp out_dos.txt utf8dosn.txt");
ok( $? == 0, 'DOS UTF-16LE to DOS UTF-8, remove BOM' );

system("$MAC2UNIX -v -n utf16le.txt out_unix.txt; cmp out_unix.txt utf8dosn.txt");
ok( $? == 0, 'mac2unix does not change utf16 DOS line breaks.' );
system("$UNIX2MAC -v -n utf16le.txt out_mac.txt; cmp out_mac.txt utf8dos.txt");
ok( $? == 0, 'unix2mac does not change utf16 DOS line breaks.' );

system("$UNIX2DOS -v -u -n utf16le.txt out_dos.txt; cmp out_dos.txt utf16le.txt");
ok( $? == 0, 'DOS UTF-16LE to DOS UTF-16' );
system("$UNIX2DOS -v -u -n utf16be.txt out_dos.txt; cmp out_dos.txt utf16be.txt");
ok( $? == 0, 'DOS UTF-16BE to DOS UTF-16' );
system("$DOS2UNIX -v -b -u -n utf16.txt out_unix.txt; cmp out_unix.txt utf16u.txt");
ok( $? == 0, 'DOS UTF-16LE to Unix UTF-16' );
system("$MAC2UNIX -v -b -u -n utf16m.txt out_unix.txt; cmp out_unix.txt utf16u.txt");
ok( $? == 0, 'Mac UTF-16LE to Unix UTF-16' );
system("$UNIX2DOS -v -b -u -n utf16u.txt out_dos.txt; cmp out_dos.txt utf16.txt");
ok( $? == 0, 'Unix UTF-16 to DOS UTF-16LE' );
system("$UNIX2MAC -v -b -u -n utf16u.txt out_mac.txt; cmp out_mac.txt utf16m.txt");
ok( $? == 0, 'Unix UTF-16 to Mac UTF-16LE' );

system("$DOS2UNIX -v -f -n utf16bin.txt out_unix.txt; cmp out_unix.txt unix_bin.txt");
ok( $? == 0, 'Dos2unix, force UTF-16 file with binary symbols' );
system("$UNIX2DOS -v -f -r -n utf16bin.txt out_dos.txt; cmp out_dos.txt dos_bin.txt");
ok( $? == 0, 'Unix2dos, force UTF-16 file with binary symbols' );

system("$DOS2UNIX -v -n invalhig.txt out_unix.txt");
$result = ($? >> 8);
ok( $result == 1, 'Dos2unix, invalid surrogate pair, missing low surrogate' );
system("$DOS2UNIX -v -n invallow.txt out_unix.txt");
$result = ($? >> 8);
ok( $result == 1, 'Dos2unix, invalid surrogate pair, missing high surrogate' );

system("cat utf16le.txt | $DOS2UNIX -v > out_unix.txt; cmp out_unix.txt utf8unix.txt");
ok( $? == 0, 'UTF-16LE with BOM to UTF-8, stdin/out' );

system("cat utf16u.txt | $UNIX2DOS -v -u > out_dos.txt; cmp out_dos.txt utf16.txt");
ok( $? == 0, 'UTF-16LE with BOM to UTF-16LE, stdin/out' );

system("$UNIX2DOS -v -u -m -n unix.txt out_dos.txt; cmp out_dos.txt dos_bom.txt");
ok( $? == 0, 'Option -u must not disable -m on ASCII input');

system("$DOS2UNIX -ul -i utf16le.txt utf16len.txt utf8unxb.txt gb18030.txt > outinfo.txt");
system("$DOS2UNIX outinfo.txt; diff info_ul.txt outinfo.txt");
ok( $? == 0, 'Option -i, --info combined with -ul');

system("$DOS2UNIX -ub -i utf16be.txt utf16ben.txt utf8unxb.txt gb18030.txt > outinfo.txt");
system("$DOS2UNIX outinfo.txt; diff info_ub.txt outinfo.txt");
ok( $? == 0, 'Option -i, --info combined with -ub');

system("$DOS2UNIX -v -7 -n utf16le.txt out_unix.txt chardos.txt out_u7.txt; cmp out_unix.txt utf8unix.txt");
ok( $? == 0, '7bit disabled for utf16');

system("cmp out_u7.txt charu7.txt");
ok( $? == 0, '7bit enabled again, dos2unix');

system("$DOS2UNIX -i dos.txt unix.txt mac.txt mixed.txt utf16le.txt utf16be.txt utf16len.txt utf8unix.txt utf8dos.txt gb18030.txt > outinfo.txt");
system("$DOS2UNIX outinfo.txt; diff info_ucs.txt outinfo.txt");
ok( $? == 0, 'Option -i, --info');

$ENV{'LC_ALL'} = 'C';

system("$DOS2UNIX -v -n utf16le.txt out_unix.txt");
$result = ($? >> 8);
if ( $unix ) { $expected = 1; } else { $expected = 0 };
print "UNIX" . $unix . "\n";
print "EXP" . $expected . "\n";
ok( $result == $expected, 'DOS UTF-16LE to Unix in C locale, conversion error.' );
system("$DOS2UNIX -v -n utf16.txt out_unix.txt");
ok( $? == 0, 'DOS UTF-16LE to Unix in C locale, conversion OK' );
