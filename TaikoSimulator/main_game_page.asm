.686P
.XMM

.model flat, c
include csfml.inc

extern currentPage: DWORD
extern create_button: PROC
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

BUTTON_STATE_NORMAL equ 0
BUTTON_STATE_PRESSED equ 1

Button STRUCT
    shape dd ?
    state dd ?
Button ENDS

; Drum ���c
Drum STRUCT
    sprite dd 0
    dtype dd 0      ; 1 = ���⹪, 2 = �Ŧ⹪
Drum ENDS

.data
    ; �ɮ׸��|
    bg_path db "assets/main/game_background.jpg", 0
    red_drum_path db "assets/main/red_note.png", 0
    blue_drum_path db "assets/main/blue_note.png", 0
    selected_music_path db "assets/main/song1.ogg", 0
    selected_beatmap_path db "assets/music/song1_beatmap.tja", 0
    selectedMusicPath db "assets/main/song2.ogg", 0
    selectedBeatmapPath db "assets/main/song1.tja", 0
    red_note_sound_path db "assets/main/RedNote.wav", 0
    blue_note_sound_path db "assets/main/BlueNote.wav", 0

    ;�`��
    MAX_DRUMS equ 100 
    Drum_struct_size equ 8     ; Drum ���c�j�p
    MAX_NOTES equ 10000
    MAX_LINE_LENGTH equ 1000
    SCREEN_WIDTH equ 1280.0
    SCREEN_HEIGHT equ 720
    DRUM_SPEED dd 0.5
    track_height REAL4 100.0
    track_width REAL4 1280.0
    track_x REAL4 640.0
    track_y REAL4 200.0
    spritePosX    dd 0.0
    spritePosY    dd 0.0
    outline_thickness REAL4 3.0




    ; CSFML ����
    bgTexture dd 0
    bgSprite dd 0
    redDrumTexture dd 0
    blueDrumTexture dd 0
    drumQueue dd MAX_DRUMS * Drum_struct_size DUP(0)
    bgmusic dd 0
    trackBounds sfFloatRect <>
    track_shape Button <>
    current_drum Drum <>

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
    noteSpawnInterval REAL4 0.0  ; ���ťͦ����j (�@��)

    totalNotes dd 0

    ; �����]�w
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0
    ;scrollSpeed REAL4 -0.5      ; ���źu�ʳt�� (�V������)

    ; �ƥ󵲺c
    event sfEvent <>

    ; �T�{��L����, �l�ܫ���O�_���U
    KeyA_state dd 0
    KeyD_state dd 0
    KeyS_state dd 0 ;   for testing

    ; �C��`��
    whiteColor sfColor <255, 255, 255, 255> ; �զ�
    blackColor sfColor <0, 0, 0, 255>       ; �¦�
    gray_color sfColor <169, 169, 169, 255>
    dark_gray_color sfColor <105, 105, 105, 255>
    light_gray_color sfColor <210, 210, 210, 255>
    beige_color sfColor <255, 239, 198, 255>
    black_color sfColor <0, 0, 0, 255>

    initialPosition sfVector2f <SCREEN_WIDTH, 200.0>  ; ���Ū� X �M Y �y��
    ;movePosition sfVector2f <-0.1, 0.0>


    ; ���Ŭ���
    notes db 256 DUP(0)
    noteTimings REAL4 256 DUP(0.0)

    ;Ū�ɬ���
    stdout_handle dd 0

    filename db "rickroll.txt", 0
    hFile dd 0
    bytesRead dd 0
    readBuffer db 1024 dup(0)

    musicInfo_bpm REAL4 0.0
    musicInfo_offset REAL4 0.0

    lineBuffer db MAX_LINE_LENGTH DUP(0)
    noteSection db 0
    currentTime REAL4 0.0

    bpmTag db "BPM:", 0
    offsetTag db "OFFSET:", 0
    startTag db "#START", 0
    endTag db "#END", 0
    comma db ",", 0

    drumSpeed REAL4 0.0
    drumStep REAL4 0.0

    msgReadFail db "Read file failed.", 13, 10, 0
    msgReadSuccess db "File content:", 13, 10, 0


    notePosition sfVector2f <1200.0, 200.0>  ; ���Ū� X �M Y �y��
    movePosition sfVector2f <-0.1, 0.0>
    
     ; �P�w���f (�H�@��p)
    hitWindowGreat DWORD 35   ; "Great" �P�w�d��
    hitWindowGood  DWORD 80   ; "Good" �P�w�d��
    hitWindowMiss  DWORD 120  ; "Miss" �P�w�d��

    ; �ΨӦsgreat good miss �����ƩM�̫��`��
    great_count DWORD 0
    good_count DWORD 0
    miss_count DWORD 0
    score DWORD 0

   

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

create_track PROC
     ; ��l�ƭy�D
    push ecx
    movss xmm0, dword ptr [track_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [track_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [track_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [track_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [track_shape], eax
    mov dword ptr [track_shape.state], BUTTON_STATE_NORMAL

    ; �ק侀��������C��M���
    push blackColor  ; �¦�
    push dword ptr [track_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push whiteColor  ; �զ����
    push dword ptr [track_shape]
    call sfRectangleShape_setOutlineColor
    add esp, 8
    ret   
create_track ENDP

; ���J�������z
@load_red_texture PROC

    push 0
    push offset red_drum_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov redDrumTexture, eax

    ret
@fail_load:
    mov eax, 0
    ret
@load_red_texture ENDP

; ���J�Ź����z
@load_blue_texture PROC
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
@load_blue_texture ENDP

isQueueFull PROC
    mov eax, qsize
    cmp eax, MAX_DRUMS
    je queue_full
    mov eax, 0

queue_full:
    mov eax, 1

    ret
isQueueFull ENDP

isQueueEmpty PROC
    mov eax, qsize
    cmp eax, 0
    je queue_empty
    mov eax, 0

queue_empty:
    mov eax, 1

    ret
isQueueEmpty ENDP

enqueue PROC
    call isQueueFull
    cmp eax, 1
    je end_enqueue
    
    mov eax, [current_drum.sprite]      ; sprite
    mov ebx, [current_drum.dtype]       ; dtype
    lea edi, drumQueue

    ; �p���\���m
    mov eax, [rear]        
    mov edx, Drum_struct_size
    mul edx                  
    add edi, eax 

    ; �x�sdrum���
    mov [edi], eax           ; sprite
    mov [edi + 4], ebx       ; dtype

    ; ��srear�Bsize
    inc dword ptr [rear]
    mov eax, [rear]
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov dword ptr [rear], edx
    inc dword ptr [qsize]

end_enqueue:
    ret
enqueue ENDP

dequeue PROC
    call isQueueEmpty
    cmp eax, 1
    je end_dequeue

    ; �p�Ⲿ����m
    lea edi, drumQueue
    mov eax, [front]
    mov edx, Drum_struct_size
    mul edx
    add edi, eax

    ; Ū�� drum
    mov eax, [edi]           ;sprite
    mov ebx, [edi + 4]       ;dtype

    ;����귽
    push eax
    call sfSprite_destroy
    add esp, 4

    ; ��sfront�Bsize
    inc dword ptr [front]
    mov eax, [front]
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov dword ptr [front], edx
    dec dword ptr [qsize]

end_dequeue:
    ret
dequeue ENDP

spawnDrum PROC             ;call�etype�n��push��eax
    call isQueueFull
    cmp eax, 1
    je end_spawn

    mov dword ptr [current_drum.dtype], eax
    call sfSprite_create
    mov DWORD PTR [current_drum.sprite], eax

    cmp dword ptr [current_drum.dtype], 1
    je spawnRed
    call @load_blue_texture

spawnRed:
    call @load_red_texture

    ;�]�w��m
    push dword ptr [initialPosition+4] ; Y �y��
    push dword ptr [initialPosition]   ; X �y��
    push eax
    call sfSprite_setPosition
    add esp, 12

    call enqueue

end_spawn:
    ret
spawnDrum ENDP

updateDrums PROC
    cmp qsize, 0
    jbe end_update
    
    lea edi, drumQueue
    mov eax, [front]
    mov edx, Drum_struct_size
    mul edx
    add edi, eax

    ; Ū�� drum
    mov eax, [edi]           ;sprite
    mov ebx, [edi + 4]       ;dtype

    push eax
    call sfSprite_getPosition
    add esp, 8

    movss [spritePosX], xmm0
    add [spritePosX], 50
    cmp [spritePosX], 50
    jae end_update

    call dequeue

    mov ecx, qsize
    mov ebx, front
update_queue:
    ; Ū�� drum
    mov eax, [edi]           ;sprite

    push eax
    call sfSprite_getPosition
    add esp, 8
    
    movss [spritePosX], xmm0
    movss [spritePosY], xmm1
    movss xmm0, [spritePosX]
    movss xmm1, [DRUM_SPEED]
    subss xmm0, xmm1
    movss [spritePosX], xmm0

    push dword ptr [spritePosY] ; Y �y��
    push dword ptr [spritePosX]   ; X �y��
    push eax
    call sfSprite_setPosition
    add esp, 12

    inc ebx
    mov eax, ebx
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov ebx, edx

loop update_queue

end_update:
    ret
updateDrums ENDP

;���񭵮�
rednote_sound PROC
    push offset red_note_sound_path
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
rednote_sound ENDP

bluenote_sound PROC
    push offset blue_note_sound_path
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
bluenote_sound ENDP

readFile PROC
    ; Ū����󤺮e
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

main_game_page PROC window:DWORD

    ; ���J�I��
    call @load_bg
    test eax, eax
    jz @exit_program

    ; ���J�������z
    call @load_red_texture
    test eax, eax
    jz @exit_program

    ; ���J�Ź����z
    call @load_blue_texture
    test eax, eax
    jz @exit_program

    ;���J����
    call game_play_music
    test eax, eax
    jz @exit_program

    ; ���Jtja��
    ;push offset selected_beatmap_path
    ;call parseNoteChart
    ;test eax, eax
    ;jz @exit_program

    ; ��l�ƭp�ɾ�
    ;call sfClock_create
    ;test eax, eax
    ;jz @exit_program
    ;mov clock, eax

   

@main_loop:

    ; �ˬd���֬O�_����
    push bgMusic
    call sfMusic_getStatus
    add esp, 4
    cmp eax, 0
    je @to_end_page

    ; �ˬd�����O�_�}��
    mov eax, window
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exit_program


    ; ��s�p�ɾ�
    ;mov eax, clock
    ;push eax
    ;call sfClock_getElapsedTime
    ;add esp, 4
    ;test eax, eax
    ;jz @exit_program               ; �p�G�ɶ���^�L�ġA�h�X�{��

    ; �ˬd���֬O�_����
    push bgMusic
    call sfMusic_getStatus
    add esp, 4
    cmp eax, 0
    je @to_end_page

    ; �����L����ഫ�����
    ;mov ebx, 1000000  ; 1,000,000 �Ω�N�L���ഫ����
    ;xor edx, edx      ; �M�� edx�A�ǳƶi�氣�k�ާ@
    ;div ebx           ; eax = microseconds / 1,000,000 (���)
    ;cvtsi2ss xmm0, eax

    ; �P�_�O�_�ͦ��s������
    ;movss xmm1, note_interval
    ;comiss xmm0, xmm1
    ;jb @skip_generate_note  ; �Y���ťͦ����j���F�@��A���L

    ; �ͦ����Ũí��m�p�ɾ�
    ;call @generate_note
    ;call sfClock_restart           ; ���m����

    @event_loop:
        ; �ƥ�B�z
        lea esi, event
        push esi
        mov eax, window
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @skip_generate_note
    
        ; �ˬd�����ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @skip_generate_note

        ; �ˬd�ƹ��I��
        cmp dword ptr [esi].sfEvent._type, sfEvtMouseButtonPressed
        je @to_end_page
    
        ; �ˬd��L�ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @check_key_press

        jmp @event_loop

        @check_key_press:
            cmp dword ptr [esi+4], sfKeyA
            je @key_A_pressed

            cmp dword ptr [esi+4], sfKeyS
            je @key_S_pressed 

            cmp dword ptr [esi+4], sfKeyD
            je @key_D_pressed 
            
            jmp @event_loop

@key_A_pressed:
    mov dword ptr [KeyA_state], 1 ; �]�w���A�w���U 
    mov dword ptr [KeyS_state], 0
    mov dword ptr [KeyD_state], 0
    call rednote_sound
    push eax
    add esp, 4
    ; delete the the latest note
    jmp @event_loop

@key_S_pressed:
    mov dword ptr [KeyS_state], 1 ; �]�w���A�w���U
    mov dword ptr [KeyA_state], 0
    mov dword ptr [KeyD_state], 0
    push eax
    add esp, 4
    jmp @to_end_page


@key_D_pressed:
    mov dword ptr [KeyD_state], 1 ; �]�w���A�w���U
    mov dword ptr [KeyA_state], 0
    mov dword ptr [KeyS_state], 0
    call bluenote_sound
    push eax
    add esp, 4
    ; delete the the latest note
    jmp @event_loop
       

@skip_generate_note:
    ; ��s����
    ;call @update_notes

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

    ;ø�s�y�D
    ;push 0
    ;mov eax, DWORD PTR [track_shape]
    ;push eax
    ;mov ecx, DWORD PTR [window]
    ;push ecx
    ;call sfRenderWindow_drawRectangleShape
    ;add esp, 12

    ; ø�s����
    xor esi, esi
;@draw_notes_loop:
    ;cmp esi, noteCount
    ;jge @end_draw_notes

    ;mov eax, DWORD PTR [noteSprites + esi*4]
    ;test eax, eax
    ;jz @next_draw

    ;push 0
    ;push eax
    ;mov ecx, window
    ;push ecx
    ;call sfRenderWindow_drawSprite
    ;add esp, 12

;@next_draw:
    ;inc esi
    ;jmp @draw_notes_loop
@end_draw_notes:

    ; ��ܵ���
    mov eax, window
    push eax
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

; �ǳƵ���
@to_end_page:

    push score    
    push miss_count    
    push good_count   
    push great_count    
    push window       
    mov DWORD PTR [currentPage], 2      ;�C�������n�����쵲���e��
    add esp, 20
    jmp @exit_program



@exit_program:

    ;call @cleanup_notes

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

    ;push dword ptr [track_shape]
    ;call sfRectangleShape_destroy
    ;add esp, 4

    push bgMusic
    call sfMusic_destroy
    add esp, 4

    @end:
    xor eax, eax
    ret
main_game_page ENDP

END main_game_page
