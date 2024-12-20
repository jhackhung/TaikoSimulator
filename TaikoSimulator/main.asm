.686P
.XMM
.model flat, c

include csfml.inc

; �ޥΨ�L�Ҳդ����{��
extern main_page_proc: PROC
extern end_game_page: PROC
extern select_music_page: PROC
extern main_game_page: PROC

public currentPage

.data
currentPage db 0         ; ��e�������X

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
    ; ��l�Ƶ{��
    mov currentPage, 0   ; �N��e�����]���D��
    call create_window
    test eax, eax
    jz end_program

game_loop:
    ; �ھ� currentPage �M�w�I�s���{��
    cmp currentPage, -1
    je end_program       ; �p�G�O -1�A�����{��

    cmp currentPage, 0
    je call_main_page    ; �p�G�O 0�A�I�s main_page_proc

    cmp currentPage, 1
    je call_select_music_page    ; �p�G�O 1�A�I�s select_music_page

    cmp currentPage, 2
    je call_end_game_page     ; �p�G�O 2�Acall end_game_page for testing starting game
    
    ; �i�H�K�[��L�������B�z����
    ; cmp currentPage, 1
    ; je call_other_page

    ; �{����������
    jmp game_loop        ; �L���j��A���D�����ק� currentPage

call_main_page:
    push DWORD PTR [window]
    call main_page_proc  ; �I�s�D�����{��
    add esp, 4
    jmp game_loop        ; ��^�D�j��

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

    ; �i�H�b���K�[��L�������{�ǩI�s
    ; call_other_page:
    ;    call other_page_proc
    ;    jmp game_loop

end_program:
	; �{������
    push window
	call sfRenderWindow_close
    add esp, 4
    push window
	call sfRenderWindow_destroy
    add esp, 4
    
main ENDP

END main