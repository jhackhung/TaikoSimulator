.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD
extern countGreat: DWORD
extern countGood: DWORD
extern countMiss: DWORD
extern countScore: DWORD

BUTTON_STATE_NORMAL equ 0

Button STRUCT
    shape dd ?
    state dd ?
Button ENDS

.data
    music_path db "assets/never-gonna-give-you-up-official-music-video.mp3", 0   
    bg_path db "assets/main/end_bg.jpg", 0
    font_path db "assets/main/Taiko_No_Tatsujin_Official_Font.ttf", 0

    ; 提示文字
    string1 db "Great", 0          
    string2 db "Good", 0
    string3 db "Miss", 0

    ; CSFML物件
    bgTexture dd 0
    bgSprite dd 0
    bgMusic dd 0
    font dd 0
    event sfEvent <>
    window_realWidth dd 044a00000r ; 1280.0

    countGreatText dd 0
    countGreatStr db 20 dup(0)
    buffer db 20 dup(0)
    countGoodText dd 0
    countGoodStr db 20 dup(0)
    buffer_1 db 20 dup(0)
    countMissText dd 0
    countMissStr db 20 dup(0)
    buffer_2 db 20 dup(0)
    countScoreText dd 0
    countScoreStr db 20 dup(0)
    buffer_3 db 20 dup(0)

    string1Text dd 0
    string2Text dd 0
    string3Text dd 0
    string1Bounds sfFloatRect <>
    string2Bounds sfFloatRect <>
    string3Bounds sfFloatRect <>

    rect_shape Button <>
    score_shape Button <>

    ; 常數
    rect_x REAL4 280.0
    rect_y REAL4 60.0
    rect_height REAL4 300.0
    rect_width REAL4 720.0
    score_x REAL4 515.0
    score_y REAL4 90.0
    score_height REAL4 60.0
    score_width REAL4 250.0

    two dd 2.0
    four dd 4.0    
    const_180 dd 180.0
    const_360 dd 360.0
    const_600 dd 600.0
    const_840 dd 840.0

    countGreat_x dd 385.0 
    countGreat_y dd 250.0 
    countGood_x dd 625.0  
    countMiss_x dd 855.0  
    countScore_x dd 588.0  
    countScore_y dd 94.0 

    ; 顏色常數
    orange_color sfColor <229, 109, 50, 255>
    white_color sfColor <255, 255, 255, 255>
    red_color sfColor <180, 50, 50, 185>
    black_color sfColor <0, 0, 0, 255>
    trans_white_color sfColor <255, 255, 255, 185>
    gray_color sfColor <80, 80, 80, 255>
    blue_color sfColor <20, 60, 100, 185>

.code

; 載入背景
load_end_background PROC
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
load_end_background ENDP

; 設定音樂
end_play_music PROC
    push offset music_path
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
end_play_music ENDP

