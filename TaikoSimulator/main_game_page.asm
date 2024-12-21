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
	msInfo MusicInfo <>

	; queue for drums
	drumQueue dword MAX_DRUMS dup(?) ; 存放Drum結構指針
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
	judgmentCircle dword ?
	
	; music
	music dword ?

	; clock
	spawnClock dword 0

	currentTime real4 0.0

	currentNoteIndex dd 0
	gameStartTime real4 3.0
	gameStarted dword 0

	; note chart
	notes dword MAX_NOTES dup(?)
	totalNotes dword 0
	noteSpawnInterval real4 0.0
	noteTimings real4 MAX_NOTES dup(?)
	drumStep real4 0.25

	; color
	blackColor sfColor <0, 0, 0, 255>
	transparentColor sfColor <0, 0, 0, 150>

	; file
	readA byte "r", 0

	; 字串常量
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
	decimal_mult  dq 0.1                  ; 小數位數乘數
    ten           dq 10.0                 ; 用於乘法運算
	real_2 real4 2.0
	real_32 real4 32.0
	real_720 real4 720.0
	real_1280 real4 1280.0
	real_1000000 real4 1000000.0
    real_good_threshold real4 30.0
    real_great_threshold real4 4.0

.code
parseFormatFloat proc inputStr:DWORD, formatPrefix:DWORD, floatResult:PTR DWORD
	LOCAL isDecimal:BYTE
	LOCAL isNegative:BYTE

    ; 初始化參數
    mov esi, inputStr                   ; 獲取 inputStr
    mov edi, formatPrefix                     ; 獲取 formatPrefix


; 比較 inputStr 與 formatPrefix
compare_loop:
    mov al, [esi]                          ; 取 inputStr 當前字元
    mov bl, [edi]                          ; 取 formatPrefix 當前字元
    cmp al, 0                              ; 檢查 inputStr 是否結束
    je parse_error                         ; 如果結束但還沒遇到 %，報錯
    cmp bl, 0                              ; 檢查 formatPrefix 是否結束
    je parse_error                         ; 如果格式結束但還沒遇到 %，報錯
    cmp al, bl                             ; 比較兩個字元
    je matched                             ; 如果相等，繼續下一個字元
    cmp bl, '%'                            ; 檢查是否遇到 %
    je check_sign                        ; 遇到 % 開始解析數字
    jmp parse_error                        ; 如果不匹配，報錯

matched:
    inc esi                                ; 前進 inputStr
    inc edi                                ; 前進 formatPrefix
    jmp compare_loop

; 解析數字部分
check_sign:
	; 檢查負號
    mov al, [esi]
    cmp al, '-'
    jne parse_number
    mov isNegative, 1        ; 設置負數標誌
    inc esi                  ; 跳過負號

parse_number:
    xor edx, edx                         ; 用於儲存整數部分
    
integer_part:
    mov al, [esi]
    cmp al, '.'
    je start_decimal
    
    cmp al, '0'
    jb check_end
    cmp al, '9'
    ja check_end
    
    ; 處理整數數字
    sub al, '0'
    imul edx, 10
    movzx ecx, al
    add edx, ecx
    inc esi
    jmp integer_part
    
start_decimal:
    ; 將整數部分轉換為浮點數
    push edx
    fild dword ptr [esp]
    add esp, 4
    
    inc esi                              ; 跳過小數點
    fld decimal_mult                     ; 載入 0.1
    
decimal_part:
    mov al, [esi]
    cmp al, '0'
    jb store_result
    cmp al, '9'
    ja store_result
    
    ; 處理小數部分
    sub al, '0'
    movzx edx, al
    push edx
    fild dword ptr [esp]                 ; 載入數字
    add esp, 4
    fmul st(0), st(1)                   ; 乘以當前小數位權重
    faddp st(2), st(0)                  ; 加到結果中
    
    ; 更新小數位權重
    fld st(0)
    fld ten
    fdivp st(1), st(0)
    fstp st(1)
    
    inc esi
    jmp decimal_part

