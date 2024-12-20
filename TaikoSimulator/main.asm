.686P
.XMM
.model flat, c

include csfml.inc

; 引用其他模組中的程序
extern main_page_proc: PROC
extern end_game_page: PROC
extern select_music_page: PROC
extern main_game_page: PROC

public currentPage

.data
currentPage db 0         ; 當前頁面號碼

window_title db "Taiko Simulator", 0
window dd 0
window_videoMode sfVideoMode <1280, 720, 32>

playing_music db 0
.code

create_window PROC
    push 0
    push 6
    push offset window_title
    sub esp, 12
    mov eax, esp
    mov ecx, window_videoMode._width
    mov [eax], ecx
    mov ecx, window_videoMode.height
    mov [eax+4], ecx
    mov ecx, window_videoMode.bpp
    mov [eax+8], ecx
    call sfRenderWindow_create
    add esp, 24
    mov window, eax
    ret
create_window ENDP


main PROC
    ; 初始化程式
    mov currentPage, 0   ; 將當前頁面設為主頁
    call create_window
    test eax, eax
    jz end_program

game_loop:
    ; 根據 currentPage 決定呼叫的程序
    cmp currentPage, -1
    je end_program       ; 如果是 -1，結束程式

    cmp currentPage, 0
    je call_main_page    ; 如果是 0，呼叫 main_page_proc

    cmp currentPage, 1
    je call_select_music_page    ; 如果是 1，呼叫 select_music_page

    cmp currentPage, 2
    je call_end_game_page     ; 如果是 2，call end_game_page for testing starting game
    
    ; 可以添加其他頁面的處理分支
    ; cmp currentPage, 1
    ; je call_other_page

    ; 程式結束條件
    jmp game_loop        ; 無限迴圈，等主頁面修改 currentPage

call_main_page:
    push DWORD PTR [window]
    call main_page_proc  ; 呼叫主頁面程序
    add esp, 4
    jmp game_loop        ; 返回主迴圈

call_select_music_page:
	push DWORD PTR [window]
	call select_music_page
	add esp, 4
    mov dword ptr [playing_music], ebx
	jmp game_loop

call_end_game_page:
    push dword ptr [playing_music]
    push DWORD PTR [window]
	call end_game_page
    add esp, 4
    jmp game_loop

    ; 可以在此添加其他頁面的程序呼叫
    ; call_other_page:
    ;    call other_page_proc
    ;    jmp game_loop

end_program:
	; 程式結束
    push window
	call sfRenderWindow_close
    add esp, 4
    push window
	call sfRenderWindow_destroy
    add esp, 4
    
main ENDP

END main