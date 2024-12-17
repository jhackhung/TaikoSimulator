.686P
.XMM
.model flat, c
include csfml.inc
;include windows.inc

extern currentPage: DWORD

.data
    ; �ɮ׸��|
    bg_path db "assets/main/game_bg.jpg", 0
    font_path db "assets/main/Taiko_No_Tatsujin_Official_Font.ttf", 0

    selected_music_path db "assets/main/song1.ogg", 0
    ;selected_beatmap1_path db "assets/main/beatmap1.tja", 0
    selected_beatmap1 db "1001201000102010,1001202000002222,1001201000102000,0000000000112212", 0
    red_note_path db "assets/main/red_note.png", 0
    blue_note_path db "assets/main/blue_note.png", 0

    ; CSFML ����
    bgTexture dd 0               ; �I�����z
    bgSprite dd 0                ; �I�����F
    ;circleTexture dd 0           ; ��έ��ů��z
    ;circleSprite dd 0            ; ��έ��ź��F
    redNoteTexture dd 0          ; ���⭵�ů��z
    blueNoteTexture dd 0         ; �Ŧ⭵�ů��z
    ;noteSprite dd 256 DUP(0)     ; ���ź��F
    noteSprite dd 0     ; ���ź��F
    font dd 0                    ; �r��
    scoreText dd 0               ; ���Ƥ�r
    comboText dd 0               ; �s����r
    bgMusic dd 0

    ; �����]�w
    ;window_videoMode sfVideoMode <1280, 720, 32>
    window_realWidth dd 044a00000r ; 1280.0
    ; �ƥ󵲺c
    event sfEvent <>

    ; �e���]�w
    window_videoMode sfVideoMode <1280, 720, 32> ; �����j�p�P�榡
    windowTitle db "Taiko Simulator", 0          ; �������D
    scrollSpeed REAL4 5.0        ; ���źu�ʳt��
    laneHeight REAL4 600.0       ; ���ŭy�D����

    ; �C��`��
    whiteColor sfColor <255, 255, 255, 255> ; �զ�
    blackColor sfColor <0, 0, 0, 255>       ; �¦�

.code

; ���J�I��
@load_bg PROC
    ; �ЫحI�����z
    push 0
    push offset bg_path
    call sfTexture_createFromFile
    add esp, 8
    mov bgTexture, eax
    
    ; �ЫحI�����F
    call sfSprite_create
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
@load_bg ENDP

; ���J����
@load_note PROC
    ; �Ыح��ů��z
    push 0
    push offset red_note_path
    call sfTexture_createFromFile
    add esp, 8
    mov redNoteTexture, eax
    
    ; �Ыح��ź��F
    call sfSprite_create
    mov DWORD PTR [noteSprite], eax
    
    ; �]�w���z
    push 1
    mov eax, DWORD PTR [redNoteTexture]
    push eax
    mov ecx, DWORD PTR [noteSprite]
    push ecx
   call sfSprite_setTexture
    add esp, 12

    ; �Ыئ�m�V�q 
    push 200 ; y �y��
    push 700  ; x �y��
    push ecx
    call sfSprite_setPosition
    add esp, 12

    ret
@load_note ENDP


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

main_game_page PROC window:DWORD

   ; ���J�I��
    call @load_bg
    test eax, eax
    jz @exit_program

    ; ���J����
    call @load_note
    test eax, eax
    jz @exit_program
    
    ;mov bgMusic, 0
    call game_play_music

@main_loop:
    
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exit_program

    @event_loop:
        ; �ƥ�B�z
        lea esi, event
        push esi
        mov eax, window
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @render_window
    
        ; �ˬd�����ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end

        ; �ˬd�ƹ��I��
        cmp dword ptr [esi].sfEvent._type, sfEvtMouseButtonPressed
        je @render_window

        ; �ˬd����ƥ� (���U�ť���������ŧP�w)
        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @end

        jmp @event_loop
    
@render_window: 
    ; �M������
    push blackColor
    push window
    call sfRenderWindow_clear
    add esp, 8
    
    ; ø�s�I��
    push 0
    mov eax, DWORD PTR [bgSprite]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

    push 0
    mov eax, DWORD PTR [noteSprite]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

    ; ��ܵ���
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

@end:
    mov DWORD PTR [currentPage], -1

@exit_program:
     push bgMusic
    call sfMusic_destroy
    add esp, 4

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push scoreText
    call sfText_destroy
    add esp, 4

    push comboText
    call sfText_destroy
    add esp, 4

    push font
    call sfFont_destroy
    add esp, 4 

    ;push circleSprite
    ;call sfSprite_destroy
    ;add esp, 4

    push blueNoteTexture
    call sfTexture_destroy
    add esp, 4

    push redNoteTexture
    call sfTexture_destroy
    add esp, 4

    push NoteSprite
    call sfTexture_destroy
    add esp, 4

    ret

main_game_page ENDP

END main_game_page