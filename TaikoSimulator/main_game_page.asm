.686P
.XMM

.model flat, c
include csfml.inc
include windows.inc
includelib kernel32.lib
includelib msvcrt.lib

extern currentPage: DWORD
extern end_game_page:PROC

.data
    ; 檔案路徑
    bg_path db "assets/main/bg_genre_2.png", 0
    red_note_path db "assets/main/red_note.png", 0
    blue_note_path db "assets/main/blue_note.png", 0


    selectedMusicPath db "assets/main/song1.ogg", 0
    selectedBeatmapPath db "assets/main/song1.tja", 0
    red_note_sound_path db "assets/main/RedNote.wav", 0
    blue_note_sound_path db "assets/main/BlueNote.wav", 0

    ; CSFML 物件
    bgTexture dd 0
    bgSprite dd 0
    redNoteTexture dd 0
    blueNoteTexture dd 0
    noteSprites dd 256 DUP(0) ; 最多支援 256 個音符精靈
    noteCount dd 0            ; 當前音符數量
    bgmusic dd 0

    ; 計時器
    clock dd 0
    note_timer REAL4 0.0       ; 音符生成計時器
    note_interval REAL4 1200.0    ; 每 1 秒生成一個音符

    ; 視窗設定
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0
    scrollSpeed REAL4 -0.05      ; 音符滾動速度 (向左移動)

    ; 事件結構
    event sfEvent <>

    ; 確認鍵盤按鍵, 追蹤按鍵是否按下
    KeyA_state dd 0
    KeyD_state dd 0
    KeyS_state dd 0 ;   for testing

    ; 顏色常數
    whiteColor sfColor <255, 255, 255, 255> ; 白色
    blackColor sfColor <0, 0, 0, 255>       ; 黑色

    notePosition sfVector2f <1200.0, 200.0>  ; 音符的 X 和 Y 座標
    movePosition sfVector2f <-0.1, 0.0>
    notes db 256 DUP(0)
    totalNotes dd 0
    bpm REAL4 113.65
    noteSpawnInterval REAL4 0.0
    lineBuffer db 256 DUP(0)
    startTag db "#START", 0
    endTag db "#END", 0
    
     ; 判定窗口 (以毫秒計)
    hitWindowGreat DWORD 35   ; "Great" 判定範圍
    hitWindowGood  DWORD 80   ; "Good" 判定範圍
    hitWindowMiss  DWORD 120  ; "Miss" 判定範圍

    ; 用來存great good miss 的次數和最後總分
    great_count DWORD 0
    good_count DWORD 0
    miss_count DWORD 0
    score DWORD 0

.code
game_play_music PROC
    push offset selectedMusicPath
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
game_play_music ENDP

; 載入背景
@load_bg PROC
    ; 創建背景紋理
    push 0
    push offset bg_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov bgTexture, eax

    ; 創建背景精靈
    call sfSprite_create
    test eax, eax
    jz @fail_load
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

@fail_load:
    mov eax, 0
    ret
@load_bg ENDP





; 載入音符
@load_notes PROC
    ; 創建紅色音符紋理
    push 0
    push offset red_note_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov redNoteTexture, eax
    ret

@fail_load:
    mov eax, 0
    ret
@load_notes ENDP

@read_beatmap PROC


    @end:
        ret

@read_beatmap ENDP

; 生成新的音符
@generate_note PROC
    ; 如果音符超過最大數量，則跳過
    mov eax, noteCount
    cmp eax, 256   ; 生成最多 256 個音符
    jae @end

    ; 創建新的音符精靈
    call sfSprite_create
    test eax, eax
    jz @end

    ; 將新的音符精靈儲存到陣列中
    mov esi, noteCount           ; 使用 noteCount 來確保索引有效
    mov DWORD PTR [noteSprites + esi*4], eax

    ; 設定紅色音符紋理
    push 1
    mov eax, redNoteTexture
    push eax
    mov ecx, DWORD PTR [noteSprites + esi*4]
    push ecx
    call sfSprite_setTexture
    add esp, 12

    ; 設定音符初始位置
    push dword ptr [notePosition+4] ; Y 座標
    push dword ptr [notePosition]   ; X 座標
    mov eax, DWORD PTR [noteSprites + esi*4]
    push eax
    call sfSprite_setPosition
    add esp, 12

    ; 更新音符數量
    inc noteCount

    @end:
        ret

@generate_note ENDP

; 更新音符位置
@update_notes PROC
    xor esi, esi

@loop_notes:
    cmp esi, noteCount
    jge @end

    ; 檢查音符是否有效
    mov eax, DWORD PTR [noteSprites + esi*4]
    test eax, eax
    jz @next_note

    ; 移動音符
    push dword ptr [movePosition+4] ; Y 方向不變
    push scrollSpeed                ; X 方向移動
    push eax
    call sfSprite_move
    add esp, 12

