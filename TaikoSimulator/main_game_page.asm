.686P
.XMM
.model flat, c
include csfml.inc
;include windows.inc

extern currentPage: DWORD

.data
    ; 檔案路徑
    bg_path db "assets/main/game_bg.jpg", 0
    font_path db "assets/main/Taiko_No_Tatsujin_Official_Font.ttf", 0

    selected_music_path db "assets/main/song1.ogg", 0
    ;selected_beatmap1_path db "assets/main/beatmap1.tja", 0
    selected_beatmap1 db "1001201000102010,1001202000002222,1001201000102000,0000000000112212", 0
    red_note_path db "assets/main/red_note.png", 0
    blue_note_path db "assets/main/blue_note.png", 0

    ; CSFML 物件
    bgTexture dd 0               ; 背景紋理
    bgSprite dd 0                ; 背景精靈
    ;circleTexture dd 0           ; 圓形音符紋理
    ;circleSprite dd 0            ; 圓形音符精靈
    redNoteTexture dd 0          ; 紅色音符紋理
    blueNoteTexture dd 0         ; 藍色音符紋理
    ;noteSprite dd 256 DUP(0)     ; 音符精靈
    noteSprite dd 0     ; 音符精靈
    font dd 0                    ; 字型
    scoreText dd 0               ; 分數文字
    comboText dd 0               ; 連擊文字
    bgMusic dd 0

    ; 視窗設定
    ;window_videoMode sfVideoMode <1280, 720, 32>
    window_realWidth dd 044a00000r ; 1280.0
    ; 事件結構
    event sfEvent <>

    ; 畫面設定
    window_videoMode sfVideoMode <1280, 720, 32> ; 視窗大小與格式
    windowTitle db "Taiko Simulator", 0          ; 視窗標題
    scrollSpeed REAL4 5.0        ; 音符滾動速度
    laneHeight REAL4 600.0       ; 音符軌道高度

    ; 顏色常數
    whiteColor sfColor <255, 255, 255, 255> ; 白色
    blackColor sfColor <0, 0, 0, 255>       ; 黑色

.code

; 載入背景
@load_bg PROC
    ; 創建背景紋理
    push 0
    push offset bg_path
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
@load_bg ENDP

; 載入音符
@load_note PROC
    ; 創建音符紋理
    push 0
    push offset red_note_path
    call sfTexture_createFromFile
    add esp, 8
    mov redNoteTexture, eax
    
    ; 創建音符精靈
    call sfSprite_create
    mov DWORD PTR [noteSprite], eax
    
    ; 設定紋理
    push 1
    mov eax, DWORD PTR [redNoteTexture]
    push eax
    mov ecx, DWORD PTR [noteSprite]
    push ecx
   call sfSprite_setTexture
    add esp, 12

    ; 創建位置向量 
    push 200 ; y 座標
    push 700  ; x 座標
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

   ; 載入背景
    call @load_bg
    test eax, eax
    jz @exit_program

    ; 載入音符
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
        ; 事件處理
        lea esi, event
        push esi
        mov eax, window
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @render_window
    
        ; 檢查關閉事件
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end

        ; 檢查滑鼠點擊
        cmp dword ptr [esi].sfEvent._type, sfEvtMouseButtonPressed
        je @render_window

        ; 檢查按鍵事件 (按下空白鍵模擬音符判定)
        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @end

        jmp @event_loop
    
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

    push 0
    mov eax, DWORD PTR [noteSprite]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

    ; 顯示視窗
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