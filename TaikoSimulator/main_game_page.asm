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
	consoleHandle dd ?
	event sfEvent <>

	chart db "assets/game/yoasobi.txt", 0
	bgPath db "assets/game/bg_genre_2.png", 0
	redNotePath db "assets/game/red_note.png", 0
	blueNotePath db "assets/game/blue_note.png", 0

	stats GameStats <>
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
	notes dword 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1
	totalNotes dword 23
	noteSpawnInterval real4 0.0
	noteTimings real4 0.000000, 0.923077, 1.846154, 2.769229, 3.653842, 7.384611, 8.307688, 9.230764, 10.153841, 11.076918, 12.884617, 14.769233, 15.692309, 16.615387, 17.538464, 18.461540, 19.384617, 20.307693, 22.153847, 23.076923, 24.000000, 24.923077, 25.846153
	drumStep real4 7.493056

	; color
	blackColor sfColor <0, 0, 0, 255>
	transparentColor sfColor <0, 0, 0, 50>

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
    real_30 real4 30.0
	real_32 real4 32.0
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
    subss xmm0, real_365
    comiss xmm0, real_0
    jnl SkipFrontRemoval

    ; �����L�ɭ���
    push [esi]
    call sfSprite_destroy
    add esp, 4
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
    push blackColor
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

processHit proc
    push ebp
    mov ebp, esp
    sub esp, 32                          ; Local stack space
    
    ; Save registers
    push ebx
    push esi
    push edi
    
    ; Get parameters (cdecl)
    mov ebx, [ebp + 8]                   ; hitType in ebx
    
    ; Check if size == 0
    mov eax, dword ptr [_size]
    test eax, eax
    jz done_processing
    
    ; Get drum position
    mov eax, dword ptr [front]           ; Load front index
    mov ecx, 24                          ; sizeof(DrumNote)
    mul ecx                              ; eax = front * 24
    add eax, dword ptr [drumQueue]       ; Base address of current drum
    push eax                             ; Push sprite pointer
    call sfSprite_getPosition            ; Call function (cdecl)
    add esp, 4                           ; Clean stack
    
    ; Calculate distance
    mov ecx, dword ptr [real_450]        ; HIT_POSITION_X
    sub ecx, 46                          ; HIT_POSITION_X - 46
    fld dword ptr [eax]                  ; Load x position
    fsub dword ptr [ecx]                 ; Calculate distance
    fstp dword ptr [ebp-4]              ; Store distance
    
    ; Check distance thresholds
    fld dword ptr [ebp-4]               ; Load distance
    fabs                                ; Get absolute value
    fld dword ptr [real_good_threshold]      ; Load GOOD_THRESHOLD
    fcompp                              ; Compare and pop both
    fstsw ax                           ; Store FPU status
    sahf                               ; Transfer to CPU flags
    ja done_processing                 ; If abs(distance) > GOOD_THRESHOLD
    
    ; Check note type match
    mov eax, dword ptr [front]
    mov ecx, 24
    mul ecx
    add eax, dword ptr [drumQueue]
    mov edx, dword ptr [eax+4]           ; Load drum type
    cmp edx, ebx                       ; Compare with hitType
    jne miss_hit
    
    ; Check for GREAT hit
    fld dword ptr [ebp-4]              ; Reload distance
    fabs
    fld dword ptr [real_great_threshold]
    fcompp
    fstsw ax
    sahf
    ja good_hit
    
great_hit:
    mov esi, dword ptr [stats]         ; Get stats pointer
    inc dword ptr [esi + GameStats.great_count]      ; Increment great_count
    inc dword ptr [esi + GameStats.current_combo]    ; Increment current_combo
    
    ; Calculate score
    mov edx, dword ptr [esi + GameStats.current_combo]  ; Get current_combo
    imul edx, 10                       ; combo * 10
    add edx, 300                       ; Add base score
    add dword ptr [esi + GameStats.total_score], edx  ; Add to total_score
    
    ; Update max combo
    mov edx, dword ptr [esi + GameStats.current_combo]  ; Get current_combo
    cmp edx, dword ptr [esi + GameStats.max_combo]      ; Compare with max_combo
    jle do_dequeue
    mov dword ptr [esi + GameStats.max_combo], edx      ; Update max_combo
    jmp do_dequeue
    