store_result:
    ; 儲存結果
    fstp st(0)
	; 如果是負數，改變符號
    cmp isNegative, 0
    je save_result
    fchs                    ; 改變符號 (change sign)

save_result:
	mov ebx, floatResult
	fstp dword ptr [ebx]
    jmp exit_parse
    
check_end:
    cmp al, 0
    jne start_decimal                     ; 非法字元
    
parse_error:
    mov eax, 0                          ; 返回失敗
    
exit_parse:

    ret
parseFormatFloat endp


ParseNoteChart PROC filename:DWORD
	LOCAL filePtr:PTR FILE
	LOCAL line[256]:BYTE
	LOCAL inNoteSection:DWORD
	LOCAL bar:PTR BYTE
	LOCAL context:ptr byte
	local barlength:DWORD
	local validNotes:DWORD
	local i:DWORD
	local note:byte
	local l_currentTIme:real4
	local beatTime:real4
	local barTime:real4
	local noteInterval:real4

	; init variables
	mov inNoteSection, 0
	fldz ; l_currentTime 0

	; open file
	push offset readA
	push filename
	call fopen
	add esp, 8
	mov filePtr, eax

	test eax, eax
	jz FileOpenError
	

	ParseLineLoop:
		; read first line
		push filePtr
		push 256
		lea eax, line
		push eax
		call fgets
		add esp, 12

		test eax, eax
		jz EndParse

		; remove \n
		push offset breakline
		lea eax, line
		push eax
		call strcspn
		add esp, 8

		movzx ecx, al
		mov byte ptr [line + ecx], 0

		; check bpm
		push 4
		push offset str_bpm
		lea eax, line
		push eax
		call strncmp
		add esp, 12

		test eax, eax
		jnz CheckOffset

		push offset msInfo.bpm
		mov eax, offset getBpm
		push eax
		lea eax, line
		push eax
		call parseFormatFloat
		add esp, 12

		jmp ParseLineLoop

		; check offset
	
	CheckOffset:
		push 7
		push offset getOffset
		lea eax, line
		push eax
		call strncmp
		add esp, 12

		test eax, eax
		jnz CheckStart

		push offset msInfo._offset
		mov eax, offset getOffset
		push eax
		lea eax, line
		push eax
		call parseFormatFloat
		add esp, 12

		jmp ParseLineLoop

	CheckStart:
		push 6
		push offset str_start
		lea eax, line
		push eax
		call strncmp
		add esp, 12

		test eax, eax
		jnz CheckEnd
		mov inNoteSection, 1
		jmp ParseLineLoop

	CheckEnd:
		push 4
		push offset str_end
		lea eax, line
		push eax
		call strncmp
		add esp, 12

		test eax, eax
		jz EndParse
	
		cmp inNoteSection, 1
		jnz ParseLineLoop

		; allocate notes
		lea eax, context
		push eax
		push offset comma
		lea eax, line
		push eax
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

		xor esi, esi                 ; esi 作為索引 i，初始化為 0
		xor eax, eax                 ; eax 作為暫存器
		mov ecx, [barLength]         ; ecx = barLength
		mov ebx, bar
	CountValidNotes:
		cmp esi, ecx                 ; 如果 i >= barLength 則跳出迴圈
		jge ComputeNoteTiming

		mov eax, [ebx]   ; 加載 bar[i] 到 al
		cmp al, '0'                  ; 如果 bar[i] < '0'
		jb SkipNote
		cmp al, '2'                  ; 如果 bar[i] > '2'
		ja SkipNote
		inc validNotes    ; 有效音符計數 +1

	SkipNote:
		inc esi   ; i++
		inc ebx
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

		mov ecx, 0
		mov esi, bar
        
	NoteLoop:
		cmp ecx, barlength
		jge ProcessNextBar

		mov al, [esi+ecx]
		cmp al, '0'
		jb SkipToNextNote
		cmp al, '2'
		ja SkipToNextNote
        cmp al, '0'
        je updateTime

		; store note and timing
        sub al, '0'
        mov ebx, totalNotes
        mov edi, offset notes
		mov [edi+ebx], eax

        mov eax, dword ptr [l_currentTime]
        mov edi, offset noteTimings
        mov [edi+ebx], eax

		inc totalNotes

    updateTime:
        fld l_currentTIme
        fld noteInterval
        fadd
		fstp l_currentTIme

	SkipToNextNote:
		inc ecx
		jmp NoteLoop

	ProcessNextBar:
		lea eax, context
		push eax
		push offset comma
		push 0
		call strtok_s
		add esp, 12

		test eax, eax
		jnz ProcessBar
		mov bar, eax

		jmp ParseLineLoop

	EndParse

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

