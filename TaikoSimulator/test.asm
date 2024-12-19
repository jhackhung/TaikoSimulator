.686P
.model flat, c

includelib kernel32.lib

extern GetStdHandle@4:PROC
extern CreateFileA@28:PROC
extern WriteFile@20:PROC
extern ReadFile@20:PROC
extern ExitProcess@4:PROC
extern CloseHandle@4:PROC
extern WriteConsoleA@20:PROC
extern GetLastError@0:PROC

GENERIC_READ equ 80000000h
FILE_ATTRIBUTE_NORMAL equ 80h
STD_OUTPUT_HANDLE equ -11

.data
    stdout_handle dd 0

    filename db "test.txt", 0
    hFile dd 0
    bytesRead dd 0
    readBuffer db 1024 dup(0)

    msgReadFail db "Read file failed.", 13, 10, 0

    msgReadSuccess db "File content:", 13, 10, 0

.code

readFile PROC
    ; 讀取文件內容
    mov esi, esp

    push 0
    push offset bytesRead
    push 1024
    push offset readBuffer
    push [hFile]
    call ReadFile@20
    add esp, 20

    mov esp, esi
    ret
readFile ENDP

test PROC
    ; 獲取標準輸出句柄
    push STD_OUTPUT_HANDLE  ; STD_OUTPUT_HANDLE
    call GetStdHandle@4
    add esp, 4
    mov [stdout_handle], eax

    ; 打開文件
    push 0
    push FILE_ATTRIBUTE_NORMAL
    push 3
    push 0
    push 1
    push GENERIC_READ
    push offset filename
    call CreateFileA@28
    add esp, 28

    cmp eax, -1
    je handle_error
    mov [hFile], eax ; 保存文件句柄
    
    call readFile
    test eax, eax
    jz handle_error

found:
    ; 將內容寫入控制台
    push 0
    push 0
    push 512
    push offset readBuffer
    push [stdout_handle]
    call WriteConsoleA@20

    ; 關閉文件句柄
    push [hFile]
    call CloseHandle@4
    add esp, 4

handle_error:
	push offset msgReadFail
	call WriteConsoleA@20
	add esp, 4

	jmp exit

exit:
    push 0
    call ExitProcess@4

test ENDP

END test