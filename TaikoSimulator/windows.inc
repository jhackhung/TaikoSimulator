; windows.inc - �]�t Windows API ��ƪ��w�q

includelib kernel32.lib

extern GetStdHandle@4:PROC
extern CreateFileA@28:PROC
extern WriteFile@20:PROC
extern ReadFile@20:PROC
extern ExitProcess@4:PROC
extern CloseHandle@4:PROC
extern WriteConsoleA@20:PROC
extern GetLastError@0:PROC

; �w�q�`�q
GENERIC_READ         EQU 0x80000000
FILE_SHARE_READ      EQU 0x00000001
STD_OUTPUT_HANDLE equ -11
OPEN_EXISTING        EQU 3
FILE_ATTRIBUTE_NORMAL EQU 0x00000080