good_hit:
    mov esi, dword ptr [stats]         ; Get stats pointer
    inc dword ptr [esi + GameStats.good_count]       ; Increment good_count
    inc dword ptr [esi + GameStats.current_combo]    ; Increment current_combo
    
    ; Calculate score
    mov edx, dword ptr [esi + GameStats.current_combo]  ; Get current_combo
    imul edx, 5                        ; combo * 5
    add edx, 100                       ; Add base score
    add dword ptr [esi + GameStats.total_score], edx  ; Add to total_score
    
    ; Update max combo
    mov edx, dword ptr [esi + GameStats.current_combo]  ; Get current_combo
    cmp edx, dword ptr [esi + GameStats.max_combo]      ; Compare with max_combo
    jle do_dequeue
    mov dword ptr [esi + GameStats.max_combo], edx      ; Update max_combo
    jmp do_dequeue
    
miss_hit:
    mov esi, dword ptr [stats]         ; Get stats pointer
    inc dword ptr [esi + GameStats.miss_count]       ; Increment miss_count
    mov dword ptr [esi + GameStats.current_combo], 0  ; Reset current_combo
    jmp done_processing
    
do_dequeue:
    call dequeue                       ; Remove the hit note (cdecl)
    
done_processing:
    ; Restore registers
    pop edi
    pop esi
    pop ebx
    
    mov esp, ebp
    pop ebp
    ret

processHit endp

main_game_page PROC window:dword,musicPath:dword,noteChart:dword
	
	mov dword ptr [noteChart], offset chart
	push dword ptr [noteChart]
	call readNoteChart
	add esp, 4

	; load background
	call @ld_background

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

@main_loop:
	mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je exit_program

    push spawnClock  ; �I�ssfClock_getElapsedTime�����microseconds
    call sfClock_getElapsedTime
    cvtsi2ss xmm1, eax

    movss xmm0, [real_1000000]
    divss xmm1, xmm0

    ; ���H1000000.0�H�ഫ����
    movss dword ptr [currentTime], xmm1

	mov eax, gameStarted
	cmp eax, 0
	jne deter_offset

	; check game start
	push music 
	call sfMusic_getStatus
	add esp, 4
	cmp eax, sfPlaying
	je skip_music_play

	; ��� currentTime >= msInfo_offset
    movss xmm0, [msInfo._offset]     ; �[�� musicInfo.offset
    ucomiss xmm1, xmm0               ; ��� currentTime �M musicInfo.offset
    jb skip_music_play               ; �p�G currentTime < musicInfo.offset ���L

    ; ��� msInfo_offset > 0
    fldz                             ; st(0) = 0.0
    fld msInfo._offset               ; st(1) = 0.0, st(0) = musicInfo.offset
    fcomip st(0), st(1)              ; ��� st(0) �P 0.0
    jbe skip_music_play              ; �p�G musicInfo.offset < 0 ���L
    fstp st(0)                       ; �M���B�I���|

    ; ���񭵼�
    push music
    call sfMusic_play
	add esp, 4
skip_music_play:
    ; ���m����
    push spawnClock
    call sfClock_restart

    ; �]�w gameStartTime = 0.0f
    fldz                             ; �[�� 0.0
    fstp gameStartTime

    ; �]�w gameStarted = 1
    mov gameStarted, 1

deter_offset:
	mov eax, gameStarted
	cmp eax, 1
	jne @event_loop

	; ��� musicInfo.offset < 0
    fldz                             ; st(0) = 0.0
    fld msInfo._offset               ; st(1) = 0.0, st(0) = musicInfo.offset
    fcomip st(0), st(1)              ; ��� musicInfo.offset �M 0.0
    jae @event_loop                  ;�p�G offset >= 0�A���L
    fstp st(0)                       ; �M���B�I���|

	; �I�s sfMusic_getStatus ���ˬd�O�_�� sfPlaying
    push music
    call sfMusic_getStatus
	add esp, 4
    cmp eax, sfPlaying               ; �����^�ȻP sfPlaying
    je @event_loop                  ; �p�G���֥��b����A���L

    ; �p�� currentTime >= -musicInfo.offset
    fld msInfo._offset              ; st(0) = musicInfo.offset
    fchs                             ; st(0) = -musicInfo.offset
    fld currentTime                  ; st(1) = currentTime, st(0) = -musicInfo.offset
    fcomip st(0), st(1)              ; ��� currentTime �M -musicInfo.offset
    jb @event_loop                  ; �p�G currentTime < -musicInfo.offset�A���L
    fstp st(0)                       ; �M���B�I���|

    ; ���񭵼�
    push music
    call sfMusic_play
	add esp, 4

	@event_loop:
		; �ƥ�B�z
        lea esi, event
        push esi
        mov eax, DWORD PTR [window]
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @controll_drum
    
        ; �ˬd�����ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end

		cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je check_gameStarted

