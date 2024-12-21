.model flat, c
include csfml.inc
include windows.inc
include file.inc

extern currentPage: DWORD
EXTERN end_game_page:PROC

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
    ; �ɮ׸��|
    bg_path db "assets/main/game_background.jpg", 0
    red_drum_path db "assets/main/red_note.png", 0
    blue_drum_path db "assets/main/blue_note.png", 0
    selected_music_path db "assets/never-gonna-give-you-up-official-music-video.mp3", 0
    selected_beatmap_path db "assets/music/song1_beatmap.tja", 0

    ;�`��
    Drum_struct_size equ 12     ; Drum ���c�j�p
    spritePosX    dd 0.0
    spritePosY    dd 0.0
    const_60000 dd 60000.0
    const_1000 dd 1000.0
    four dd 4.0

    ;�ΨӦsgreat good miss �����ƩM�̫��`��
    great_count DWORD 0
    good_count DWORD 0
    miss_count DWORD 0
    score DWORD 0

    ; CSFML ����
    bgTexture dd 0
    bgSprite dd 0
    bgmusic dd 0
    trackBounds sfFloatRect <>
    current_drum Drum <>

    ;Queue ����
    index dd 0

    ; �ɶ�����
    clock dd 0
    note_timer REAL4 0.0       ; ���ťͦ��p�ɾ�

    ;�Э�����
    bpm dd 113.65 ; �w�] BPM
    currentNoteIndex dd 0

    ; �����]�w
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0

    ; �C��`��
    whiteColor sfColor <255, 255, 255, 255> ; �զ�
    blackColor sfColor <0, 0, 0, 255>       ; �¦�

    ;initialPosition sfVector2f <SCREEN_WIDTH, 200.0>  ; ���Ū� X �M Y �y��
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    stats GameStats <>
	msInfo MusicInfo <>

	; queue for drums
	drumQueue Drum MAX_DRUMS dup(<>)
	front dword 0
	rear dword 0
	_size dword 0

	; texture
	redDrumTexture dword ?
	blueDrumTexture dword ?

	notes dword MAX_NOTES dup(?)
	totalNotes dword 0
	noteSpawnInterval real4 0.0
	noteTimings real4 MAX_NOTES dup(?)
	drumStep real4 0.25

	; file
	readA byte "r", 0

	;label
	str_bpm db "BPM:", 0
	str_offset db "OFFSET:", 0
	str_start db "#START", 0
	str_end db "#END", 0
	comma db ",", 0

	getBmp db "BMP:%f", 0
	getOffset db "OFFSET:%f", 0

	real_60 real4 60.0
	real_4 real4 4.0
	real_60000 real4 60000.0


.code

;���񭵼�
game_play_music PROC musicPath:PTR BYTE
    mov eax, [musicPath]
    push musicPath          
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

parseString proc
    push ebp
    mov ebp, esp
    sub esp, 8                           ; �Ȧs��

    ; ��l�ưѼ�
    mov esi, dword ptr [ebp+8]           ; esi = inputStr
    mov edi, dword ptr [ebp+12]          ; edi = formatStr
    mov eax, 1                           ; �w�]��^�Ȭ����\

    ; �ѪR�榡�Ʀr��
next_format:
    lodsb                                ; �[���榡�r�ꤤ���U�@�Ӧr�Ũ� al
    cmp al, 0                            ; �ˬd�O�_��r�굲��
    je parse_done                        ; �p�G��r�굲���A�ѪR����

    cmp al, '%'                          ; �ˬd�O�_���榡�ƲŸ� '%'
    jne skip_format                      ; �p�G���O '%', ���L

    lodsb                                ; ���U�@�Ӯ榡�ƲŸ�
    cmp al, 'd'                          ; �ˬd�O�_�� %d
    je parse_int
    cmp al, 's'                          ; �ˬd�O�_�� %s
    je parse_string
    cmp al, 'f'                          ; �ˬd�O�_�� %f
    je parse_float
    jmp parse_error                      ; ��������榡�A�������~

skip_format:
    lodsb                                ; �~��U�@�Ӧr��
    jmp next_format

; �ѪR��� (%d)
parse_int:
    mov ebx, dword ptr [ebp+16]          ; ebx = intResult
    xor ecx, ecx                         ; ecx = 0 (�s��Ƶ��G)
parse_int_loop:
    lodsb                                ; �[���U�@�Ӧr��
    cmp al, '0'                          ; �ˬd�O�_���Ʀr
    jb parse_done_int                    ; �p�G���O�Ʀr�A����
    cmp al, '9'
    ja parse_done_int
    sub al, '0'                          ; �N�r���ର�Ʀr
    imul ecx, ecx, 10                    ; ecx = ecx * 10
    add ecx, eax                         ; ecx = ecx + �Ʀr
    jmp parse_int_loop
parse_done_int:
    stosd                                ; �x�s���G�� intResult
    jmp next_format

; �ѪR�r�� (%s)
parse_string:
    mov ebx, dword ptr [ebp+20]          ; ebx = strResult
parse_string_loop:
    lodsb                                ; �[���U�@�Ӧr��
    cmp al, ' '                          ; �J��Ů�ε�����
    je parse_done_str
    stosb                                ; �x�s�r�Ũ� strResult
    jmp parse_string_loop
parse_done_str:
    mov byte ptr [ebx], 0                ; �K�[�r�굲����
    jmp next_format

; �ѪR�B�I�� (%f)
parse_float:
    mov ebx, dword ptr [ebp+24]          ; ebx = floatResult
    xor edx, edx                         ; edx = �p�Ƴ�����ƭp�ƾ�
    xor ecx, ecx                         ; ecx = ��Ƴ���
    mov ebp, 0                           ; ebp = �p�Ƴ���

parse_float_loop:
    lodsb                                ; �[���U�@�Ӧr��
    cmp al, '.'                          ; �ˬd�O�_�O�p���I
    je parse_fraction
    cmp al, '0'                          ; �ˬd�O�_���Ʀr
    jb parse_done_float                  ; �p�G���O�Ʀr�A����
    cmp al, '9'
    ja parse_done_float
    sub al, '0'                          ; �N�r���ର�Ʀr
    imul ecx, ecx, 10                    ; ecx = ecx * 10
    add ecx, eax                         ; ecx = ecx + �Ʀr
    jmp parse_float_loop

parse_fraction:
    lodsb                                ; �[���p�Ƴ������Ĥ@�Ӧr��
    cmp al, '0'                          ; �ˬd�O�_���Ʀr
    jb parse_done_float
    cmp al, '9'
    ja parse_done_float
    sub al, '0'                          ; �N�r���ର�Ʀr
    imul ebp, ebp, 10                    ; ebp = ebp * 10
    add ebp, eax                         ; ebp = ebp + �Ʀr
    inc edx                              ; �p�Ƴ������ +1
    jmp parse_fraction

parse_done_float:
    ; �p��̲ת��B�I��
    mov eax, 1
    mov cl, dl
    shl eax, cl                         ; eax = 10^�p�Ƴ������
    fild dword ptr [ecx]                 ; �[����Ƴ�����B�I�H�s��
    fidiv dword ptr [eax]                ; ��Ƴ������H 10^�p�Ʀ��
    fistp dword ptr [ebx]                ; �x�s���G�� floatResult
    jmp next_format

; �B�z���~
parse_error:
    xor eax, eax                         ; ��^����
    jmp parse_exit

parse_done:
    mov eax, 1                           ; ��^���\

parse_exit:
    mov esp, ebp
    pop ebp
    ret
parseString endp

ParseNoteChart PROC filename:PTR BYTE
	LOCAL filePtr:PTR FILE
	LOCAL line[256]:BYTE
	LOCAL inNoteSection:DWORD
	LOCAL bar:PTR BYTE
	LOCAL context:ptr byte
	local barlength:DWORD
	local validNotes:DWORD
	local i:DWORD
	local note:byte
	local currentTIme:real4
	local beatTime:real4
	local barTime:real4
	local noteInterval:real4

	; init variables
	mov inNoteSection, 0
	fldz ; currentTime 0

	; open file
	push offset readA
	push filename
	call fopen
	add esp, 8

	test eax, eax
	jz FileOpenError
	mov filePtr, eax

ParseLineLoop:
	; read first line
	push filePtr
	push 256
	push dword ptr [line]
	call fgets
	add esp, 12

	test eax, eax
	jz EndParse

	; remove \n
	push 10
	push dword ptr [line]
	call strcspn
	add esp, 8

	movzx ecx, al
	mov byte ptr [line + ecx], 0

	; check bpm
	push 4
	push offset str_bpm
	push dword ptr [line]
	call strncmp
	add esp, 12

	test eax, eax
	jnz CheckOffset
	
	push offset msInfo.bpm
	push offset getBmp
	push dword ptr [line]
	call parseString
	add esp, 12

	jmp ParseLineLoop

	; check offset
	
CheckOffset:
	push 7
	push offset str_offset
	push dword ptr [line]
	call strncmp
	add esp, 12

	test eax, eax
	jnz CheckStart
	push msInfo._offset
	push offset getOffset
	push dword ptr [line]
	call parseString
	add esp, 12

	jmp ParseLineLoop

CheckStart:
	push 6
	push offset str_start
	push dword ptr [line]
	call strncmp
	add esp, 12

	test eax, eax
	jnz CheckEnd
	mov inNoteSection, 1
	jmp ParseLineLoop

CheckEnd:
	push 4
	push offset str_end
	push dword ptr [line]
	call strncmp
	add esp, 12

	test eax, eax
	jz EndParse
	
	cmp inNoteSection, 1
	jnz ParseLineLoop

	; allocate notes
	push context
	push dword ptr [comma]
	push dword ptr [line]
	call strtok_s
	add esp, 12

	test eax, eax
	jz ParseLineLoop

	mov bar, eax

ProcessBar:
	; get bar length
	push bar
	call strlen
	add esp, 4

	mov barlength, eax

	; get valid notes
	mov validNotes, 0
	mov ecx, barlength

	mov eax, i
	xor eax, eax
	mov i, eax
CountValidNotes:
	cmp i, ecx
	jge ComputeNoteTiming
	movzx eax, byte ptr [bar + i]
	cmp al, '0'
	jb SkipNote
	cmp al, '2'
	ja SkipNote
	inc validNotes
SkipNote:
	inc i
	jmp CountValidNotes

ComputeNoteTiming:
	; check if there are notes in the bar
	mov eax, validNotes
	cmp eax, 0
	je ProcessNextBar

	; calculate note time
	fld dword ptr [msInfo.bpm]
	fld1
	fdiv
	fmul dword ptr [real_60]
	fstp beatTime	; beatTime = 60 / bpm
	fmul dword ptr [real_4]
	fstp barTime	; barTime = 4 * beatTime
	fld barTIme
	fdiv validNotes
	fstp noteInterval  ; noteInterval = barTime / validNotes

	mov eax, i
	xor eax, eax
	mov i, eax

NoteLoop:
	mov eax, i
    cmp eax, barlength
	jge ProcessNextBar
	movzx eax, byte ptr [bar + i]
	cmp al, '0'
	jbe SkipToNextNote
	cmp al, '2'
	ja SkipToNextNote

	; store note and timing
	mov eax, totalNotes
	mov notes[eax], eax
	fld currentTIme
	fstp noteTimings[eax*4]
	inc totalNotes

SkipToNextNote:
    fld currentTime
	fld noteInterval
	fadd
	fstp currentTime
	inc i
	jmp NoteLoop

ProcessNextBar:
    push context
	push dword ptr [comma]
	push 0
	call strtok_s
	add esp, 12

	test eax, eax
	jnz ProcessBar
	mov bar, eax

	jmp ParseLineLoop

EndParse:
	push filePtr
	call fclose
	add esp, 4

	fld dword ptr [msInfo.bpm]
	fmul dword ptr [real_4]
	fld1
	fdiv
	fmul dword ptr [real_60000]
	fstp noteSpawnInterval

	mov eax, SCREEN_WIDTH
	sub eax, HIT_POSITION_X

	push eax
	fild dword ptr [esp]
	add esp, 4

	fld dword ptr [barTime]
	fdiv
	fstp dword ptr [drumStep]

	ret

FileOpenError:
	ret
ParseNoteChart ENDP

; ���J�������z
@load_red_texture PROC
    push 0
    push offset red_drum_path
    call sfTexture_createFromFile
    add esp, 8
    mov redDrumTexture, eax
    ret
@load_red_texture ENDP

; ���J�Ź����z
@load_blue_texture PROC
    push 0
    push offset blue_drum_path
    call sfTexture_createFromFile
    add esp, 8
    mov blueDrumTexture, eax
    ret
@load_blue_texture ENDP

;full�|return 1
isQueueFull PROC
    mov eax, _size
    cmp eax, MAX_DRUMS
    je queue_full
    mov eax, 0

queue_full:
    mov eax, 1
    ret
isQueueFull ENDP

;empty�|return 1
isQueueEmpty PROC
    mov eax, _size
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
    
    lea edi, [drumQueue]

    ; �p���\���m
    mov eax, rear      
    mov edx, Drum_struct_size
    mul edx                  
    add edi, eax 

    mov eax, current_drum.sprite      ; sprite
    mov ebx, current_drum._type       ; dtype

    ; �x�sdrum���
    mov [edi], eax           ; sprite
    mov [edi + 4], ebx       ; dtype

    ; ��srear�Bsize
    inc rear
    mov eax, rear
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov rear, edx
    inc _size

end_enqueue:
    ret
enqueue ENDP

dequeue PROC
    call isQueueEmpty
    cmp eax, 1
    je end_dequeue

    ; �p�Ⲿ����m
    lea edi, drumQueue
    mov eax, front
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
    inc front
    mov eax, front
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov front, edx
    dec _size

end_dequeue:
    ret
dequeue ENDP

spawnDrum PROC             ;call�etype�n��load��eax
    call isQueueFull
    cmp eax, 1
    je end_spawn

    mov current_drum._type, eax
    call sfSprite_create
    mov DWORD PTR [current_drum.sprite], eax

    cmp current_drum._type, 1
    je spawnRed
    call @load_blue_texture

spawnRed:
    call @load_red_texture

    ;�]�w��m
    push 200 ; Y �y��
    push SCREEN_WIDTH   ; X �y��
    push eax
    call sfSprite_setPosition
    add esp, 12

    call enqueue

end_spawn:
    ret
spawnDrum ENDP

updateDrums PROC
    cmp _size, 0
    jbe end_update
    
    lea edi, [drumQueue]
    mov eax, front
    mov edx, Drum_struct_size
    mul edx
    add edi, eax

    push [edi]
    call sfSprite_getPosition
    add esp, 8

    movss spritePosX, xmm0
    add spritePosX, 50
    cmp spritePosX, 50
    jae end_update

    call dequeue

    mov ecx, _size
    mov ebx, front
update_queue:
    ; Ū�� drum
    mov eax, [edi]           ;sprite

    push [eax]
    call sfSprite_getPosition
    add esp, 8
    
    movss xmm1, drumStep
    subss xmm0, xmm1
    movss spritePosX, xmm0

    push dword ptr [spritePosY] ; Y �y��
    push dword ptr [spritePosX]   ; X �y��
    push [eax]
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

main_game_page PROC window:DWORD, musicPath:dword, noteChart:dword

    ;���J�Э�
    push dword ptr [noteChart]
	call ParseNoteChart
	add esp, 4

    ;���J����
    push dword ptr [musicPath]
    call game_play_music
    add esp, 4
    test eax, eax
    jz @exit_program

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

    ; ���Jtja��
    ;push offset selected_beatmap_path
    ;call parseNoteChart
    ;test eax, eax
    ;jz @exit_program

    ; ��l�ƭp�ɾ�
    call sfClock_create
    test eax, eax
    jz @exit_program
    mov dword ptr [clock], eax

@main_loop:

    ; �ˬd���֬O�_����
    push bgMusic
    call sfMusic_getStatus
    add esp, 4
    cmp eax, 0
    je to_end_page

    ;�ˬd�Э��O�_�]��
    ;mov eax, currentNoteIndex
    ;cmp eax, totalNotes
    ;jb check_window
    ;call isQueueEmpty
    ;cmp eax, 1
    ;je to_end_page

check_window:
    ; �ˬd�����O�_�}��
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exit_program

    ; ��s�p�ɾ�
    push dword ptr [clock]
    call sfClock_getElapsedTime
    add esp, 4
    test eax, eax
    jz @exit_program 

    cvtsi2ss xmm0, eax
    movss xmm1, [const_1000] 
    divss xmm0, xmm1
    movss xmm1, noteSpawnInterval
    ucomiss xmm0, xmm1
    jb update

    mov eax, currentNoteIndex
    cmp eax, totalNotes
    jae restart
    lea edi, [notes]
    add edi, eax
    inc currentNoteIndex

    mov eax, [edi]
    cmp eax, 0
    je restart
    call spawnDrum

restart:
    call sfClock_restart

update:
    call updateDrums

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

    mov ecx, _size
    mov edx, front
    mov index, edx
draw_loop:
    ; ø�s��
    lea edi, [drumQueue]
    mov eax, index
    mov edx, Drum_struct_size
    mul edx
    add edi, eax

    ;push 0
    ;push edi
    ;push DWORD PTR [window]
    ;call sfRenderWindow_drawSprite
    ;add esp, 12                    ;error here

    ;inc index
    mov eax, index
    xor edx, edx
    mov ebx, MAX_DRUMS
    div ebx
    mov index, edx
    cmp ecx, 0
    je display_window

display_window:
    ; ��ܵ���
    mov eax, window
    push eax
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

; ���൲��e��
to_end_page:
    ;�C�������n�����쵲���e��
    push score    
    push miss_count    
    push good_count   
    push great_count    
    push window        
    call end_game_page
    add esp, 20
    mov DWORD PTR [currentPage], 2
    jmp @exit_program

@exit_program:

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

    push dword ptr [clock]
    call sfClock_destroy
    add esp, 4

    push bgMusic
    call sfMusic_destroy
    add esp, 4
    
    ret
main_game_page ENDP

END main_game_page