.686P
.XMM
.model flat, c
include csfml.inc
include file.inc

extern currentPage: DWORD
extern main_game_page: proc

BUTTON_STATE_NORMAL equ 0
BUTTON_STATE_PRESSED equ 1

Button STRUCT
    shape dd ?
    state dd ?
Button ENDS

.data
    ; 檔案路徑
    music1_path db "assets/music/Yoru ni Kakeru.ogg", 0
    music2_path db "assets/music/Zen Zen Zense.ogg", 0
    music3_path db "assets/music/Zenryoku Shounen.ogg", 0
    bg_path db "assets/main/song_select_bg.jpg", 0
    font_path db "assets/fonts/Taiko_No_Tatsujin_Official_Font.ttf", 0
   
   ; music1 資料
   music1Info MusicInfo <130.000000, -1.962000, 115.384613>
   music1_notes dword 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
                dword 2, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1
                dword 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1
   music1_totalNotes dword 90
   music1_noteTimings real4 0.000000, 0.923077, 1.846154, 2.769229, 3.653842, 7.384611, 8.307688, 9.230764, 10.153841, 11.076918, 12.884617, 14.769233, 15.692309, 16.615387, 17.538464, 18.461540, 19.384617, 20.307693, 22.153847, 23.076923, 24.000000, 24.923077, 25.846153, 26.769230, 27.692307, 29.076921, 29.538460, 31.384613, 33.230766, 35.076920
                real4 36.923073, 38.769226, 40.615379, 44.307686, 45.230762, 46.153839, 47.999992, 48.923069, 49.846146, 51.692299, 52.615376, 53.538452, 55.384605, 56.961456, 59.076828, 60.922981, 62.769135, 65.538368, 66.461449, 67.384529, 68.307610, 70.153763, 71.076843, 71.999924, 73.846077, 74.769157, 75.692238, 76.153778, 76.615318, 77.538399
                real4 78.461479, 79.384560, 79.846100, 80.307640, 81.230721, 81.692261, 82.153801, 83.076881, 83.538422, 83.999962, 84.923042, 88.615349, 89.538429, 90.461510, 90.923050, 91.384590, 92.307671, 93.230751, 94.153831, 94.615372, 95.076912, 95.999992, 96.461533, 96.923073, 97.846153, 98.307693, 98.769234, 99.692314, 100.615395, 101.538475

    ; music2 資料
    music2Info MusicInfo <190.000000, -1.688, 78.947365>
    music2_notes dword 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1
                 dword 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 2, 2, 2, 1, 2, 1, 1, 1, 2, 2, 2, 2, 1, 2, 1, 1, 1, 1, 1, 2
                 dword 2, 1, 2, 1, 1, 1, 1, 1, 2, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 1, 1, 1, 2, 2
                 dword 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1
    music2_totalNotes dword 121
    music2_noteTimings real4 0.963158, 1.910526, 3.489474, 4.121053, 4.752632, 5.068421, 5.384211, 6.015789, 6.647368, 7.278947, 7.594736, 7.910525, 8.542104, 9.173683, 9.805262, 10.121051, 10.436840, 11.068419, 12.147362, 12.331572, 13.278939, 13.594728, 14.226307, 15.489464, 16.121042, 18.647358, 18.963148, 19.278938, 19.910519, 20.226307
                       real4 20.542095, 21.015778, 21.621038, 23.699982, 24.331560, 25.594717, 26.226295, 28.752609, 29.068399, 29.384190, 30.015770, 30.331560, 30.647350, 31.278931, 31.884192, 33.805279, 34.121067, 34.436855, 35.068432, 35.384220, 35.700008, 36.015797, 36.331585, 37.252701, 38.857986, 39.173775, 39.489563, 40.121140, 40.436928, 40.752716
                       real4 41.068504, 41.384293, 43.279030, 43.910610, 44.226398, 44.542187, 45.173763, 45.489552, 45.805340, 46.121128, 46.436916, 48.331654, 48.963234, 50.226391, 50.857971, 51.489552, 52.752708, 54.015865, 55.279022, 55.910603, 56.542183, 58.726456, 59.068584, 60.331741, 60.963322, 61.594902, 61.910690, 62.226479, 62.700161, 63.331738
                       real4 64.121208, 65.515938, 66.331665, 66.963219, 67.594795, 68.226372, 68.857948, 69.173737, 71.068474, 71.700050, 72.015846, 72.331642, 72.805336, 73.436928, 74.226418, 75.621147, 76.436874, 77.068428, 77.700005, 78.331589, 78.963181, 79.121078, 80.226341, 81.805290, 82.436867, 83.068443, 83.384239, 83.700035, 84.173729, 85.726357, 86.226318
    
    ; music3 資料
    music3Info MusicInfo <134.000000, -7.430000, 111.515877>
    music3_notes dword 1, 2, 1, 2, 2, 1, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2
                 dword 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
                 dword 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1
                 dword 1, 2, 2, 1, 2, 1, 1, 1
    music3_totalNotes dword 98
    music3_noteTimings real4 5.373135, 7.164181, 8.955227, 10.746273, 11.417915, 12.537319, 12.985081, 13.880604, 14.776127, 15.671650, 16.119411, 17.835831, 19.701504, 20.149265, 21.044788, 21.940311, 22.835835, 23.283596, 25.000015, 26.865688, 28.656734, 29.552258, 30.447781, 30.895542, 32.238815, 33.134293, 33.805901, 35.820724, 36.716202, 37.387810
                       real4 38.283287, 39.402634, 39.850372, 40.298111, 40.969719, 42.238312, 42.984543, 43.880020, 44.775497, 45.223236, 46.566452, 47.461929, 48.133537, 50.148361, 51.043839, 51.715446, 52.610924, 53.730270, 54.625748, 55.297356, 57.312180, 58.207657, 59.103134, 59.998611, 60.894089, 61.341827, 61.789566, 62.461174, 65.296982, 66.267181
                       real4 66.714966, 68.058319, 68.729996, 69.625565, 70.894287, 71.640594, 72.088379, 72.536163, 73.879517, 74.327301, 75.222870, 75.670654, 76.118439, 77.461792, 77.909576, 78.805145, 79.252930, 80.596283, 81.044067, 81.491852, 81.939636, 82.387421, 84.178467, 85.969513, 86.417297, 86.865082, 88.208435, 88.656219, 89.551788, 89.999573
                       real4 90.447357, 91.790710, 92.238495, 93.134064, 93.805740, 94.701309, 95.596878, 96.716339

    ; 文字相關
    song1_string db "Yoru ni Kakeru", 0
    song2_string  db "Zen Zen Zense", 0
    song3_string  db "Zenryoku Shounen", 0
    instruction_string db "Use A/S/D to select songs", 0Dh, 0Ah, 0Dh, 0Ah,"F/J to hit the red note   K/D to hit the blue note", 0
    
    ; CSFML物件
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
    const_550 dd 520.0

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
    call cleanup
    push offset music1Info
    push offset music1_noteTimings
    push offset music1_totalNotes
    push offset music1_notes
    push offset music1_path
    push dword ptr [window]
    call main_game_page
    jmp @exit_program

@keyS_enter:
    mov DWORD PTR [currentPage], 2
    call cleanup
    push offset music2Info
    push offset music2_noteTimings
    push offset music2_totalNotes
    push offset music2_notes
    push offset music2_path
    push dword ptr [window]
    call main_game_page
    jmp @exit_program

@keyD_enter:
    mov DWORD PTR [currentPage], 2
    call cleanup
    push offset music3Info
    push offset music3_noteTimings
    push offset music3_totalNotes
    push offset music3_notes
    push offset music3_path
    push dword ptr [window]
    call main_game_page
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
    xor eax, eax
    ret

select_music_page ENDP

END select_music_page