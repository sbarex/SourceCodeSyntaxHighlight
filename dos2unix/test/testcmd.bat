@echo off
REM This script demonstrates how to use Unicode file names
REM in a batch script.
REM This script is in UTF-8 encoding.
REM This script must NOT have a BOM (Byte Order Mark). Notepad will
REM add one when you save the file. Remove it with unix2dos -r test.bat
REM This script will only run on Windows 7 and higher.

REM switch to UTF-8 code page
chcp 65001
dos2unix -D unicode -i uni_el_αρχείο.txt uni_zh_文件.txt

REM set code page back to original value
chcp 850