isQueueFull PROC
    mov eax, _size
    cmp eax, MAX_DRUMS
    sete al                ; 如果滿了，設置返回值為1
    ret
isQueueFull ENDP

isQueueEmpty PROC
    mov eax, _size
    test eax, eax
    sete al                ; 如果空，設置返回值為1
    ret
isQueueEmpty ENDP

enqueue PROC USES edi esi ebx @drum:DWORD 
    ; 檢查是否滿了
    call isQueueFull
    test al, al
    jnz @end_enqueue

    ; 加入隊列
    mov esi, @drum          ; drum參數
    mov edi, rear          ; rear索引
    mov drumQueue[edi*4], esi ; 將drum加入隊列

    ; 更新rear和size
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
    ; 檢查是否空了
    call isQueueEmpty
    test al, al
    jnz QueueEmpty

    ; 刪除隊列頭
    mov edi, front          ; front索引
    mov esi, drumQueue[edi*4] ; 獲取隊列頭的drum指針
    push esi
    call sfSprite_destroy   ; 釋放sprite
    add esp, 4

    ; 更新front和size
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
    ; 檢查是否滿了
    call isQueueFull
    test al, al
    jnz QueueFullSpawn

    ; 創建新的Drum結構
    push 12                ; 分配空間
    call malloc
    add esp, 4
    mov esi, eax           ; 保存新結構指針

    ; 初始化Drum結構
	push 0
    call sfSprite_create
    add esp, 4
    mov [esi], eax       ; sprite指針

	mov eax, _type
    mov dword ptr [esi+4], eax
    fld targetTime
    fstp dword ptr [esi+8]
    

    ; 設置音符的紋理
    cmp _type, 1
    jne SetBlueTexture
    push sfTrue
    push OFFSET redDrumTexture
    push [esi+8]
    call sfSprite_setTexture
    jmp DoneTexture
SetBlueTexture:
    push sfTrue
    push OFFSET blueDrumTexture
    push [esi+8]
    call sfSprite_setTexture
DoneTexture:

    ; 設置初始位置
    push 200
    push SCREEN_WIDTH
    lea eax, [esp]
    push eax
    push [esi+8]
    call sfSprite_setPosition
    add esp, 8

    ; 將Drum加入隊列
    push esi
    call enqueue
    add esp, 4
    ret

QueueFullSpawn:
    ret
spawnDrum ENDP

updateDrums PROC USES esi edi ebx
    ; 檢查並移除過時的音符
    mov eax, _size
    test eax, eax
    jz SkipUpdate

    mov edi, front
    mov esi, drumQueue[edi*4]
    push [esi]            ; drum.sprite
    call sfSprite_getPosition
    add esp, 4
    mov ebx, eax            ; 保存X座標
    sub ebx, HIT_POSITION_X
    sub ebx, 85
    cmp ebx, 0
    jnl SkipFrontRemoval

    ; 移除過時音符
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

    ; 更新音符位置
    mov ecx, _size
    mov edi, front
UpdateLoop:
    test ecx, ecx
    jz EndUpdateLoop

    mov esi, drumQueue[edi*4]
    push [esi]
    call sfSprite_getPosition
    add esp, 4
    mov ebx, eax
    sub ebx, drumStep
    push ebx
    push [esi]
    call sfSprite_setPosition
    add esp, 8

    inc edi
    cmp edi, MAX_DRUMS
    jb NoWrap
    mov edi, 0
