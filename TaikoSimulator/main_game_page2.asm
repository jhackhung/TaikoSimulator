.686P
.XMM
.model flat, c
include csfml.inc
include game.inc

extern end_game_page: PROC
extern currentPage: DWORD

.data
	event sfEvent <>

	chart db "C:\Users\User\source\repos\TaikoSimulator\TaikoSimulator\assets\game\yoasobi.txt", 0
	bgPath db "assets/game/bg_genre_2.png", 0
	redNotePath db "assets/game/red_note.png", 0
	blueNotePath db "assets/game/blue_note.png", 0

	stats GameStats <>
	msInfo MusicInfo <>

	; queue for drums
	drumQueue Drum MAX_DRUMS dup(<>) ; 存放Drum結構指針
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
	scoreText dword ?

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

	real_60 real4 60.0
	real_4 real4 4.0
	real_60000 real4 60000.0
	decimal_mult  dq 0.1                  ; 小數位數乘數
    ten           dq 10.0                 ; 用於乘法運算
	real_2 real4 2.0
	real_10 real4 10.0
	real_32 real4 32.0
	real_720 real4 720.0
	real_1280 real4 1280.0
	real_1000000 real4 1000000.0
    real_good_threshold real4 30.0
    real_great_threshold real4 4.0
	
	
.code

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

@score_text proc
	call sfText_create
	mov scoreText, eax

	push 0
	push offset font_path
	call sfFont_createFromFile
	add esp, 8
	mov font, eax

	push font
	push dword ptr [scoreText]
	call sfText_setFont
	add esp, 8

	push 24
	push dword ptr [scoreText]
	call sfText_setCharacterSize
	add esp, 8

	push blackColor
	push dword ptr [scoreText]
	call sfText_setFillColor
	add esp, 8

	push dword ptr [real_10]
	push dword ptr [real_10]
	push dword ptr [scoreText]
	call sfText_setPosition
	add esp, 12

	ret

@score_text ENDP

@countDown_text proc
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

main_game_page2 PROC window:dword,musicPath:dword,noteChart:dword

	push dword ptr [drumStep]
	push dword ptr [noteSpawnInterval]
	push dword ptr [noteTimings]
	push dword ptr [notes]
	push dword ptr [msInfo]
	mov dword ptr [noteChart], offset chart 
	mov eax, dword ptr [noteChart]
	push eax
	call parseNoteChart


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

	call @score_text

	call @countDown_text

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
	add esp, 4

	fstp st(0)                    ; 將結果放入浮點堆疊 (microseconds)

	; 除以1000000.0以轉換為秒
	fld real_1000000
	fdiv                        ; st(0) = st(0) / divisor
	fst currentTime             ; 儲存結果到currentTime

	; 遊戲開始倒數
	push dword ptr spawnClock
	push offset gameStartTime
	push dword ptr music
	push dword ptr msInfo
	push dword ptr countDownText
	push offset currentTime
	push dword ptr gameStarted
	call countdownEvent
	

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
		push dword ptr [stats]
		push dword ptr [drumQueue]
		push dword ptr [front]
		push dword ptr [_size]
		push 1
		call processHit
		jmp @controll_drum
	@blue_pressed:
		push dword ptr [stats]
		push dword ptr [drumQueue]
		push dword ptr [front]
		push dword ptr [_size]
		push 2
		call processHit
		jmp @controll_drum


	@controll_drum:
		mov eax, gameStarted
		cmp eax, 0
		je @render_window

		push spawnClock
		call sfClock_getElapsedTime
		add esp, 4
		movss xmm0, dword ptr [eax]
		divss xmm0, [real_1000000]
		movss [currentTime], xmm0
	@spawn_note:
		mov eax, currentNoteIndex
		cmp eax, totalNotes
		jge @render_window

		movss xmm0, [currentTime]
		movss xmm1, [noteTimings+eax*4]
		comiss xmm0, xmm1
		jb @render_window

		mov esi, offset notes
		mov ebx, [esi+eax*4]
		cmp ebx, 0
		je @next_spawn_note

		cmp ebx, 1
		je @spawn_red_note
		push dword ptr [redDrumTexture]
		sub esp, 4
		movss dword ptr [esp], xmm1
		push dword ptr [drumQueue]
		push dword ptr [rear]
		push ebx
		push dword ptr [_size]
		call spawnDrum

	@spawn_red_note:
		push dword ptr [blueDrumTexture]
		sub esp, 4
		movss dword ptr [esp], xmm1
		push dword ptr [drumQueue]
		push dword ptr [rear]
		push ebx
		push dword ptr [_size]
		call spawnDrum
		
	@next_spawn_note:
		add eax, 1
		mov currentNoteIndex, eax
		jmp @spawn_note

	push dword ptr [drumStep]
	push dword ptr [stats]
	push dword ptr [front]
	push dword ptr [drumQueue]
	push dword ptr [_size]
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
		mov esi, offset drumQueue
    draw_notes:
        cmp ecx, 0
        jz @deter_music_stop

        push 0
		mov eax, [esi + edi*4]
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
	push music
	call sfMusic_destroy
	add esp, 4

	push redDrumTexture
	call sfTexture_destroy
	add esp, 4

	push blueDrumTexture
	call sfTexture_destroy
	add esp, 4

	push font
	call sfFont_destroy
	add esp, 4

	push countDownText
	call sfText_destroy
	add esp, 4

	push scoreText
	call sfText_destroy
	add esp, 4

	push judgmentCircle
	call sfCircleShape_destroy
	add esp, 4

	push bgSprite
	call sfSprite_destroy
	add esp, 4

	push bgTexture
	call sfTexture_destroy
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
main_game_page2 ENDP

END main_game_page2
