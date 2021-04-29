# This script demonstrates how to use Unicode file names
# in a PowerShell script.
# This script is in UTF-8 encoding, with BOM.

$env:DOS2UNIX_DISPLAY_ENC = "utf8"

dos2unix -i uni_el_αρχείο.txt uni_zh_文件.txt

echo "test select-string:"

# select-string requires a BOM.
$env:DOS2UNIX_DISPLAY_ENC = "utf8bom"
dos2unix -i uni* | select-string -encoding utf8 -pattern αρχ

$env:DOS2UNIX_DISPLAY_ENC = ""