NoWrap:
    dec ecx
    jmp UpdateLoop
EndUpdateLoop:
SkipUpdate:
    ret
updateDrums ENDP

createJudgementCircle PROC USES esi edi
    ; 創建圓形形狀
    push 0
    call sfCircleShape_create
    add esp, 4
    mov esi, eax

    ; 設置圓形半徑
    push 30
    push esi
    call sfCircleShape_setRadius
    add esp, 8

    ; 設置圓形位置
    push 225               ; HIT_POSITION_X, 200+25
    push HIT_POSITION_X
    lea eax, [esp]
    push eax
    push esi
    call sfCircleShape_setPosition
    add esp, 16

    ; 設置填充顏色
    push blackColor
    push esi
    call sfCircleShape_setFillColor
    add esp, 8

    ; 設置邊框厚度
    push 2
    push esi
    call sfCircleShape_setOutlineThickness
    add esp, 8

    ; 設置邊框顏色
    push transparentColor
    push esi
    call sfCircleShape_setOutlineColor
    add esp, 8

    mov eax, esi
    ret
createJudgementCircle ENDP

@ld_background PROC
    ; 創建背景紋理
    push 0
    push offset bgPath
    call sfTexture_createFromFile
    add esp, 8
    mov bgTexture, eax
    
    ; 創建背景精靈
    call sfSprite_create
    mov DWORD PTR [bgSprite], eax
    
    ; 設定紋理
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
    mov ecx, dword ptr [HIT_POSITION_X]
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
	call ParseNoteChart
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
	mov judgmentCircle, eax

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

	
    push spawnClock  ; 呼叫sfClock_getElapsedTime並獲取microseconds
    call sfClock_getElapsedTime
    fstp st(0)                    ; 將結果放入浮點堆疊 (microseconds)

    ; 除以1000000.0以轉換為秒
    fld real_1000000
    fdiv                        ; st(0) = st(0) / divisor
    fst currentTIme             ; 儲存結果到currentTime

	mov eax, gameStarted
	cmp eax, 0
	jne deter_offset

	; check game start
	push music 
	call sfMusic_getStatus
	add esp, 4
	cmp eax, sfPlaying
	je skip_music_play

	; 比較 currentTime >= msInfo_offset
    fld currentTime                  ; st(0) = currentTime
    fld msInfo._offset              ; st(1) = musicInfo.offset, st(0) = currentTime
    fcomip st(0), st(1)              ; 比較 st(0) 與 st(1)
    jb skip_music_play               ; 如果 currentTime < musicInfo.offset 跳過
    fstp st(0)                       ; 清除浮點堆疊

    ; 比較 msInfo_offset >= 0
    fld msInfo._offset            ; st(0) = musicInfo.offset
    fldz                             ; st(1) = 0.0, st(0) = musicInfo.offset
    fcomip st(0), st(1)              ; 比較 st(0) 與 0.0
    jb skip_music_play               ; 如果 musicInfo.offset < 0 跳過
    fstp st(0)                       ; 清除浮點堆疊

    ; 播放音樂
    push music
    call sfMusic_play
	add esp, 4
skip_music_play:
    ; 重置時鐘
    push spawnClock
    call sfClock_restart

    ; 設定 gameStartTime = 0.0f
    fldz                             ; 加載 0.0
    fstp gameStartTime

    ; 設定 gameStarted = 1
    mov gameStarted, 1

