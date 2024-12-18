.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD
extern selected_music_path: DWORD
extern selected_beatmap1_path: DWORD

.data


    ; �襤�����֩M�Э��ɮ�
    selectedMusicPath db 256 DUP(0)    ; �����ɮ׸��|
    selectedBeatmapPath db 256 DUP(0)  ; �Э��ɮ׸��|

    ; �ɶ��P�C�����A
    currentNoteIndex DWORD 0  ; ��e���ů���
    currentSongTime DWORD 0   ; ��e�q���ɶ� (�@��)
    lastJudgment DWORD -1     ; �W�@���P�w���G

    ; �Э����Ůɶ�
    noteTimings DWORD 256 DUP(?) ; �x�s���Ůɶ�
    noteCount DWORD 0            ; �`���żƶq

    ; CSFML ����


    ; �����]�w
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0
    scrollSpeed REAL4 -0.05      ; ���źu�ʳt�� (�V������)

    ; �C��`��
    whiteColor sfColor <255, 255, 255, 255> ; �զ�
    blackColor sfColor <0, 0, 0, 255>       ; �¦�


    call sfMusic_createFromFile
    add esp, 4
    mov bgMusic, eax

    call sfMusic_play
    add esp, 4
    ret
game_play_music ENDP


    test eax, eax



    add esp, 8
    test eax, eax







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


    add esp, 4
    test eax, eax
    jz @exit_program               ; �p�G�ɶ���^�L�ġA�h�X�{��

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

    add esp, 4

    call sfSprite_destroy
    add esp, 4

    add esp, 4

    add esp, 4

    add esp, 4

    ret
main_game_page ENDP

END main_game_page