.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD
PUBLIC end_game_page

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

    countGreat dd 0
    countGood dd 0
    countMiss dd 0
    countScore dd 0

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

end_play_music PROC
    push offset musicPath
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
end_play_music ENDP


end_game_page PROC window:DWORD
   
   call end_play_music

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

        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @check_key

        jmp @event_loop

        @check_key:
            cmp dword ptr [esi+4], sfKeyEscape
            je @end
    
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