deter_offset:
	mov eax, gameStarted
	cmp eax, 1
	jne @event_loop

	; 比較 musicInfo.offset < 0
    fld msInfo._offset              ; st(0) = musicInfo.offset
    fldz                             ; st(1) = 0.0, st(0) = musicInfo.offset
    fcomip st(0), st(1)              ; 比較 musicInfo.offset 和 0.0
    jae @event_loop                 ; 如果 offset >= 0，跳過
    fstp st(0)                       ; 清除浮點堆疊

	; 呼叫 sfMusic_getStatus 並檢查是否為 sfPlaying
    push music
    call sfMusic_getStatus
	add esp, 4
    cmp eax, sfPlaying               ; 比較返回值與 sfPlaying
    je @event_loop                  ; 如果音樂正在播放，跳過

    ; 計算 currentTime >= -musicInfo.offset
    fld msInfo._offset              ; st(0) = musicInfo.offset
    fchs                             ; st(0) = -musicInfo.offset
    fld currentTime                  ; st(1) = currentTime, st(0) = -musicInfo.offset
    fcomip st(0), st(1)              ; 比較 currentTime 和 -musicInfo.offset
    jb @event_loop                  ; 如果 currentTime < -musicInfo.offset，跳過
    fstp st(0)                       ; 清除浮點堆疊

    ; 播放音樂
    push music
    call sfMusic_play
	add esp, 4

	@event_loop:
		; 事件處理
        lea esi, event
        push esi
        mov eax, DWORD PTR [window]
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @render_window
    
        ; 檢查關閉事件
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end

		cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
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

		; 呼叫sfClock_getElapsedTime並獲取microseconds
		push spawnClock
		call sfClock_getElapsedTime
		add esp, 4
		fstp st(0)                    ; 將結果放入浮點堆疊 (microseconds)

		; 除以1000000.0以轉換為秒
		fld real_1000000
		fdiv                        ; st(0) = st(0) / divisor
		fst currentTime             ; 儲存結果到currentTime

        ; 比較 currentTime >= noteTimings[currentNoteIndex]
        fld currentTime                         ; st(0) = currentTime
        mov ebx, currentNoteIndex               ; ebx = currentNoteIndex
        shl ebx, 2                              ; 計算索引的位移 (4字節對齊)
        fld noteTimings[ebx]                    ; st(1) = noteTimings[currentNoteIndex]
        fcomip st(0), st(1)                     ; 比較 currentTime 與 noteTimings
        jb loop_end                             ; 如果 currentTime < noteTimings, 跳過迴圈
        fstp st(0)                              ; 清除浮點堆疊

        ; 檢查 notes[currentNoteIndex] != 0
        mov eax, currentNoteIndex               ; eax = currentNoteIndex
        mov ebx, notes[eax*4]                   ; ebx = notes[currentNoteIndex]
        cmp ebx, 0                              ; 比較 notes[currentNoteIndex] == 0
        je skip_spawn                           ; 如果等於0，跳過 spawnDrum

        ; 呼叫 spawnDrum(notes[currentNoteIndex], noteTimings[currentNoteIndex])
        push noteTimings[ebx]                   ; 推入 noteTimings[currentNoteIndex]
        push ebx                                ; 推入 notes[currentNoteIndex]
        call spawnDrum                          ; 呼叫 spawnDrum 函式
        add esp, 8                              ; 清理堆疊

    skip_spawn:
        ; 更新 currentNoteIndex++
        inc currentNoteIndex
        jmp @controll_drum                          ; 返回迴圈起點

    loop_end:
        ; 呼叫 updateDrums 函式
        call updateDrums

	@render_window:
        ; 清除視窗
        push blackColor
        push window
        call sfRenderWindow_clear
        add esp, 8

        ; 繪製背景
        push 0
        mov eax, DWORD PTR [bgSprite]
        push eax
        mov ecx, DWORD PTR [window]
        push ecx
        call sfRenderWindow_drawSprite
        add esp, 12

        ; 繪製音符
        mov ecx, _size
        test ecx, ecx
        jz @deter_music_stop
        mov edi, front
    draw_notes:
        cmp ecx, 0
        jz @deter_music_stop

        push 0
        mov eax, [drumQueue + edi*4]
		push eax
        call sfRenderWindow_drawSprite
        add esp, 8

        cmp edi, MAX_DRUMS
        jne @next_note
        mov edi, 0

    @next_note:
        inc edi
        dec ecx
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
        push window
        call sfRenderWindow_display
        add esp, 4

@end:

    ; 釋放資源
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
