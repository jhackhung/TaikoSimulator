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

	consoleHandle dd ?
	event sfEvent <>

	chart db "assets/game/yoasobi.txt", 0
	bgPath db "assets/game/bg_genre_2.png", 0
	redNotePath db "assets/game/red_note.png", 0
	blueNotePath db "assets/game/blue_note.png", 0
    red_note_sound_path db "assets/game/redmote.wav", 0
    blue_note_sound_path db "assets/main/bluemote.wav", 0

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
    addss xmm0, real_32   ; 加上音符寬度(約32像素)
    movss xmm1, real_450  ; 載入判定圈x座標
    subss xmm1, real_30   ; 減去半徑，獲得左邊緣
    comiss xmm0, xmm1     ; 比較 (note.x + width) < (circle.x - radius)
    jae SkipFrontRemoval

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
    push blackColor
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
    
    ; 獲取音符位置
    push dword ptr [esi]
    call sfSprite_getPosition
    add esp, 4
    
    ; 計算與判定線的距離
    subss xmm0, real_450
    
    ; 取絕對值
    andps xmm0, [abs_mask]
    
    ; 檢查音符類型是否匹配
    mov edx, dword ptr [esi+4]
    cmp edx, [hitType]
    jne @miss_hit
    
    ; 檢查是否在great範圍內
    comiss xmm0, real_great_threshold
    jbe @great_hit
    
    ; 檢查是否在good範圍內
    comiss xmm0, real_good_threshold
    ja @miss_hit
    
@good_hit:
    ; 直接操作記憶體中的計數器
    mov eax, offset stats
    inc dword ptr [eax]              ; great_count
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
    
@miss_hit:
    mov eax, offset stats
    inc dword ptr [eax+8]            ; miss_count
    mov dword ptr [eax+12], 0        ; current_combo = 0
    jmp @done_processing
    
@remove_note:
    call dequeue
    
@done_processing:
    ret 4

processHit endp

;播放音效
rednote_sound PROC
    push offset red_note_sound_path
    call sfMusic_createFromFile
    add esp, 4 
    mov music, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
rednote_sound ENDP

bluenote_sound PROC
    push offset blue_note_sound_path
    call sfMusic_createFromFile
    add esp, 4 
    mov music, eax

    push eax
    call sfMusic_play
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

    push spawnClock
    call sfClock_getElapsedTime
    cvtsi2ss xmm1, eax

    movss xmm0, [real_1000000]
    divss xmm1, xmm0

    ; 除以1000000.0以轉換為秒
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

    movss xmm0, [msInfo._offset]
    ucomiss xmm1, xmm0
    jb skip_music_play

    fldz
    fld msInfo._offset
    fcomip st(0), st(1)
    jbe skip_music_play
    fstp st(0)

    ; 播放音樂
    push music
    call sfMusic_play
    add esp, 4

skip_music_play:
    ; 重置時鐘
    push spawnClock
    call sfClock_restart

    fldz
    fstp gameStartTime

    ; 設定 gameStarted = 1
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

	; 呼叫 sfMusic_getStatus 並檢查是否為 sfPlaying
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

    ; 播放音樂
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

        ; 檢查關閉事件
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
                push 1                   ; 紅色音符類型
                call processHit
                jmp @controll_drum

            @handle_blue:
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

        ; 除以1000000.0以轉換為秒
                movss dword ptr [currentTime], xmm1

spawn_loop:
        ;比較currentNoteIndex < totalNotes
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
        ; 更新 currentNoteIndex++
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
        ; 繪製判定圓
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

    ; 釋放資源
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

@end_game:
    push music
    call sfMusic_stop    ; 停止音樂
    add esp, 4

    push dword ptr [stats+16]    ; max_combo
    push dword ptr [stats+20]    ; total_score
    push dword ptr [stats+8]     ; miss_count
    push dword ptr [stats+4]     ; good_count
    push dword ptr [stats]       ; great_count
    push window
    call end_game_page
    add esp, 24

exit_program:

    ret

main_game_page ENDP

END main_game_page