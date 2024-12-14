.686P
.XMM
.model flat, c

include csfml.inc

extern currentPage: DWORD

.data
    ;musicPath db "assets/never-gonna-give-you-up-official-music-video.mp3", 0   ; 音樂檔案路徑
    ; 修改結構體初始化，正確給定每個成員

    bgMusic dd 0
    event sfEvent <>
    blackColor dd 0

.code

end_play_music PROC imusicp:DWORD
    push imusicp
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
end_play_music ENDP


end_game_page PROC window:DWORD, imusicp:DWORD
   push imusicp
   call end_play_music

    ; 主迴圈
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
        push blackColor
        push window
        call sfRenderWindow_clear
        add esp, 8

        ; 顯示視窗
        mov eax, DWORD PTR [window]
        push eax
        call sfRenderWindow_display
        add esp, 4

        jmp @main_loop
@end: 
    mov dword ptr [currentPage], -1

@exitLoop:
    ; 清理資源
    push bgMusic
    call sfMusic_destroy
    add esp, 4
    ret
end_game_page ENDP
END end_game_page