; 設定String1文字
setup_string1_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [string1Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset string1
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push white_color
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setFillColor
    add esp, 8

    ; Set outline color
    push red_color
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setOutlineColor
    add esp, 8
    
    ; Set outline thickness
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0 
    push DWORD PTR [string1Text]
    call sfText_setOutlineThickness
    add esp, 8
    
    ; Set position
    movss xmm0, DWORD PTR [const_180]  
    movss xmm1, DWORD PTR [const_360]     
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0     
    push DWORD PTR [string1Text]      
    call sfText_setPosition
    add esp, 12                   

    ret
setup_string1_text ENDP

; 設定String2文字
setup_string2_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [string2Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset string2
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push white_color
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setFillColor
    add esp, 8
  
      ; Set outline color
    push orange_color
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setOutlineColor
    add esp, 8
    
    ; Set outline thickness
    movss xmm0, DWORD PTR [four] 
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [string2Text]
    call sfText_setOutlineThickness
    add esp, 8

    ; Set position
    movss xmm0, DWORD PTR [const_180]  
    movss xmm1, DWORD PTR [const_600]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1           
    movss DWORD PTR [esp+4], xmm0         
    push DWORD PTR [string2Text]          
    call sfText_setPosition
    add esp, 12                         

    ret
setup_string2_text ENDP

; 設定String3文字
setup_string3_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [string3Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset string3
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push white_color
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setFillColor
    add esp, 8
   
    ; Set outline color
    push blue_color
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setOutlineColor
    add esp, 8
    
    ; Set outline thickness
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [string3Text]
    call sfText_setOutlineThickness
    add esp, 8

    ; Set position
    movss xmm0, DWORD PTR [const_180] 
    movss xmm1, DWORD PTR [const_840]  
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0        
    push DWORD PTR [string3Text]          
    call sfText_setPosition
    add esp, 12                    

    ret
setup_string3_text ENDP

; 設定countGreat文字
setup_countgreat_text PROC

    call sfText_create
    mov DWORD PTR [countGreatText], eax
   
    push font
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer
    push dword ptr [countGreat]
    call int_to_str
    add esp, 8

    push offset countGreatStr
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
   
    push white_color
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setFillColor
    add esp, 8

    push red_color
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setOutlineColor
    add esp, 8
   
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [countGreatText]
    call sfText_setOutlineThickness
    add esp, 8

    movss xmm0, DWORD PTR [countGreat_y]  
    movss xmm1, DWORD PTR [countGreat_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countGreatText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countgreat_text ENDP

; 設定countGood文字
setup_countgood_text PROC

    call sfText_create
    mov DWORD PTR [countGoodText], eax
   
    push font
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer_1
    push dword ptr [countGood]
    call int_to_str_1
    add esp, 8

    push offset countGoodStr
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setCharacterSize
    add esp, 8

    push white_color
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setFillColor
    add esp, 8

    push orange_color
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setOutlineColor
    add esp, 8
   
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [countGoodText]
    call sfText_setOutlineThickness
    add esp, 8

    movss xmm0, DWORD PTR [countGreat_y]  
    movss xmm1, DWORD PTR [countGood_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countGoodText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countgood_text ENDP

; 設定countMiss文字
setup_countmiss_text PROC

    call sfText_create
    mov DWORD PTR [countMissText], eax
   
    push font
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer_2
    push dword ptr [countMiss]
    call int_to_str_2
    add esp, 8

    push offset countMissStr
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
   
    push white_color
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setFillColor
    add esp, 8

    push blue_color
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setOutlineColor
    add esp, 8
   
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [countMissText]
    call sfText_setOutlineThickness
    add esp, 8

    movss xmm0, DWORD PTR [countGreat_y]  
    movss xmm1, DWORD PTR [countMiss_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countMissText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countmiss_text ENDP

; 設定countScore文字
setup_countscore_text PROC

    call sfText_create
    mov DWORD PTR [countScoreText], eax
   
    push font
    mov eax, DWORD PTR [countScoreText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer_3
    push dword ptr [countScore]
    call int_to_str_3
    add esp, 8

    push offset countScoreStr
    mov eax, DWORD PTR [countScoreText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countScoreText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
   
    push white_color
    mov eax, DWORD PTR [countScoreText]
    push eax
    call sfText_setFillColor
    add esp, 8

    movss xmm0, DWORD PTR [countScore_y]  
    movss xmm1, DWORD PTR [countScore_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countScoreText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countscore_text ENDP

strcpy PROC
    push ebp
    mov ebp, esp
    
    ; 取得來源和目標位址
    mov esi, [ebp+8]   ; 來源字串
    mov edi, [ebp+12]  ; 目標字串

@copy_loop:
    mov al, [esi]     ; 載入來源字元
    mov [edi], al     ; 複製到目標
    
    test al, al       ; 檢查是否為字串結尾（0）
    jz @done          ; 如果是，結束複製
    
    inc esi           ; 移動來源指標
    inc edi           ; 移動目標指標
    jmp @copy_loop

@done:
    pop ebp
    ret
strcpy ENDP

; 整數轉字串的程序
int_to_str PROC
    push ebp
    mov ebp, esp

    ; 參數：number(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; 取得數字
    mov esi, [ebp+12]  ; 取得緩衝區位址
    mov ecx, 10        ; 除數
    mov edi, 0         ; 位數計數器

    ; 特殊情況：數字為 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; 清除 edx 準備除法
    div ecx           ; 除以 10
    add edx, '0'      ; 轉換餘數為字元
    push edx          ; 暫存字元
    inc edi           ; 增加位數
    test eax, eax     ; 是否還有數字
    jnz @convert_loop

@reverse_loop:
    pop edx           ; 取出字元
    mov [esi], dl     ; 存入緩衝區
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; 加入結束符

@done:
    ; 移動字串到 countGreatStr
    push offset countGreatStr
    push offset buffer
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str ENDP

; 整數轉字串的程序
int_to_str_1 PROC
    push ebp
    mov ebp, esp

    ; 參數：number(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; 取得數字
    mov esi, [ebp+12]  ; 取得緩衝區位址
    mov ecx, 10        ; 除數
    mov edi, 0         ; 位數計數器

    ; 特殊情況：數字為 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; 清除 edx 準備除法
    div ecx           ; 除以 10
    add edx, '0'      ; 轉換餘數為字元
    push edx          ; 暫存字元
    inc edi           ; 增加位數
    test eax, eax     ; 是否還有數字
    jnz @convert_loop

@reverse_loop:
    pop edx           ; 取出字元
    mov [esi], dl     ; 存入緩衝區
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; 加入結束符

@done:
    ; 移動字串到 countGoodStr
    push offset countGoodStr
    push offset buffer_1
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str_1 ENDP

; 整數轉字串的程序
int_to_str_2 PROC
    push ebp
    mov ebp, esp

    ; 參數：number(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; 取得數字
    mov esi, [ebp+12]  ; 取得緩衝區位址
    mov ecx, 10        ; 除數
    mov edi, 0         ; 位數計數器

    ; 特殊情況：數字為 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; 清除 edx 準備除法
    div ecx           ; 除以 10
    add edx, '0'      ; 轉換餘數為字元
    push edx          ; 暫存字元
    inc edi           ; 增加位數
    test eax, eax     ; 是否還有數字
    jnz @convert_loop

@reverse_loop:
    pop edx           ; 取出字元
    mov [esi], dl     ; 存入緩衝區
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; 加入結束符

@done:
    push offset countMissStr
    push offset buffer_2
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str_2 ENDP

; 整數轉字串的程序
int_to_str_3 PROC
    push ebp
    mov ebp, esp

    ; 參數：number(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; 取得數字
    mov esi, [ebp+12]  ; 取得緩衝區位址
    mov ecx, 10        ; 除數
    mov edi, 0         ; 位數計數器

    ; 特殊情況：數字為 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; 清除 edx 準備除法
    div ecx           ; 除以 10
    add edx, '0'      ; 轉換餘數為字元
    push edx          ; 暫存字元
    inc edi           ; 增加位數
    test eax, eax     ; 是否還有數字
    jnz @convert_loop

@reverse_loop:
    pop edx           ; 取出字元
    mov [esi], dl     ; 存入緩衝區
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; 加入結束符

@done:
    push offset countScoreStr
    push offset buffer_3
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str_3 ENDP

; 創建rect
create_rect PROC
    
    push ebp
    mov ebp, esp

    call sfRectangleShape_create
    mov esi, eax  

    push dword ptr [ebp+12] 
    push dword ptr [ebp+8]  
    push esi
    call sfRectangleShape_setPosition
    add esp, 12

    ; 設定大小
    push dword ptr [ebp+20] 
    push dword ptr [ebp+16] 
    push esi
    call sfRectangleShape_setSize
    add esp, 12

    ; 設定填充顏色
    push trans_white_color
    push esi
    call sfRectangleShape_setFillColor
    add esp, 8

    ; 返回按鈕物件
    mov eax, esi

    pop ebp
    ret
create_rect ENDP

init_rect PROC
    ; 初始化rect
    push ecx
    movss xmm0, dword ptr [rect_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [rect_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [rect_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [rect_x]
    movss dword ptr [esp], xmm0

    call create_rect
    add esp, 16
    mov dword ptr [rect_shape], eax
    mov dword ptr [rect_shape.state], BUTTON_STATE_NORMAL

    ; 初始化score
    push ecx
    movss xmm0, dword ptr [score_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [score_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [score_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [score_x]
    movss dword ptr [esp], xmm0

    call create_rect
    add esp, 16
    mov dword ptr [score_shape], eax
    mov dword ptr [score_shape.state], BUTTON_STATE_NORMAL

    push gray_color 
    push dword ptr [score_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    ret
init_rect ENDP

; 釋放資源
end_cleanup PROC

    push bgMusic
    call sfMusic_destroy
    add esp, 4

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push string1Text
    call sfText_destroy
    add esp, 4

    push string2Text
    call sfText_destroy
    add esp, 4

    push string3Text
    call sfText_destroy
    add esp, 4

    push font
    call sfFont_destroy
    add esp, 4
    
    push dword ptr [rect_shape]
    call sfRectangleShape_destroy
    add esp, 4

    push dword ptr [score_shape]
    call sfRectangleShape_destroy
    add esp, 4

    push countGreatText
    call sfText_destroy
    add esp, 4

    push countGoodText
    call sfText_destroy
    add esp, 4

    push countMissText
    call sfText_destroy
    add esp, 4    

    push countScoreText
    call sfText_destroy
    add esp, 4 
    ret
end_cleanup ENDP

end_game_page PROC window:DWORD

    ; 載入背景
    call end_play_music
    call load_end_background
    test eax, eax
    jz @exitLoop

    mov bgMusic, 0

    ; 設定按鈕
    call init_rect

    ; 設定提示文字
    call setup_string1_text
    call setup_string2_text
    call setup_string3_text
    call setup_countgreat_text
    call setup_countgood_text
    call setup_countmiss_text
    call setup_countscore_text

@main_loop:
    
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exitLoop

    @event_loop:

        ; 事件處理
        lea esi, event
        push esi
        push window
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @render_window
    
        ; 檢查關閉事件
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end

        jmp @event_loop
    
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

        ; 繪製rect
        push 0
        mov eax, DWORD PTR [rect_shape]
        push eax
        mov ecx, DWORD PTR [window]
        push ecx
        call sfRenderWindow_drawRectangleShape
        add esp, 12

        ; 繪製score
        push 0
        mov eax, DWORD PTR [score_shape]
        push eax
        mov ecx, DWORD PTR [window]
        push ecx
        call sfRenderWindow_drawRectangleShape
        add esp, 12

        ; 繪製string1
        push 0
        push DWORD PTR [string1Text]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; 繪製string2
        push 0
        push DWORD PTR [string2Text]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; 繪製string3
        push 0
        push DWORD PTR [string3Text]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; 繪製countgreat
        push 0
        push DWORD PTR [countGreatText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; 繪製countgood
        push 0
        push DWORD PTR [countGoodText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; 繪製countmiss
        push 0
        push DWORD PTR [countMissText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; 繪製countscore
        push 0
        push DWORD PTR [countScoreText]
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
    mov dword ptr [currentPage], -1

@exitLoop:
    call end_cleanup
    xor eax, eax
    ret

end_game_page ENDP

END end_game_page