check_gameStarted:
        cmp gameStarted, 1
        je @check_key_press

        jmp @event_loop

		@check_key_press:
			cmp dword ptr [esi+4], sfKeyF
            je @red_pressed

            cmp dword ptr [esi+4], sfKeyJ
            je @red_pressed

            cmp dword ptr [esi+4], sfKeyD
            je @blue_pressed

            cmp dword ptr [esi+4], sfKeyK
            je @blue_pressed     
            
            jmp @event_loop
	@red_pressed:
		push 1
		call processHit
		add esp, 4
		jmp @controll_drum
	@blue_pressed:
		push 2
		call processHit
		add esp, 4
		jmp @controll_drum

	@controll_drum:
		mov eax, gameStarted
		cmp eax, 0
		je @render_window

        push spawnClock  ; �I�ssfClock_getElapsedTime�����microseconds
        call sfClock_getElapsedTime
        cvtsi2ss xmm1, eax

        movss xmm0, [real_1000000]
        divss xmm1, xmm0

        ; ���H1000000.0�H�ഫ����
        movss dword ptr [currentTime], xmm1

spawn_loop:
        ;���currentNoteIndex < totalNotes
        mov eax, currentNoteIndex
        mov ebx, totalNotes
        cmp eax, ebx
        jae skip_spawn

        ; ��� currentTime >= noteTimings[currentNoteIndex]
        movss xmm0, [currentTime]              ; �[�� currentTime
        mov ebx, currentNoteIndex               ; ebx = currentNoteIndex
        shl ebx, 2                              ; �p����ު��첾 (4�r�`���)
        movss xmm1, noteTimings[ebx]            ; �[�� noteTimings[currentNoteIndex]
        ucomiss xmm0, xmm1                      ; ��� currentTime �P noteTimings
        jb loop_end                             ; �p�G currentTime < noteTimings, ���L�j��

        ; �ˬd notes[currentNoteIndex] != 0
        mov eax, currentNoteIndex               ; eax = currentNoteIndex
        mov ebx, notes[eax*4]                   ; ebx = notes[currentNoteIndex]
        cmp ebx, 0                              ; ��� notes[currentNoteIndex] == 0
        je skip_spawn                           ; �p�G����0�A���L spawnDrum

        ; �I�s spawnDrum(notes[currentNoteIndex], noteTimings[currentNoteIndex])

        sub esp, 4
        movss dword ptr [esp], xmm1               ; �NnoteTimings[currentNoteIndex]���J���|
        push ebx                                ; �Nnotes[currentNoteIndex]���J���|
        call spawnDrum
        add esp, 8                              ; �M�z���|

    skip_spawn:
        ; ��s currentNoteIndex++
        inc currentNoteIndex
        jmp spawn_loop                          ; ��^�j��_�I

    loop_end:
        ; �I�s updateDrums �禡
        call updateDrums

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

        ; ø�s����
        mov eax, _size
        test eax, eax
        jz @deter_music_stop
        mov loop_index, eax
        mov edi, front
    draw_notes:
        mov eax, loop_index
        cmp eax, 0
        jz @deter_music_stop

        push 0
        mov eax, [drumQueue + edi*4]
		push dword ptr [eax]
        mov ecx, DWORD PTR [window]
        push ecx
        call sfRenderWindow_drawSprite
        add esp, 8

        cmp edi, MAX_DRUMS
        jne @next_note
        mov edi, 0

    @next_note:
        inc edi
        mov eax, loop_index
        dec eax
        mov loop_index, eax
        jmp draw_notes
        

    @deter_music_stop:
        push music
        call sfMusic_getStatus
        add esp, 4
        cmp eax, sfStopped
        jne @display
        mov eax, currentNoteIndex
        cmp eax, totalNotes
        jne @display

        jmp @end_game

    @display:
        ; ø�s�P�w��
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

    ; ����귽
	push music
	call sfMusic_destroy
	add esp, 4

	push 0
	call sfTexture_destroy
	add esp, 4

	push 0
	call sfSprite_destroy
	add esp, 4

	push 0
	call sfCircleShape_destroy
	add esp, 4

	push 0
	call sfFont_destroy
	add esp, 4

	push 0
	call sfText_destroy
	add esp, 4

@end_game:
    push stats.max_combo
    push stats.total_score
    push stats.miss_count
    push stats.good_count
    push stats.great_count
    push window
    call end_game_page
    add esp, 24

exit_program:

	ret
main_game_page ENDP

END main_game_page