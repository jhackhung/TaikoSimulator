.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD

BUTTON_STATE_NORMAL equ 0
BUTTON_STATE_PRESSED equ 1

Button STRUCT
    shape dd ?
    state dd ?
Button ENDS

.data
    ; 檔案路徑
    music1_path db "assets/main/song1.ogg", 0
    ;music1_path db "assets/never-gonna-give-you-up-official-music-video.mp3", 0

    music2_path db "assets/main/song2.ogg", 0
    music3_path db "assets/main/song3.ogg", 0
    bg_path db "assets/main/song_select_bg.jpg", 0
    font_path db "assets/main/Taiko_No_Tatsujin_Official_Font.ttf", 0
   
    ; 提示文字
    song1_string db "Song 1", 0
    song2_string  db "Song 2", 0
    song3_string  db "Song 3", 0
    instruction_string db "Introduction", 0
    
    ; CSFML物件
    ; window dd 0
    bgTexture dd 0
    bgSprite dd 0
    bgMusic dd 0
    font dd 0

    song1Text dd 0
    song2Text dd 0
    song3Text dd 0
    instructionText dd 0


    KeyA_state dd 0 ; 追蹤按鍵是否按下
    KeyS_state dd 0
    KeyD_state dd 0

    song1Bounds sfFloatRect <>
    song2Bounds sfFloatRect <>
    song3Bounds sfFloatRect <>
    instructionBounds sfFloatRect <>

    ; 視窗設定
    ;window_videoMode sfVideoMode <1280, 720, 32>
    window_realWidth dd 044a00000r ; 1280.0
    ; 事件結構
    event sfEvent <>

    ; 顏色常數
    gray_color sfColor <169, 169, 169, 255>
    dark_gray_color sfColor <105, 105, 105, 255>
    light_gray_color sfColor <210, 210, 210, 255>
    beige_color sfColor <255, 239, 198, 255>
    black_color sfColor <0, 0, 0, 255>

    ; 按鈕物件
    button1_shape Button <>
    button2_shape Button <>
    button3_shape Button <>
    instruction_shape Button <>
        
    ; 常數
    button_x REAL4 400.0
    button1_y REAL4 150.0
    button2_y REAL4 250.0
    button3_y REAL4 350.0
    instruction_x REAL4 160.0
    instruction_y REAL4 500.0
    button_width REAL4 480.0
    instruction_width REAL4 960.0
    button_height REAL4 60.0
    instruction_height REAL4 150.0
    outline_thickness REAL4 3.0

    two dd 2.0
    const_160 dd 160.0
    const_260 dd 260.0
    const_360 dd 360.0
    const_550 dd 550.0

.code

; 載入背景
@load_background PROC
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
@load_background ENDP


play_music PROC
    mov eax, bgMusic
    cmp eax, 0
    je @create_music
    push dword ptr [bgMusic]
    call sfMusic_getStatus
    add esp, 4
    cmp eax, 2
    jne @create_music

    @stop_music:
	   push bgMusic
	   call sfMusic_stop
	   add esp, 4

    @create_music:
		push [esp+4]
		call sfMusic_createFromFile
		add esp, 4 
		mov bgMusic, eax

		push eax
		call sfMusic_play
		add esp, 4
		ret
play_music ENDP

