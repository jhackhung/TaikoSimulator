.386
.model flat, c

EXTERN sfRenderWindow_create:PROC
EXTERN sfRenderWindow_display:PROC
EXTERN sfRenderWindow_clear:PROC
EXTERN sfRenderWindow_destroy:PROC
EXTERN sfRenderWindow_pollEvent:PROC
EXTERN sfMusic_createFromFile:PROC
EXTERN sfMusic_play:PROC
EXTERN sfMusic_destroy:PROC

sfVideoMode STRUCT
	_width dd ?
	height dd ?
	bpp dd ?
sfVideoMode ENDS
.data
    musicPath db "never-gonna-give-you-up-official-music-video.mp3", 0   ; 音樂檔案路徑
    window_t byte "SFML Window", 0
    ; 修改結構體初始化，正確給定每個成員
    window_videoMode sfVideoMode <>

window DWORD ?
.code

main PROC
    ; This is jack branch
   mov esi, esp ; test
   push 0
   push 6
   push offset window_t
   sub esp, 12
   mov eax, esp
   mov ecx, 800
   mov [eax], ecx
   mov ecx, 600
   mov [eax+4], ecx
   mov ecx, 32
   mov [eax+8], ecx
    call sfRenderWindow_create
    add esp, 24
   
   mov window, eax

    ; 檢查是否成功創建視窗
    test eax, eax
    jz exitLoop                    ; 若返回值為 0，則視窗創建失敗，退出

    mov ebx, eax                   ; 保存視窗指標

    ; 加載音樂
    push OFFSET musicPath
    call sfMusic_createFromFile
    mov edi, eax  ; 保存音樂指標

    ; 播放音樂
    push edi
    call sfMusic_play

    ; 主迴圈
mainLoop:
    ; 清空視窗
    mov ebx, window
    push ebx
    call sfRenderWindow_clear
    pop ebx

    push ebx
    ; 顯示視窗內容
    call sfRenderWindow_display
    pop ebx

    ; 檢查視窗是否被關閉
    call sfRenderWindow_pollEvent
    cmp eax, 0   ; 假設0表示沒有事件
    je mainLoop  ; 如果沒有事件，繼續迴圈

    ; 如果有事件，檢查是否為關閉事件
    cmp eax, 1   ; 假設1是關閉事件
    ; je exitLoop

    ; 重新進入主迴圈
    jmp mainLoop

exitLoop:
    ; 清理資源
    push edi
    call sfMusic_destroy

    push ebx
    call sfRenderWindow_destroy

    ret
main ENDP
END main
