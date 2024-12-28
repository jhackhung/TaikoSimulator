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

    ; 新增延遲相關變數
    initial_delay_1 real4 2.0    ; 設定 2 秒延遲
    delay_started dword 0      ; 追蹤延遲是否開始
    delay_clock dword 0        ; 用於計時的時鐘

	consoleHandle dd ?
	event sfEvent <>

    redNoteSound dd 0    ; 紅色音符音效
    blueNoteSound dd 0   ; 藍色音符音效

	chart db "assets/game/yoasobi.txt", 0
	bgPath db "assets/game/bg_genre_2.jpg", 0
	redNotePath db "assets/game/red_note.png", 0
	blueNotePath db "assets/game/blue_note.png", 0
    red_note_sound_path db "assets/main/rednote.wav", 0
    blue_note_sound_path db "assets/main/bluenote.wav", 0

	stats GameStats <0, 0, 0, 0, 0, 0>
	msInfo MusicInfo <130.000000, -1.962000, 115.384613>

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
    movss xmm0, targetTime
    movss dword ptr [esi+8], xmm0
    

    ; 設置音符的紋理
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

    ; 設置初始位置

    sub esp, 8
    movss xmm0, real_1280
    movss dword ptr [esp], xmm0
    movss xmm0, real_200
    movss dword ptr [esp+4], xmm0
    push [esi]
    call sfSprite_setPosition
    add esp, 12

    ; 將Drum加入隊列
    push esi
    call enqueue
    add esp, 4
    ret

QueueFullSpawn:
    ret
spawnDrum ENDP

updateDrums PROC USES esi edi ebx
    local i:DWORD
    ; 檢查並移除過時的音符
    mov eax, _size
    test eax, eax
    jz SkipUpdate

    mov edi, front
    mov esi, drumQueue[edi*4]
    push [esi]            ; drum.sprite
    call sfSprite_getPosition
    add esp, 4

    ; 檢查音符是否完全超出判定圓圈
    ; 判定圓圈左邊緣 = 450 - 30 = 420
    ; 音符右邊緣 = x + 64
    addss xmm0, real_64   ; 加上音符半徑寬度(約32像素)
    movss xmm1, real_450  ; 載入判定圈x座標
    subss xmm1, real_30   ; 減去半徑，獲得左邊緣
    comiss xmm0, xmm1     ; 比較 (note.x + width) < (circle.x - radius)
    jae SkipFrontRemoval

    ; 移除過時音符
    push [esi]
    call sfSprite_destroy
    add esp, 4

    ; 更新miss and current_combo 統計數據
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

    ; 更新音符位置
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
    ; 創建圓形形狀
    push 0
    call sfCircleShape_create
    add esp, 4
    mov judgementCircle, eax

    ; 設置圓形半徑
    push real_30
    push dword ptr [judgementCircle]
    call sfCircleShape_setRadius
    add esp, 8

    ; 設置圓形位置
    push real_225               ; HIT_POSITION_X, 200+25
    push real_450
    push dword ptr [judgementCircle]
    call sfCircleShape_setPosition
    add esp, 12

    ; 設置填充顏色
    push transparentColor
    push dword ptr [judgementCircle]
    call sfCircleShape_setFillColor
    add esp, 8

    ; 設置邊框厚度
    push real_2
    push dword ptr [judgementCircle]
    call sfCircleShape_setOutlineThickness
    add esp, 8

    ; 設置邊框顏色
    push white_color
    push dword ptr [judgementCircle]
    call sfCircleShape_setOutlineColor
    add esp, 8

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

processHit proc uses ebx esi edi hitType:DWORD
    local delta:DWORD
    
    ; 檢查佇列是否為空
    call isQueueEmpty
    test al, al
    jnz @done_processing
    
    ; 獲取最前面的音符
    mov edi, front
    mov esi, drumQueue[edi*4]
    
    ; 獲取音符位置(取到音符top_left位置)
    push dword ptr [esi]
    call sfSprite_getPosition
    add esp, 4
    
    ; 計算與判定線的距離 (450是判定線位置，也是judgement circle的圓心) 兩圓心比較
    subss xmm0, real_450
    addss xmm0, real_32 ; 加上音符半徑
    
    ; 取絕對值
    andps xmm0, [abs_mask]
    
    ; 首先檢查音符類型是否匹配
    mov edx, dword ptr [esi+4]
    cmp edx, [hitType]
    jne @done_processing         ; 如果類型不匹配，跳出processHit
    
    ; 判斷音符是否在判定圈內
    movss xmm1, real_30    ; 載入判定圈半徑
    addss xmm1, real_32    ; 加上音符半徑
    comiss xmm0, xmm1      ; 比較音符中心點距離是否 >= 30
    jae @done_processing     ; 如果距離 > 30，直接跳過

    ; GREAT判定 (誤差 <= 15)
    movss xmm1, real_15       ; 載入判定圈半徑   
    comiss xmm0, xmm1         ; 比較音符中心點距離是否 <= 15
    jbe @great_hit

    ; MISS判定 (誤差 > 40)
    ;movss xmm2, real_30       ; 載入判定圈半徑
    ;addss xmm2, real_2        ; 加上10個單位
    ;addss xmm2, real_2
    ;addss xmm2, real_2
    ;addss xmm2, real_2
    ;addss xmm2, real_2
    ;comiss xmm0, xmm2         ; 比較是否 > 40
    ;ja @miss_hit
    
    ; 其餘情況 -> GOOD 誤差 <= 30
    jmp @good_hit
    
