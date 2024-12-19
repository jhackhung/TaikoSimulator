.model flat, c
include csfml.inc
include windows.inc

extern currentPage: DWORD

GENERIC_READ equ 80000000h
FILE_ATTRIBUTE_NORMAL equ 80h
STD_OUTPUT_HANDLE equ -11

.data
    ; �ɮ׸��|
    bg_path db "assets/main/bg_genre_2.png", 0
    red_drum_path db "assets/main/red_note.png", 0
    blue_drum_path db "assets/main/blue_note.png", 0
    selected_music_path db "assets/music/never-gonna-give-you-up-official-music-video.mp3", 0
    selected_beatmap_path db "assets/music/song1_beatmap.tja", 0

    ;�`��
    MAX_DRUMS equ 100 
    Drum_struct_size equ 8     ; Drum ���c�j�p
    MAX_NOTES equ 10000
    MAX_LINE_LENGTH equ 1000
    SCREEN_WIDTH equ 1280
    SCREEN_HEIGHT equ 720
    DRUM_SPEED equ 0.5

    ; CSFML ����
    bgTexture dd 0
    bgSprite dd 0
    redDrumTexture dd 0
    blueDrumTexture dd 0
    drumQueue dd MAX_DRUMS * Drum_struct_size DUP(0)   ; type�� Drum ��Queue
    bgmusic dd 0

    ; Drum ���c
    Drum_struct dd 0         ; sprite
                dd 0         ; type(1 = ���⹪, 2 = �Ŧ⹪)

    ;Queue ����
    front dd 0
    rear dd 0
    qsize dd 0

    ; �ɶ�����
    clock dd 0
    note_timer REAL4 0.0       ; ���ťͦ��p�ɾ�
    ;note_interval REAL4 1.0    ; �C 1 ��ͦ��@�ӭ���

    ;�Э�����
    bpm dd 113.65 ; �w�] BPM
    noteSpawnInterval dd 0.0  ; ���ťͦ����j (�@��)
    notes dd MAX_NOTES DUP(0) ; �x�s���żƾ�
    totalNotes dd 0

    ; �����]�w
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0
    ;scrollSpeed REAL4 -0.5      ; ���źu�ʳt�� (�V������)

    ; �C��`��
    whiteColor sfColor <255, 255, 255, 255> ; �զ�
    blackColor sfColor <0, 0, 0, 255>       ; �¦�

    ;notePosition sfVector2f <1200.0, 200.0>  ; ���Ū� X �M Y �y��
    ;movePosition sfVector2f <-0.1, 0.0>

    ;Ū�ɬ���
    stdout_handle dd 0

    filename db "song1_beatmap.tja", 0
    hFile dd 0
    bytesRead dd 0
    readBuffer db 1024 dup(0)

    msgReadFail db "Read file failed.", 13, 10, 0

    msgReadSuccess db "File content:", 13, 10, 0


.code

;���񭵼�
game_play_music PROC
    push offset selected_music_path
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
game_play_music ENDP

; Ū����󤺮e
readFile PROC
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

; ���J�������z
@load_drums PROC
    push 0
    push offset red_drum_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov redDrumTexture, eax

    push 0
    push offset blue_drum_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov blueDrumTexture, eax

    ret
@fail_load:
    mov eax, 0
    ret
@load_drums ENDP

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
    mov eax, redDrumTexture
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

    ; ���J�������z
    call @load_drums
    test eax, eax
    jz @exit_program

    ;���J����
    call game_play_music
    test eax, eax
    jz @exit_program

    ; ���Jtja��
    push offset notes_path
    call parseNoteChart
    test eax, eax
    jz @exit_program

    ; ��l�ƭp�ɾ�
    call sfClock_create
    test eax, eax
    jz @exit_program
    mov clock, eax

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

    ; �����L����ഫ�����
    mov ebx, 1000000  ; 1,000,000 �Ω�N�L���ഫ����
    xor edx, edx      ; �M�� edx�A�ǳƶi�氣�k�ާ@
    div ebx           ; eax = microseconds / 1,000,000 (���)
    cvtsi2ss xmm0, eax

    ; �P�_�O�_�ͦ��s������
    movss xmm1, note_interval
    comiss xmm0, xmm1
    jb @skip_generate_note  ; �Y���ťͦ����j���F�@��A���L

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

@exit_program:
    call @cleanup_notes

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push redDrumTexture
    call sfTexture_destroy
    add esp, 4

    push blueDrumTexture
    call sfTexture_destroy
    add esp, 4

    push clock
    call sfClock_destroy
    add esp, 4

    ret
main_game_page ENDP

END main_game_page