@next_note:
    inc esi
    jmp @loop_notes
@end:
    ret
@update_notes ENDP

; 清理音符
@cleanup_notes PROC
    xor esi, esi

@loop_cleanup:
    cmp esi, noteCount
    jge @end

    ; 檢查音符是否有效
    mov eax, DWORD PTR [noteSprites + esi*4]
    test eax, eax
    jz @next_cleanup

    ; 銷毀音符精靈
    push eax
    call sfSprite_destroy
    add esp, 4

@next_cleanup:
    inc esi
    jmp @loop_cleanup

@end:
    ret
@cleanup_notes ENDP

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

main_game_page PROC window:DWORD
    ; 載入背景
    call @load_bg
    test eax, eax
    jz @exit_program

    ; 播放音樂
    call game_play_music

    ; 載入音符
    call @load_notes
    test eax, eax
    jz @exit_program

    ; 初始化計時器
    call sfClock_create
    test eax, eax
    jz @exit_program
    mov clock, eax

    ; 設置音符生成間隔開始時間
    movss note_timer, xmm0

@main_loop:
    ; 檢查視窗是否開啟
    mov eax, window
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exit_program


    ; 更新計時器
    mov eax, clock
    push eax
    call sfClock_getElapsedTime
    add esp, 4
    test eax, eax
    jz @exit_program               ; 如果時間返回無效，退出程式

    ; 檢查音樂是否停止
    push bgMusic
    call sfMusic_getStatus
    add esp, 4
    cmp eax, 0
    je @to_end_page

    ; 提取微秒並轉換為秒數
    mov ebx, 1000000  ; 1,000,000 用於將微秒轉換為秒
    xor edx, edx      ; 清除 edx，準備進行除法操作
    div ebx           ; eax = microseconds / 1,000,000 (秒數)
    movss note_timer, xmm0  ; 將秒數存儲到 note_timer

    ; 判斷是否生成新的音符
    movss xmm0, note_timer
    movss xmm1, note_interval
    comiss xmm0, xmm1
    jb @skip_generate_note

    ; 生成音符並重置計時器
    call @generate_note
    call sfClock_restart           ; 重置時鐘

    @event_loop:
        ; 事件處理
        lea esi, event
        push esi
        mov eax, window
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @skip_generate_note
    
        ; 檢查關閉事件
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @to_end_page

        ; 檢查滑鼠點擊
        cmp dword ptr [esi].sfEvent._type, sfEvtMouseButtonPressed
        je @skip_generate_note
    
        ; 檢查鍵盤事件
        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @check_key_press

        jmp @event_loop

        @check_key_press:
            cmp dword ptr [esi+4], sfKeyA
            je @key_A_pressed

            cmp dword ptr [esi+4], sfKeyD
            je @key_D_pressed 
            
            jmp @event_loop

@key_A_pressed:
    mov dword ptr [KeyA_state], 1 ; 設定狀態已按下 
    mov dword ptr [KeyD_state], 0
    call rednote_sound
    push eax
    add esp, 4
    ; delete the the latest note
    jmp @main_loop

@key_S_pressed:
    mov dword ptr [KeyS_state], 1 ; 設定狀態已按下
    mov dword ptr [KeyA_state], 0
   mov dword ptr [KeyD_state], 0
    mov DWORD PTR [currentPage], 3
    jmp @to_end_page


@key_D_pressed:
    mov dword ptr [KeyD_state], 1 ; 設定狀態已按下
    mov dword ptr [KeyA_state], 0
    call bluenote_sound
    push eax
    add esp, 4
    ; delete the the latest note
    jmp @main_loop
       

@skip_generate_note:
    ; 更新音符
    call @update_notes

    ; 清除視窗
    push blackColor
    push window
    call sfRenderWindow_clear
    add esp, 8

    ; 繪製背景
    push 0
    mov eax, bgSprite
    push eax
    mov ecx, window
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

    ; 繪製音符
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

    ; 顯示視窗
    mov eax, window
    push eax
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

; 準備結算
@to_end_page:

    push score    
    push miss_count    
    push good_count   
    push great_count    
    push window       
    mov DWORD PTR [currentPage], 2      ;遊戲結束要切換到結尾畫面
    call end_game_page
    add esp, 20
    jmp @exit_program



@exit_program:
    call @cleanup_notes

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push redNoteTexture
    call sfTexture_destroy
    add esp, 4

    push clock
    call sfClock_destroy
    add esp, 4




    ret
main_game_page ENDP

END main_game_page