@great_hit:
    mov eax, offset stats
    inc dword ptr [eax]              ; great_count
    inc dword ptr [eax+12]           ; current_combo
    
    ; 計算分數 (combo * 10 + 300)
    mov ecx, dword ptr [eax+12]      ; 取得current_combo
    imul ecx, 10
    add ecx, 300
    add dword ptr [eax+20], ecx      ; 加到total_score
    
    ; 更新max_combo
    mov ecx, dword ptr [eax+12]      ; current_combo
    cmp ecx, dword ptr [eax+16]      ; 比較max_combo
    jle @remove_note
    mov dword ptr [eax+16], ecx      ; 更新max_combo
    jmp @remove_note
    
@good_hit:
    mov eax, offset stats
    inc dword ptr [eax+4]            ; good_count
    inc dword ptr [eax+12]           ; current_combo
    
    ; 計算分數 (combo * 5 + 100)
    mov ecx, dword ptr [eax+12]      ; 取得current_combo
    imul ecx, 5
    add ecx, 100
    add dword ptr [eax+20], ecx      ; 加到total_score
    
    ; 更新max_combo
    mov ecx, dword ptr [eax+12]      ; current_combo
    cmp ecx, dword ptr [eax+16]      ; 比較max_combo
    jle @remove_note
    mov dword ptr [eax+16], ecx      ; 更新max_combo
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

;播放音效
initializeSounds PROC
    ; 創建紅色音符音效
    push offset red_note_sound_path
    call sfMusic_createFromFile
    add esp, 4
    mov redNoteSound, eax

    ; 創建藍色音符音效
    push offset blue_note_sound_path
    call sfMusic_createFromFile
    add esp, 4
    mov blueNoteSound, eax

    ret
initializeSounds ENDP

; 修改紅色音符音效函數
rednote_sound PROC
    push redNoteSound
    call sfMusic_stop    ; 先停止之前的播放
    add esp, 4

    push redNoteSound
    call sfMusic_play    ; 播放音效
    add esp, 4
    ret
rednote_sound ENDP

; 修改藍色音符音效函數
bluenote_sound PROC
    push blueNoteSound
    call sfMusic_stop    ; 先停止之前的播放
    add esp, 4

    push blueNoteSound
    call sfMusic_play    ; 播放音效
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
    call initializeSounds    ; 初始化音效

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

    ; 創建延遲計時器
    call sfClock_create
    mov delay_clock, eax

@main_loop:
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je exit_program

    ; 檢查延遲狀態
    mov eax, delay_started
    cmp eax, 0
    jne check_game_start    ; 如果延遲已經開始，檢查遊戲開始

    ; 開始延遲計時
    mov delay_started, 1
    push delay_clock
    call sfClock_restart
    add esp, 4
    jmp @event_loop

check_game_start:
    ; 檢查是否已經過了延遲時間
    push delay_clock
    call sfClock_getElapsedTime
    cvtsi2ss xmm1, eax
    
    movss xmm0, [real_1000000]
    divss xmm1, xmm0        ; 轉換為秒
    
    movss xmm0, dword ptr [initial_delay_1]
    comiss xmm1, xmm0       ; 比較是否超過延遲時間
    jb @event_loop          ; 如果還沒超過延遲時間，繼續等待

    ; 如果超過延遲時間且遊戲還沒開始，開始遊戲
    mov eax, gameStarted
    cmp eax, 0
    jne deter_offset

    ; 開始播放音樂
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

        ; 修改按鍵處理部分
        @check_key_press:
   
            ; 檢查是否是F鍵或J鍵
            cmp dword ptr [esi+4], sfKeyF
            je @handle_red
            cmp dword ptr [esi+4], sfKeyJ
            je @handle_red
    
            ; 檢查是否是D鍵或K鍵
            cmp dword ptr [esi+4], sfKeyD
            je @handle_blue
            cmp dword ptr [esi+4], sfKeyK
            je @handle_blue
    
            jmp @event_loop

            @handle_red:
                call rednote_sound
                push 1                   ; 紅色音符類型
                call processHit
                jmp @controll_drum

            @handle_blue:
                call bluenote_sound
                push 2                   ; 藍色音符類型
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
    jae check_last_note    ; 如果所有音符都已生成，檢查最後一個音符

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
    ; 檢查是否有音符在隊列中
    mov eax, _size
    test eax, eax
    jz @end_game         ; 如果沒有音符且都已生成，結束遊戲

    ; 檢查最後一個音符的位置
    mov edi, front
    mov ecx, _size
    dec ecx              ; 獲取最後一個音符的索引
    add edi, ecx
    cmp edi, MAX_DRUMS
    jb no_wrap
    sub edi, MAX_DRUMS
no_wrap:
    mov esi, drumQueue[edi*4]
    push [esi]
    call sfSprite_getPosition
    add esp, 4
    
    ; 檢查音符是否已離開畫面
    comiss xmm0, real_0   ; 比較 x 位置是否小於 0
    jb @end_game         ; 如果最後一個音符已離開畫面，結束遊戲

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

    ; 釋放紅色音符音效
    push redNoteSound
    call sfMusic_destroy
    add esp, 4

    ; 釋放藍色音符音效
    push blueNoteSound
    call sfMusic_destroy
    add esp, 4

    push music
    call sfMusic_destroy
    add esp, 4

@end_game:
    push music
    call sfMusic_stop    ; 停止音樂
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