; 設定Song1文字
setup_song1_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [song1Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [song1Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset song1_string
    mov eax, DWORD PTR [song1Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [song1Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push black_color
    mov eax, DWORD PTR [song1Text]
    push eax
    call sfText_setFillColor
    add esp, 8
        
    ; Set position
    sub esp, 16
    lea eax, [esp]

    push DWORD PTR [song1Text]
    push eax
    call sfText_getLocalBounds
    add esp, 8

    mov edx, DWORD PTR [eax]
    mov DWORD PTR [song1Bounds.left], edx
    mov ecx, DWORD PTR [eax+4]
    mov DWORD PTR [song1Bounds.top], ecx
    mov edx, DWORD PTR [eax+8]
    mov DWORD PTR [song1Bounds._width], edx
    mov eax, DWORD PTR [eax+12]
    mov DWORD PTR [song1Bounds.height], eax

    add esp, 16
    
    ; Adjust position
    movss xmm0, DWORD PTR [window_realWidth]
    subss xmm0, DWORD PTR [song1Bounds._width]
    movss xmm1, DWORD PTR [two]
    divss xmm0, xmm1
    movss DWORD PTR [esp-8], xmm0
    
    movss xmm0, DWORD PTR [const_160]
    movss DWORD PTR [esp-4], xmm0

    mov esi, esp

    push DWORD PTR [esi-4] ; y (200.0)
    push DWORD PTR [esi-8] ; x (centered)
    push DWORD PTR [song1Text]
    call sfText_setPosition
    add esp, 12

    ret
setup_song1_text ENDP

; 設定Song2文字
setup_song2_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [song2Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [song2Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset song2_string
    mov eax, DWORD PTR [song2Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [song2Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push black_color
    mov eax, DWORD PTR [song2Text]
    push eax
    call sfText_setFillColor
    add esp, 8
        
    ; Set position
    sub esp, 16
    lea eax, [esp]

    push DWORD PTR [song2Text]
    push eax
    call sfText_getLocalBounds
    add esp, 8

    mov edx, DWORD PTR [eax]
    mov DWORD PTR [song2Bounds.left], edx
    mov ecx, DWORD PTR [eax+4]
    mov DWORD PTR [song2Bounds.top], ecx
    mov edx, DWORD PTR [eax+8]
    mov DWORD PTR [song2Bounds._width], edx
    mov eax, DWORD PTR [eax+12]
    mov DWORD PTR [song2Bounds.height], eax

    add esp, 16
    
    ; Adjust position
    movss xmm0, DWORD PTR [window_realWidth]
    subss xmm0, DWORD PTR [song2Bounds._width]
    movss xmm1, DWORD PTR [two]
    divss xmm0, xmm1
    movss DWORD PTR [esp-8], xmm0
    
    movss xmm0, DWORD PTR [const_260]
    movss DWORD PTR [esp-4], xmm0

    mov esi, esp

    push DWORD PTR [esi-4] ; y (200.0)
    push DWORD PTR [esi-8] ; x (centered)
    push DWORD PTR [song2Text]
    call sfText_setPosition
    add esp, 12

    ret
setup_song2_text ENDP

; 設定Song3文字
setup_song3_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [song3Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [song3Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset song3_string
    mov eax, DWORD PTR [song3Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [song3Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push black_color
    mov eax, DWORD PTR [song3Text]
    push eax
    call sfText_setFillColor
    add esp, 8
       
    ; Set position
    sub esp, 16
    lea eax, [esp]

    push DWORD PTR [song3Text]
    push eax
    call sfText_getLocalBounds
    add esp, 8

    mov edx, DWORD PTR [eax]
    mov DWORD PTR [song3Bounds.left], edx
    mov ecx, DWORD PTR [eax+4]
    mov DWORD PTR [song3Bounds.top], ecx
    mov edx, DWORD PTR [eax+8]
    mov DWORD PTR [song3Bounds._width], edx
    mov eax, DWORD PTR [eax+12]
    mov DWORD PTR [song3Bounds.height], eax

    add esp, 16
    
    ; Adjust position
    movss xmm0, DWORD PTR [window_realWidth]
    subss xmm0, DWORD PTR [song3Bounds._width]
    movss xmm1, DWORD PTR [two]
    divss xmm0, xmm1
    movss DWORD PTR [esp-8], xmm0
    
    movss xmm0, DWORD PTR [const_360]
    movss DWORD PTR [esp-4], xmm0

    mov esi, esp

    push DWORD PTR [esi-4] ; y (200.0)
    push DWORD PTR [esi-8] ; x (centered)
    push DWORD PTR [song3Text]
    call sfText_setPosition
    add esp, 12

    ret
setup_song3_text ENDP

; 設定instruction文字
setup_instruction_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [instructionText], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [instructionText]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset instruction_string
    mov eax, DWORD PTR [instructionText]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [instructionText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push black_color
    mov eax, DWORD PTR [instructionText]
    push eax
    call sfText_setFillColor
    add esp, 8
    
    ; Set position
    sub esp, 16
    lea eax, [esp]

    push DWORD PTR [instructionText]
    push eax
    call sfText_getLocalBounds
    add esp, 8

    mov edx, DWORD PTR [eax]
    mov DWORD PTR [instructionBounds.left], edx
    mov ecx, DWORD PTR [eax+4]
    mov DWORD PTR [instructionBounds.top], ecx
    mov edx, DWORD PTR [eax+8]
    mov DWORD PTR [instructionBounds._width], edx
    mov eax, DWORD PTR [eax+12]
    mov DWORD PTR [instructionBounds.height], eax

    add esp, 16
    
    ; Adjust position
    movss xmm0, DWORD PTR [window_realWidth]
    subss xmm0, DWORD PTR [instructionBounds._width]
    movss xmm1, DWORD PTR [two]
    divss xmm0, xmm1
    movss DWORD PTR [esp-8], xmm0
    
    movss xmm0, DWORD PTR [const_550]
    movss DWORD PTR [esp-4], xmm0

    mov esi, esp

    push DWORD PTR [esi-4] ; y (200.0)
    push DWORD PTR [esi-8] ; x (centered)
    push DWORD PTR [instructionText]
    call sfText_setPosition
    add esp, 12

    ret
setup_instruction_text ENDP

; 創建按鈕
create_button PROC
    
    push ebp
    mov ebp, esp

    ; 呼叫函數創建矩形
    call sfRectangleShape_create
    mov esi, eax  ; 儲存矩形物件

    ; 創建位置向量 !程式位置存在ebp+4
    push dword ptr [ebp+12] ; y 座標
    push dword ptr [ebp+8]  ; x 座標
    push esi
    call sfRectangleShape_setPosition
    add esp, 12

    ; 設定大小
    push dword ptr [ebp+20] ; 高度
    push dword ptr [ebp+16] ; 寬度
    push esi
    call sfRectangleShape_setSize
    add esp, 12

    ; 設定填充顏色
    push gray_color
    push esi
    call sfRectangleShape_setFillColor
    add esp, 8

    ; 設定邊框顏色
    push dark_gray_color
    push esi
    call sfRectangleShape_setOutlineColor
    add esp, 8

    ; 設定邊框厚度  
    sub esp, 4
    movss xmm0, dword ptr [outline_thickness]
    movss dword ptr [esp], xmm0
    push esi
    call sfRectangleShape_setOutlineThickness
    add esp, 8

    ; 返回按鈕物件
    mov eax, esi

    pop ebp
    ret
create_button ENDP

; 初始化按鈕
init_buttons PROC
    ; 初始化按鈕1
    push ecx
    movss xmm0, dword ptr [button_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button1_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [button1_shape], eax
    mov dword ptr [button1_shape.state], BUTTON_STATE_NORMAL

    ; 初始化按鈕2
    push ecx
    movss xmm0, dword ptr [button_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button2_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [button2_shape], eax
    mov dword ptr [button2_shape.state], BUTTON_STATE_NORMAL

    ; 初始化按鈕3
    push ecx
    movss xmm0, dword ptr [button_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button3_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [button3_shape], eax
    mov dword ptr [button3_shape.state], BUTTON_STATE_NORMAL

    ; 初始化介紹框
    push ecx
    movss xmm0, dword ptr [instruction_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [instruction_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [instruction_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [instruction_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [instruction_shape], eax
    mov dword ptr [instruction_shape.state], BUTTON_STATE_NORMAL

    ; 修改底部長方形顏色和邊框
    push beige_color  ; 鵝黃色
    push dword ptr [instruction_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push black_color  ; 黑色邊框
    push dword ptr [instruction_shape]
    call sfRectangleShape_setOutlineColor
    add esp, 8

    ret
init_buttons ENDP

; 釋放資源
cleanup PROC
    ; push window
    ; call sfRenderWindow_destroy

    push bgMusic
    call sfMusic_destroy
    add esp, 4

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push song1Text
    call sfText_destroy
    add esp, 4

    push song2Text
    call sfText_destroy
    add esp, 4

    push song3Text
    call sfText_destroy
    add esp, 4

    push instructionText
    call sfText_destroy
    add esp, 4

    push font
    call sfFont_destroy
    add esp, 4 
    
    push dword ptr [button1_shape]
    call sfRectangleShape_destroy
    add esp, 4
    
    push dword ptr [button2_shape]
    call sfRectangleShape_destroy
    add esp, 4
    
    push dword ptr [button3_shape]
    call sfRectangleShape_destroy
    add esp, 4

    push dword ptr [instruction_shape]
    call sfRectangleShape_destroy
    add esp, 4
   
    ret
cleanup ENDP

select_music_page PROC window:DWORD

   ; 載入背景
    call @load_background
    test eax, eax
    jz @exit_program
    
    mov bgMusic, 0

    ; 設定按鈕
    call init_buttons

    ; 設定提示文字
    call setup_song1_text
    call setup_song2_text
    call setup_song3_text
    call setup_instruction_text

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
    
        ; 檢查鍵盤事件
        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @check_key_press

        jmp @event_loop

        @check_key_press:
            cmp dword ptr [esi+4], sfKeyA
            je @key_1_pressed

            cmp dword ptr [esi+4], sfKeyS
            je @key_2_pressed

            cmp dword ptr [esi+4], sfKeyD
            je @key_3_pressed

            cmp dword ptr [esi+4], sfKeyEnter
            je @check_enter     
            
            jmp @event_loop

@key_1_pressed:
    mov dword ptr [KeyA_state], 1 ; 設定狀態已按下 
    mov dword ptr [KeyS_state], 0
    mov dword ptr [KeyD_state], 0

    push offset music1_path
    call play_music
    add esp, 4

    push light_gray_color
    push DWORD PTR [button1_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push gray_color
    push DWORD PTR [button2_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push gray_color
    push DWORD PTR [button3_shape]
    call sfRectangleShape_setFillColor
    add esp, 8
    jmp @event_loop

@key_2_pressed:
    mov dword ptr [KeyS_state], 1 ; 設定狀態已按下
    mov dword ptr [KeyA_state], 0
    mov dword ptr [KeyD_state], 0

    push offset music2_path
    call play_music
    add esp, 4

    push light_gray_color
    push DWORD PTR [button2_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push gray_color
    push DWORD PTR [button1_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push gray_color
    push DWORD PTR [button3_shape]
    call sfRectangleShape_setFillColor
    add esp, 8
    jmp @event_loop

@key_3_pressed:
    mov dword ptr [KeyD_state], 1 ; 設定狀態已按下
    mov dword ptr [KeyA_state], 0
    mov dword ptr [KeyS_state], 0

    push offset music3_path
    call play_music
    add esp, 4

    push light_gray_color
    push DWORD PTR [button3_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push gray_color
    push DWORD PTR [button1_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push gray_color
    push DWORD PTR [button2_shape]
    call sfRectangleShape_setFillColor
    add esp, 8
    jmp @event_loop

@check_enter:
    cmp dword ptr [KeyA_state], 1 
    je @keyA_enter

    cmp dword ptr [KeyS_state], 1 
    je @keyS_enter

    cmp dword ptr [KeyD_state], 1 
    je @keyD_enter

    jne @event_loop              

@keyA_enter:
    mov DWORD PTR [currentPage], 2
    mov ebx, offset music1_path
    jmp @exit_program

@keyS_enter:
    mov DWORD PTR [currentPage], 2
    mov ebx, offset music2_path
    jmp @exit_program

@keyD_enter:
    mov DWORD PTR [currentPage], 2
    mov ebx, offset music3_path
    jmp @exit_program
    
@render_window: 
    ; 清除視窗
    push black_color
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

    ; 繪製按鈕
    push 0
    mov eax, DWORD PTR [button1_shape]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawRectangleShape
    add esp, 12

    push 0
    mov eax, DWORD PTR [button2_shape]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawRectangleShape
    add esp, 12
    
    push 0
    mov eax, DWORD PTR [button3_shape]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawRectangleShape
    add esp, 12

    push 0
    mov eax, DWORD PTR [instruction_shape]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawRectangleShape
    add esp, 12

    ; 繪製song1
    push 0
    push DWORD PTR [song1Text]
    push DWORD PTR [window]
    call sfRenderWindow_drawText
    add esp, 12

    ; 繪製song2
    push 0
    push DWORD PTR [song2Text]
    push DWORD PTR [window]
    call sfRenderWindow_drawText
    add esp, 12

    ; 繪製song3
    push 0
    push DWORD PTR [song3Text]
    push DWORD PTR [window]
    call sfRenderWindow_drawText
    add esp, 12

    ; 繪製instruction
    push 0
    push DWORD PTR [instructionText]
    push DWORD PTR [window]
    call sfRenderWindow_drawText
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
    call cleanup
    xor eax, eax
    ret

select_music_page ENDP

END select_music_page