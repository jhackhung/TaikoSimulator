.686P
.XMM

.model flat, c
include csfml.inc
include windows.inc
includelib kernel32.lib
includelib msvcrt.lib



extern currentPage: DWORD

.data
    ; �ɮ׸��|
    bg_path db "assets/main/bg_genre_2.png", 0
    red_note_path db "assets/main/red_note.png", 0
    blue_note_path db "assets/main/blue_note.png", 0

    selectedMusicPath db "assets/main/song1.ogg", 0
    selectedBeatmapPath db "assets/main/song1.tja", 0

    ; CSFML ����
    bgTexture dd 0
    bgSprite dd 0
    redNoteTexture dd 0
    blueNoteTexture dd 0
    noteSprites dd 256 DUP(0) ; �̦h�䴩 256 �ӭ��ź��F
    noteCount dd 0            ; ��e���żƶq
    bgmusic dd 0

    ; �p�ɾ�
    clock dd 0
    note_timer REAL4 0.0       ; ���ťͦ��p�ɾ�
    note_interval REAL4 100.0    ; �C 1 ��ͦ��@�ӭ���

    ; �����]�w
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0
    scrollSpeed REAL4 -0.05      ; ���źu�ʳt�� (�V������)

    ; �C��`��
    whiteColor sfColor <255, 255, 255, 255> ; �զ�
    blackColor sfColor <0, 0, 0, 255>       ; �¦�

    notePosition sfVector2f <1200.0, 200.0>  ; ���Ū� X �M Y �y��
    movePosition sfVector2f <-0.1, 0.0>
    notes db 256 DUP(0)
    totalNotes dd 0
    bpm REAL4 113.65
    noteSpawnInterval REAL4 0.0
    lineBuffer db 256 DUP(0)
    startTag db "#START", 0
    endTag db "#END", 0

.code
game_play_music PROC
    push offset selectedMusicPath
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
game_play_music ENDP

; ���J�I��
@load_bg PROC
    ; �ЫحI�����z
    push 0
    push offset bg_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov bgTexture, eax

    ; �ЫحI�����F
    call sfSprite_create
    test eax, eax
    jz @fail_load
    mov DWORD PTR [bgSprite], eax

    ; �]�w���z
    push 1
    mov eax, DWORD PTR [bgTexture]
    push eax
    mov ecx, DWORD PTR [bgSprite]
    push ecx
    call sfSprite_setTexture
    add esp, 12
    ret

@fail_load:
    mov eax, 0
    ret
@load_bg ENDP





; ���J����
@load_notes PROC
    ; �Ыج��⭵�ů��z
    push 0
    push offset red_note_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov redNoteTexture, eax
    ret

@fail_load:
    mov eax, 0
    ret
@load_notes ENDP

; �ͦ��s������
@generate_note PROC
    ; �p�G���ŶW�L�̤j�ƶq�A�h���L
    mov eax, noteCount
    cmp eax, 256   ; �ͦ��̦h 256 �ӭ���
    jae @end

    ; �Ыطs�����ź��F
    call sfSprite_create
    test eax, eax
    jz @end

    ; �N�s�����ź��F�x�s��}�C��
    mov esi, noteCount           ; �ϥ� noteCount �ӽT�O���ަ���
    mov DWORD PTR [noteSprites + esi*4], eax

    ; �]�w���⭵�ů��z
    push 1
    mov eax, redNoteTexture
    push eax
    mov ecx, DWORD PTR [noteSprites + esi*4]
    push ecx
    call sfSprite_setTexture
    add esp, 12

    ; �]�w���Ū�l��m
    push dword ptr [notePosition+4] ; Y �y��
    push dword ptr [notePosition]   ; X �y��
    mov eax, DWORD PTR [noteSprites + esi*4]
    push eax
    call sfSprite_setPosition
    add esp, 12

    ; ��s���żƶq
    inc noteCount
@end:
    ret
@generate_note ENDP

; ��s���Ŧ�m
@update_notes PROC
    xor esi, esi

@loop_notes:
    cmp esi, noteCount
    jge @end

    ; �ˬd���ŬO�_����
    mov eax, DWORD PTR [noteSprites + esi*4]
    test eax, eax
    jz @next_note

    ; ���ʭ���
    push dword ptr [movePosition+4] ; Y ��V����
    push scrollSpeed                ; X ��V����
    push eax
    call sfSprite_move
    add esp, 12

@next_note:
    inc esi
    jmp @loop_notes
@end:
    ret
@update_notes ENDP

; �M�z����
@cleanup_notes PROC
    xor esi, esi

@loop_cleanup:
    cmp esi, noteCount
    jge @end

    ; �ˬd���ŬO�_����
    mov eax, DWORD PTR [noteSprites + esi*4]
    test eax, eax
    jz @next_cleanup

    ; �P�����ź��F
    push eax
    call sfSprite_destroy
    add esp, 4

@next_cleanup:
    inc esi
    jmp @loop_cleanup
@end:
    ret
@cleanup_notes ENDP

main_game_page PROC window:DWORD
    ; ���J�I��
    call @load_bg
    test eax, eax
    jz @exit_program

    ; ���񭵼�
    call game_play_music

    ; ���J����
    call @load_notes
    test eax, eax
    jz @exit_program

    ; ��l�ƭp�ɾ�
    call sfClock_create
    test eax, eax
    jz @exit_program
    mov clock, eax

    ; �]�m���ťͦ����j�}�l�ɶ�
    movss note_timer, xmm0

@main_loop:
    ; �ˬd�����O�_�}��
    mov eax, window
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exit_program


    ; ��s�p�ɾ�
    mov eax, clock
    push eax
    call sfClock_getElapsedTime
    add esp, 4
    test eax, eax
    jz @exit_program               ; �p�G�ɶ���^�L�ġA�h�X�{��

    ; �ˬd���֬O�_����
    push bgMusic
    call sfMusic_getStatus
    add esp, 4
    cmp eax, 0
    je @to_end_page

    ; �����L����ഫ�����
    mov ebx, 1000000  ; 1,000,000 �Ω�N�L���ഫ����
    xor edx, edx      ; �M�� edx�A�ǳƶi�氣�k�ާ@
    div ebx           ; eax = microseconds / 1,000,000 (���)
    movss note_timer, xmm0  ; �N��Ʀs�x�� note_timer

    ; �P�_�O�_�ͦ��s������
    movss xmm0, note_timer
    movss xmm1, note_interval
    comiss xmm0, xmm1
    jb @skip_generate_note

    ; �ͦ����Ũí��m�p�ɾ�
    call @generate_note
    call sfClock_restart           ; ���m����



@skip_generate_note:
    ; ��s����
    call @update_notes

    ; �M������
    push blackColor
    push window
    call sfRenderWindow_clear
    add esp, 8

    ; ø�s�I��
    push 0
    mov eax, bgSprite
    push eax
    mov ecx, window
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

    ; ø�s����
    xor esi, esi
@draw_notes_loop:
    cmp esi, noteCount
    jge @end_draw_notes

    mov eax, DWORD PTR [noteSprites + esi*4]
    test eax, eax
    jz @next_draw

    push 0
    push eax
    mov ecx, window
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

@next_draw:
    inc esi
    jmp @draw_notes_loop
@end_draw_notes:

    ; ��ܵ���
    mov eax, window
    push eax
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

; ���൲��e��
@to_end_page:
    mov DWORD PTR [currentPage], 2
    jmp @exit_program



@exit_program:
    call @cleanup_notes

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push redNoteTexture
    call sfTexture_destroy
    add esp, 4

    push clock
    call sfClock_destroy
    add esp, 4




    ret
main_game_page ENDP

END main_game_page