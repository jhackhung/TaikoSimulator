.686P
.XMM
.model flat, c
include csfml.inc
include file.inc
includelib kernel32.lib

extern GetStdHandle@4: PROC
extern WriteConsoleA@20:PROC
STD_OUTPUT_HANDLE EQU -11

extern end_game_page: PROC
extern currentPage: DWORD

; Constants
MAX_NOTES = 10000
MAX_LINE_LENGTH = 1000
SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
MAX_DRUMS = 100
HIT_POSITION_X = 450 
GREAT_THRESHOLD = 4
GOOD_THRESHOLD = 30
INITIAL_DELAY = 3

.data
    ALIGN 4
    abs_mask DD 7fffffffh, 0, 0, 0

    ; �s�W��������ܼ�
    initial_delay_1 real4 2.0    ; �]�w 2 ����
    delay_started dword 0      ; �l�ܩ���O�_�}�l
    delay_clock dword 0        ; �Ω�p�ɪ�����

	consoleHandle dd ?
	event sfEvent <>

    redNoteSound dd 0    ; ���⭵�ŭ���
    blueNoteSound dd 0   ; �Ŧ⭵�ŭ���

	chart db "assets/game/yoasobi.txt", 0
	bgPath db "assets/game/bg_genre_2.jpg", 0
	redNotePath db "assets/game/red_note.png", 0
	blueNotePath db "assets/game/blue_note.png", 0
    red_note_sound_path db "assets/main/rednote.wav", 0
    blue_note_sound_path db "assets/main/bluenote.wav", 0

	stats GameStats <0, 0, 0, 0, 0, 0>
	msInfo MusicInfo <130.000000, -1.962000, 115.384613>

	; queue for drums
	drumQueue dword MAX_DRUMS dup(?) ; �s��Drum���c���w
	front dword 0
	rear dword 0
	_size dword 0

	; texture
	redDrumTexture dword ?
	blueDrumTexture dword ?

	font_path db "assets/fonts/arial.ttf", 0
	font dd 0

	; text
	countDownText dword ?

	; background
	bgTexture dword ?
	bgSprite dword ?

	; judgement circle
	judgementCircle dword ?
	
	; music
	music dword ?

	; clock
	spawnClock dword 0

	currentTime real4 0.0

	currentNoteIndex dd 0
	gameStartTime real4 3.0
	gameStarted dword 0

	; note chart
	notes dword 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
          dword 2, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1
          dword 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1
	totalNotes dword 90
	noteSpawnInterval real4 0.0
	noteTimings real4 0.000000, 0.923077, 1.846154, 2.769229, 3.653842, 7.384611, 8.307688, 9.230764, 10.153841, 11.076918, 12.884617, 14.769233, 15.692309, 16.615387, 17.538464, 18.461540, 19.384617, 20.307693, 22.153847, 23.076923, 24.000000, 24.923077, 25.846153, 26.769230, 27.692307, 29.076921, 29.538460, 31.384613, 33.230766, 35.076920
                real4 36.923073, 38.769226, 40.615379, 44.307686, 45.230762, 46.153839, 47.999992, 48.923069, 49.846146, 51.692299, 52.615376, 53.538452, 55.384605, 56.961456, 59.076828, 60.922981, 62.769135, 65.538368, 66.461449, 67.384529, 68.307610, 70.153763, 71.076843, 71.999924, 73.846077, 74.769157, 75.692238, 76.153778, 76.615318, 77.538399
                real4 78.461479, 79.384560, 79.846100, 80.307640, 81.230721, 81.692261, 82.153801, 83.076881, 83.538422, 83.999962, 84.923042, 88.615349, 89.538429, 90.461510, 90.923050, 91.384590, 92.307671, 93.230751, 94.153831, 94.615372, 95.076912, 95.999992, 96.461533, 96.923073, 97.846153, 98.307693, 98.769234, 99.692314, 100.615395, 101.538475
	drumStep real4 7.493056

	; color
	blackColor sfColor <0, 0, 0, 255>
    white_color sfColor <230, 230, 230, 200>
	transparentColor sfColor <255, 255, 255, 50>

	; file
	readA byte "r", 0

	; �r��`�q
	str_bpm db "BPM:", 0
	str_offset db "OFFSET:", 0
	str_start db "#START", 0
	str_end db "#END", 0
	comma db ",", 0
	breakline db "\n", 0
	;format db "%", 0

	getBpm db "BPM:%f", 0
	getOffset db "OFFSET:%f", 0

	real_60 real4 60.0
	real_4 real4 4.0
	real_60000 real4 60000.0
	decimal_mult  dq 0.1                  ; �p�Ʀ�ƭ���
    ten           dq 10.0                 ; �Ω󭼪k�B��
	real_2 real4 2.0
    real_15 real4 15.0
    real_30 real4 30.0
	real_32 real4 32.0
    real_46 real4 46.0
    real_64 real4 64.0
    real_200 real4 200.0
    real_225 real4 225.0
    real_450 real4 450.0
	real_720 real4 720.0
	real_1280 real4 1280.0
	real_1000000 real4 1000000.0
    real_good_threshold real4 30.0
    real_great_threshold real4 4.0
    real_365 real4 365.0
    real_0 real4 0.0
    loop_index dword 0
.code

readNoteChart PROC


readNoteChart ENDP

isQueueFull PROC
    mov eax, _size
    cmp eax, MAX_DRUMS
    sete al                ; �p�G���F�A�]�m��^�Ȭ�1
    ret
isQueueFull ENDP

isQueueEmpty PROC
    mov eax, _size
    test eax, eax
    sete al                ; �p�G�šA�]�m��^�Ȭ�1
    ret
isQueueEmpty ENDP

enqueue PROC USES edi esi ebx @drum:DWORD 
    ; �ˬd�O�_���F
    call isQueueFull
    test al, al
    jnz @end_enqueue

    ; �[�J���C
    mov esi, @drum          ; drum�Ѽ�
    mov edi, rear          ; rear����
    mov drumQueue[edi*4], esi ; �Ndrum�[�J���C

    ; ��srear�Msize
    inc rear
    cmp rear, MAX_DRUMS
    jb SkipRearWrap
    mov rear, 0
	SkipRearWrap:
		inc _size
	@end_enqueue:
		ret
enqueue ENDP

dequeue PROC
    ; �ˬd�O�_�ŤF
    call isQueueEmpty
    test al, al
    jnz QueueEmpty

    ; �R�����C�Y
    mov edi, front          ; front����
    mov esi, drumQueue[edi*4] ; ������C�Y��drum���w
    push esi
    call sfSprite_destroy   ; ����sprite
    add esp, 4

    ; ��sfront�Msize
    inc front
    cmp front, MAX_DRUMS
    jb SkipFrontWrap
    mov front, 0
SkipFrontWrap:
    dec _size
    ret

QueueEmpty:
    ret
dequeue ENDP

spawnDrum PROC USES esi edi _type:DWORD, targetTime:REAL4
    ; �ˬd�O�_���F
    call isQueueFull
    test al, al
    jnz QueueFullSpawn

    ; �Ыطs��Drum���c
    push 12                ; ���t�Ŷ�
    call malloc
    add esp, 4
    mov esi, eax           ; �O�s�s���c���w

    ; ��l��Drum���c
	push 0
    call sfSprite_create
    add esp, 4
    mov [esi], eax       ; sprite���w

	mov eax, _type
    mov dword ptr [esi+4], eax
    movss xmm0, targetTime
    movss dword ptr [esi+8], xmm0
    

    ; �]�m���Ū����z
    cmp _type, 1
    jne SetBlueTexture
    push sfTrue
    push dword ptr redDrumTexture
    push [esi]
    call sfSprite_setTexture
    add esp, 12
    jmp DoneTexture
SetBlueTexture:
    push sfTrue
    push dword ptr blueDrumTexture
    push [esi]
    call sfSprite_setTexture
    add esp, 12
DoneTexture:

    ; �]�m��l��m

    sub esp, 8
    movss xmm0, real_1280
    movss dword ptr [esp], xmm0
    movss xmm0, real_200
    movss dword ptr [esp+4], xmm0
    push [esi]
    call sfSprite_setPosition
    add esp, 12

    ; �NDrum�[�J���C
    push esi
    call enqueue
    add esp, 4
    ret

QueueFullSpawn:
    ret
spawnDrum ENDP

updateDrums PROC USES esi edi ebx
    local i:DWORD
    ; �ˬd�ò����L�ɪ�����
    mov eax, _size
    test eax, eax
    jz SkipUpdate

    mov edi, front
    mov esi, drumQueue[edi*4]
    push [esi]            ; drum.sprite
    call sfSprite_getPosition
    add esp, 4

    ; �ˬd���ŬO�_�����W�X�P�w���
    ; �P�w��饪��t = 450 - 30 = 420
    ; ���ťk��t = x + 64
    addss xmm0, real_64   ; �[�W���ťb�|�e��(��32����)
    movss xmm1, real_450  ; ���J�P�w��x�y��
    subss xmm1, real_30   ; ��h�b�|�A��o����t
    comiss xmm0, xmm1     ; ��� (note.x + width) < (circle.x - radius)
    jae SkipFrontRemoval

    ; �����L�ɭ���
    push [esi]
    call sfSprite_destroy
    add esp, 4

    ; ��smiss and current_combo �έp�ƾ�
    mov eax, offset stats
    inc dword ptr [eax+8]            ; miss_count++
    mov dword ptr [eax+12], 0        ; current_combo = 0
    
    inc front
    cmp front, MAX_DRUMS
    jb SkipFrontWrap2
    mov front, 0
SkipFrontWrap2:
    dec _size
SkipFrontRemoval:

    ; ��s���Ŧ�m
    mov eax, _size
    mov i, eax
    mov edi, front
UpdateLoop:
    mov eax, i
    cmp eax, 0
    jz EndUpdateLoop

    mov esi, drumQueue[edi*4]
    push dword ptr [esi]
    call sfSprite_getPosition
    add esp, 4

    subss xmm0, drumStep
    
    push edx
    sub esp, 4
    movss dword ptr [esp], xmm0
    push [esi]
    call sfSprite_setPosition
    add esp, 8

    inc edi
    cmp edi, MAX_DRUMS
    jb NoWrap
    mov edi, 0
NoWrap:
    mov eax, i
    dec eax
    mov i, eax
    jmp UpdateLoop
EndUpdateLoop:
SkipUpdate:
    ret
updateDrums ENDP

createJudgementCircle PROC USES esi edi
    ; �Ыض�ΧΪ�
    push 0
    call sfCircleShape_create
    add esp, 4
    mov judgementCircle, eax

    ; �]�m��Υb�|
    push real_30
    push dword ptr [judgementCircle]
    call sfCircleShape_setRadius
    add esp, 8

    ; �]�m��Φ�m
    push real_225               ; HIT_POSITION_X, 200+25
    push real_450
    push dword ptr [judgementCircle]
    call sfCircleShape_setPosition
    add esp, 12

    ; �]�m��R�C��
    push transparentColor
    push dword ptr [judgementCircle]
    call sfCircleShape_setFillColor
    add esp, 8

    ; �]�m��ثp��
    push real_2
    push dword ptr [judgementCircle]
    call sfCircleShape_setOutlineThickness
    add esp, 8

    ; �]�m����C��
    push white_color
    push dword ptr [judgementCircle]
    call sfCircleShape_setOutlineColor
    add esp, 8

    ret
createJudgementCircle ENDP

@ld_background PROC
    ; �ЫحI�����z
    push 0
    push offset bgPath
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
@ld_background ENDP

@countDown_text proc
	push 0
	push offset font_path
	call sfFont_createFromFile
	add esp, 8
	mov font, eax

	call sfText_create
	mov countDownText, eax

	push font
	push dword ptr [countDownText]
	call sfText_setFont
	add esp, 8

	push 72
	push dword ptr [countDownText]
	call sfText_setCharacterSize
	add esp, 8

	movss xmm0, [real_720]
	divss xmm0, [real_2]
	subss xmm0, [real_32]
	movss dword ptr [esp-4], xmm0

	movss xmm0, [real_1280]
	divss xmm0, [real_2]
	subss xmm0, [real_32]
	movss dword ptr [esp-8], xmm0

	mov esi, esp
	push dword ptr [esi-4]
	push dword ptr [esi-8]
	push dword ptr [countDownText]
	call sfText_setPosition
	add esp, 12

	ret
@countDown_text ENDP

processHit proc uses ebx esi edi hitType:DWORD
    local delta:DWORD
    
    ; �ˬd��C�O�_����
    call isQueueEmpty
    test al, al
    jnz @done_processing
    
    ; ����̫e��������
    mov edi, front
    mov esi, drumQueue[edi*4]
    
    ; ������Ŧ�m(���쭵��top_left��m)
    push dword ptr [esi]
    call sfSprite_getPosition
    add esp, 4
    
    ; �p��P�P�w�u���Z�� (450�O�P�w�u��m�A�]�Ojudgement circle�����) ���ߤ��
    subss xmm0, real_450
    addss xmm0, real_32 ; �[�W���ťb�|
    
    ; �������
    andps xmm0, [abs_mask]
    
    ; �����ˬd���������O�_�ǰt
    mov edx, dword ptr [esi+4]
    cmp edx, [hitType]
    jne @done_processing         ; �p�G�������ǰt�A���XprocessHit
    
    ; �P�_���ŬO�_�b�P�w�餺
    movss xmm1, real_30    ; ���J�P�w��b�|
    addss xmm1, real_32    ; �[�W���ťb�|
    comiss xmm0, xmm1      ; ������Ť����I�Z���O�_ >= 30
    jae @done_processing     ; �p�G�Z�� > 30�A�������L

    ; GREAT�P�w (�~�t <= 15)
    movss xmm1, real_15       ; ���J�P�w��b�|   
    comiss xmm0, xmm1         ; ������Ť����I�Z���O�_ <= 15
    jbe @great_hit

    ; MISS�P�w (�~�t > 40)
    ;movss xmm2, real_30       ; ���J�P�w��b�|
    ;addss xmm2, real_2        ; �[�W10�ӳ��
    ;addss xmm2, real_2
    ;addss xmm2, real_2
    ;addss xmm2, real_2
    ;addss xmm2, real_2
    ;comiss xmm0, xmm2         ; ����O�_ > 40
    ;ja @miss_hit
    
    ; ��l���p -> GOOD �~�t <= 30
    jmp @good_hit
    
@great_hit:
    mov eax, offset stats
    inc dword ptr [eax]              ; great_count
    inc dword ptr [eax+12]           ; current_combo
    
    ; �p����� (combo * 10 + 300)
    mov ecx, dword ptr [eax+12]      ; ���ocurrent_combo
    imul ecx, 10
    add ecx, 300
    add dword ptr [eax+20], ecx      ; �[��total_score
    
    ; ��smax_combo
    mov ecx, dword ptr [eax+12]      ; current_combo
    cmp ecx, dword ptr [eax+16]      ; ���max_combo
    jle @remove_note
    mov dword ptr [eax+16], ecx      ; ��smax_combo
    jmp @remove_note
    
@good_hit:
    mov eax, offset stats
    inc dword ptr [eax+4]            ; good_count
    inc dword ptr [eax+12]           ; current_combo
    
    ; �p����� (combo * 5 + 100)
    mov ecx, dword ptr [eax+12]      ; ���ocurrent_combo
    imul ecx, 5
    add ecx, 100
    add dword ptr [eax+20], ecx      ; �[��total_score
    
    ; ��smax_combo
    mov ecx, dword ptr [eax+12]      ; current_combo
    cmp ecx, dword ptr [eax+16]      ; ���max_combo
    jle @remove_note
    mov dword ptr [eax+16], ecx      ; ��smax_combo
    jmp @remove_note
    
@miss_hit:
    ;mov eax, offset stats
    ;inc dword ptr [eax+8]            ; miss_count
    ;mov dword ptr [eax+12], 0        ; current_combo = 0
    ;jmp @done_processing
    
@remove_note:
    call dequeue
    
@done_processing:
    ret 4

processHit endp

;���񭵮�
initializeSounds PROC
    ; �Ыج��⭵�ŭ���
    push offset red_note_sound_path
    call sfMusic_createFromFile
    add esp, 4
    mov redNoteSound, eax

    ; �Ы��Ŧ⭵�ŭ���
    push offset blue_note_sound_path
    call sfMusic_createFromFile
    add esp, 4
    mov blueNoteSound, eax

    ret
initializeSounds ENDP

; �ק���⭵�ŭ��Ĩ��
rednote_sound PROC
    push redNoteSound
    call sfMusic_stop    ; ������e������
    add esp, 4

    push redNoteSound
    call sfMusic_play    ; ���񭵮�
    add esp, 4
    ret
rednote_sound ENDP

; �ק��Ŧ⭵�ŭ��Ĩ��
bluenote_sound PROC
    push blueNoteSound
    call sfMusic_stop    ; ������e������
    add esp, 4

    push blueNoteSound
    call sfMusic_play    ; ���񭵮�
    add esp, 4
    ret
bluenote_sound ENDP

main_game_page PROC window:dword,musicPath:dword,noteChart:dword
    mov eax, offset stats
    mov dword ptr [eax], 0      ; great_count
    mov dword ptr [eax+4], 0    ; good_count
    mov dword ptr [eax+8], 0    ; miss_count
    mov dword ptr [eax+12], 0   ; current_combo
    mov dword ptr [eax+16], 0   ; max_combo
    mov dword ptr [eax+20], 0   ; total_score

    ; load background
    call @ld_background
    call initializeSounds    ; ��l�ƭ���

    ; load red note texture
    push 0
    push offset redNotePath
    call sfTexture_createFromFile
    add esp, 8
    mov redDrumTexture, eax

    ; load blue note texture
    push 0
    push offset blueNotePath
    call sfTexture_createFromFile
    add esp, 8
    mov blueDrumTexture, eax

    ; create judgement circle
    call createJudgementCircle

    ; create music
    push 0
    push dword ptr [musicPath]
    call sfMusic_createFromFile
    add esp, 8
    mov music, eax

    push 0
    push music
    call sfMusic_setLoop
    add esp, 8

    call sfClock_create
    mov spawnClock, eax

    ; �Ыة���p�ɾ�
    call sfClock_create
    mov delay_clock, eax

@main_loop:
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je exit_program

    ; �ˬd���𪬺A
    mov eax, delay_started
    cmp eax, 0
    jne check_game_start    ; �p�G����w�g�}�l�A�ˬd�C���}�l

    ; �}�l����p��
    mov delay_started, 1
    push delay_clock
    call sfClock_restart
    add esp, 4
    jmp @event_loop

check_game_start:
    ; �ˬd�O�_�w�g�L�F����ɶ�
    push delay_clock
    call sfClock_getElapsedTime
    cvtsi2ss xmm1, eax
    
    movss xmm0, [real_1000000]
    divss xmm1, xmm0        ; �ഫ����
    
    movss xmm0, dword ptr [initial_delay_1]
    comiss xmm1, xmm0       ; ����O�_�W�L����ɶ�
    jb @event_loop          ; �p�G�٨S�W�L����ɶ��A�~�򵥫�

    ; �p�G�W�L����ɶ��B�C���٨S�}�l�A�}�l�C��
    mov eax, gameStarted
    cmp eax, 0
    jne deter_offset

    ; �}�l���񭵼�
    push music
    call sfMusic_play
    add esp, 4

    push spawnClock
    call sfClock_restart
    add esp, 4

    fldz
    fstp gameStartTime
    mov gameStarted, 1

deter_offset:
    mov eax, gameStarted
    cmp eax, 1
    jne @event_loop

    fldz
    fld msInfo._offset
    fcomip st(0), st(1)
    jae @event_loop
    fstp st(0)

    push music
    call sfMusic_getStatus
    add esp, 4
    cmp eax, sfPlaying
    je @event_loop

    fld msInfo._offset
    fchs
    fld currentTime
    fcomip st(0), st(1)
    jb @event_loop
    fstp st(0)

    push music
    call sfMusic_play
    add esp, 4

    @event_loop:
        lea esi, event
        push esi
        mov eax, DWORD PTR [window]
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @controll_drum

        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end

        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @check_key_press

    ; check_gameStarted:
        ; cmp gameStarted, 1
        ; je @check_key_press

        jmp @event_loop

        ; �ק����B�z����
        @check_key_press:
   
            ; �ˬd�O�_�OF���J��
            cmp dword ptr [esi+4], sfKeyF
            je @handle_red
            cmp dword ptr [esi+4], sfKeyJ
            je @handle_red
    
            ; �ˬd�O�_�OD���K��
            cmp dword ptr [esi+4], sfKeyD
            je @handle_blue
            cmp dword ptr [esi+4], sfKeyK
            je @handle_blue
    
            jmp @event_loop

            @handle_red:
                call rednote_sound
                push 1                   ; ���⭵������
                call processHit
                jmp @controll_drum

            @handle_blue:
                call bluenote_sound
                push 2                   ; �Ŧ⭵������
                call processHit
                jmp @controll_drum

            @controll_drum:
                mov eax, gameStarted
                cmp eax, 0
                je @render_window

                push spawnClock
                call sfClock_getElapsedTime
                cvtsi2ss xmm1, eax

                movss xmm0, [real_1000000]
                divss xmm1, xmm0

                movss dword ptr [currentTime], xmm1

spawn_loop:
    mov eax, currentNoteIndex
    mov ebx, totalNotes
    cmp eax, ebx
    jae check_last_note    ; �p�G�Ҧ����ų��w�ͦ��A�ˬd�̫�@�ӭ���

    movss xmm0, [currentTime]
    mov ebx, currentNoteIndex
    shl ebx, 2
    movss xmm1, noteTimings[ebx]
    ucomiss xmm0, xmm1
    jb loop_end

    mov eax, currentNoteIndex
    mov ebx, notes[eax*4]
    cmp ebx, 0
    je skip_spawn

    sub esp, 4
    movss dword ptr [esp], xmm1
    push ebx
    call spawnDrum
    add esp, 8

skip_spawn:
    inc currentNoteIndex
    jmp spawn_loop

check_last_note:
    ; �ˬd�O�_�����Ŧb���C��
    mov eax, _size
    test eax, eax
    jz @end_game         ; �p�G�S�����ťB���w�ͦ��A�����C��

    ; �ˬd�̫�@�ӭ��Ū���m
    mov edi, front
    mov ecx, _size
    dec ecx              ; ����̫�@�ӭ��Ū�����
    add edi, ecx
    cmp edi, MAX_DRUMS
    jb no_wrap
    sub edi, MAX_DRUMS
no_wrap:
    mov esi, drumQueue[edi*4]
    push [esi]
    call sfSprite_getPosition
    add esp, 4
    
    ; �ˬd���ŬO�_�w���}�e��
    comiss xmm0, real_0   ; ��� x ��m�O�_�p�� 0
    jb @end_game         ; �p�G�̫�@�ӭ��Ťw���}�e���A�����C��

loop_end:
    call updateDrums

@render_window:
    push blackColor
    push window
    call sfRenderWindow_clear
    add esp, 8

    push 0
    mov eax, DWORD PTR [bgSprite]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

    mov eax, _size
    test eax, eax
    jz @display
    mov loop_index, eax
    mov edi, front

draw_notes:
    mov eax, loop_index
    cmp eax, 0
    jz @display

    push 0
    mov eax, [drumQueue + edi*4]
    push dword ptr [eax]
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

    inc edi
    cmp edi, MAX_DRUMS
    jne @next_note
    mov edi, 0

@next_note:
    mov eax, loop_index
    dec eax
    mov loop_index, eax
    jmp draw_notes

@display:
    push 0
    push dword ptr [judgementCircle]
    push DWORD PTR [window]
    call sfRenderWindow_drawCircleShape
    add esp, 12

    push window
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

@end:
    push music
    call sfMusic_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push judgementCircle
    call sfCircleShape_destroy
    add esp, 4

    push font
    call sfFont_destroy
    add esp, 4

    push countDownText
    call sfText_destroy
    add esp, 4

    ; ������⭵�ŭ���
    push redNoteSound
    call sfMusic_destroy
    add esp, 4

    ; �����Ŧ⭵�ŭ���
    push blueNoteSound
    call sfMusic_destroy
    add esp, 4

    push music
    call sfMusic_destroy
    add esp, 4

@end_game:
    push music
    call sfMusic_stop    ; �����
    add esp, 4

    push dword ptr [stats+16]    ; max_combo
    push dword ptr [stats+20]    ; total_score
    push dword ptr [stats+8]       ; miss_count
    push dword ptr [stats+4]     ; good_count
    push dword ptr [stats]     ; great_count
    push window
    call end_game_page
    add esp, 24

exit_program:
    ret

main_game_page ENDP

END main_game_page