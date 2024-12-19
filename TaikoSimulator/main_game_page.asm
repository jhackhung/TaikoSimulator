.model flat, c
include csfml.inc
include windows.inc

extern currentPage: DWORD
extern create_button: PROC

GENERIC_READ equ 80000000h
FILE_ATTRIBUTE_NORMAL equ 80h
STD_OUTPUT_HANDLE equ -11

BUTTON_STATE_NORMAL equ 0
BUTTON_STATE_PRESSED equ 1

Button STRUCT
    shape dd ?
    state dd ?
Button ENDS

; Drum 結構
Drum STRUCT
    sprite dd 0
    dtype dd 0      ; 1 = 紅色鼓, 2 = 藍色鼓
Drum ENDS

.data
    ; 檔案路徑
    bg_path db "assets/main/game_background.jpg", 0
    red_drum_path db "assets/main/red_note.png", 0
    blue_drum_path db "assets/main/blue_note.png", 0
    selected_music_path db "assets/never-gonna-give-you-up-official-music-video.mp3", 0
    selected_beatmap_path db "assets/music/song1_beatmap.tja", 0

    ;常數
    MAX_DRUMS equ 100 
    Drum_struct_size equ 8     ; Drum 結構大小
    MAX_NOTES equ 10000
    MAX_LINE_LENGTH equ 1000
    SCREEN_WIDTH equ 1280
    SCREEN_HEIGHT equ 720
    DRUM_SPEED equ 0.5
    track_height REAL4 100.0
    track_width REAL4 1280.0
    track_x REAL4 640.0
    track_y REAL4 200.0

    ; CSFML 物件
    bgTexture dd 0
    bgSprite dd 0
    redDrumTexture dd 0
    blueDrumTexture dd 0
    drumQueue dd MAX_DRUMS * Drum_struct_size DUP(0)
    bgmusic dd 0
    trackBounds sfFloatRect <>
    track_shape Button <>
    current_drum Drum <>

    ;Queue 相關
    front dd 0
    rear dd 0
    qsize dd 0

    ; 時間相關
    clock dd 0
    note_timer REAL4 0.0       ; 音符生成計時器
    ;note_interval REAL4 1.0    ; 每 1 秒生成一個音符

    ;譜面相關
    bpm dd 113.65 ; 預設 BPM
    noteSpawnInterval dd 0.0  ; 音符生成間隔 (毫秒)
    notes dd MAX_NOTES DUP(0) ; 儲存音符數據
    totalNotes dd 0

    ; 視窗設定
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0
    ;scrollSpeed REAL4 -0.5      ; 音符滾動速度 (向左移動)

    ; 顏色常數
    whiteColor sfColor <255, 255, 255, 255> ; 白色
    blackColor sfColor <0, 0, 0, 255>       ; 黑色

    initialPosition sfVector2f <SCREEN_WIDTH, 200.0>  ; 音符的 X 和 Y 座標
    ;movePosition sfVector2f <-0.1, 0.0>

    ;讀檔相關
    stdout_handle dd 0

    filename db "song1_beatmap.tja", 0
    hFile dd 0
    bytesRead dd 0
    readBuffer db 1024 dup(0)

    msgReadFail db "Read file failed.", 13, 10, 0

    msgReadSuccess db "File content:", 13, 10, 0


.code

;播放音樂
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

; 讀取文件內容
readFile PROC
    mov esi, esp

    push 0
    push offset bytesRead
    push 1024
    push offset readBuffer
    push [hFile]
    call ReadFile@20
    add esp, 20

    mov esp, esi
    ret
readFile ENDP

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

create_track PROC
     ; 初始化軌道
    push ecx
    movss xmm0, dword ptr [track_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [track_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [track_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [track_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [track_shape], eax
    mov dword ptr [track_shape.state], BUTTON_STATE_NORMAL

    ; 修改底部長方形顏色和邊框
    push blackColor  ; 黑色
    push dword ptr [track_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    push whiteColor  ; 白色邊框
    push dword ptr [track_shape]
    call sfRectangleShape_setOutlineColor
    add esp, 8
    ret   
create_track ENDP

; 載入紅鼓紋理
@load_red_texture PROC
    push 0
    push offset red_drum_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov redDrumTexture, eax

    ret
@fail_load:
    mov eax, 0
    ret
@load_red_texture ENDP

; 載入藍鼓紋理
@load_blue_texture PROC
    push 0
    push offset blue_drum_path
    call sfTexture_createFromFile
    add esp, 8
    test eax, eax
    jz @fail_load
    mov blueDrumTexture, eax

    ret
@fail_load:
    mov eax, 0
    ret
@load_blue_texture ENDP

isQueueFull PROC
    mov eax, qsize
    cmp eax, MAX_DRUMS
    je queue_full
    mov eax, 0

queue_full:
    mov eax, 1

    ret
isQueueFull ENDP

isQueueEmpty PROC
    mov eax, qsize
    cmp eax, 0
    je queue_empty
    mov eax, 0

queue_empty:
    mov eax, 1

    ret
isQueueEmpty ENDP

enqueue PROC
    call isQueueFull
    cmp eax, 1
    je end_enqueue
    
    mov eax, [current_drum.sprite]      ; sprite
    mov ebx, [current_drum.dtype]       ; dtype
    lea edi, drumQueue

    ; 計算擺放位置
    mov eax, [rear]        
    mov edx, Drum_struct_size
    mul edx                  
    add edi, eax 

    ; 儲存drum資料
    mov [edi], eax           ; sprite
    mov [edi + 4], ebx       ; dtype

    ; 更新rear、size
    inc dword ptr [rear]
    mov eax, [rear]
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov dword ptr [rear], edx
    inc dword ptr [qsize]

end_enqueue:
    ret
enqueue ENDP

dequeue PROC
    call isQueueEmpty
    cmp eax, 1
    je end_dequeue

    ; 計算移除位置
    lea edi, drumQueue
    mov eax, [front]
    mov edx, Drum_struct_size
    mul edx
    add edi, eax

    ; 讀取 drum
    mov eax, [edi]           ;sprite
    mov ebx, [edi + 4]       ;dtype

    ;釋放資源
    push eax
    call sfSprite_destroy
    add esp, 4

    ; 更新front、size
    inc dword ptr [front]
    mov eax, [front]
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov dword ptr [front], edx
    dec dword ptr [qsize]

end_dequeue:
    ret
dequeue ENDP

spawnDrum PROC             ;call前type要先push到eax
    call isQueueFull
    cmp eax, 1
    je end_spawn

    mov dword ptr [current_drum.dtype], eax
    call sfSprite_create
    mov DWORD PTR [current_drum.sprite], eax

    cmp dword ptr [current_drum.dtype], 1
    je spawnRed
    call @load_blue_texture

spawnRed:
    call @load_red_texture

    ;設定位置
    push dword ptr [initialPosition+4] ; Y 座標
    push dword ptr [initialPosition]   ; X 座標
    push eax
    call sfSprite_setPosition
    add esp, 12

    call enqueue

end_spawn:
    ret
spawnDrum ENDP

updateDrums PROC
    cmp qsize, 0
    jbe end_update
    
    lea edi, drumQueue
    mov eax, [front]
    mov edx, Drum_struct_size
    mul edx
    add edi, eax

    ; 讀取 drum
    mov eax, [edi]           ;sprite
    mov ebx, [edi + 4]       ;dtype

end_update:
    ret
updateDrums ENDP

; 生成新的音符
;@generate_note PROC
    ; 如果音符超過最大數量，則跳過
    ;mov eax, noteCount
    ;cmp eax, 256   ; 生成最多 256 個音符
    ;jae @end

    ; 創建新的音符精靈
    ;call sfSprite_create
    ;test eax, eax
    ;jz @end

    ; 將新的音符精靈儲存到陣列中
    ;mov esi, noteCount           ; 使用 noteCount 來確保索引有效
    ;mov DWORD PTR [noteSprites + esi*4], eax

    ; 設定紅色音符紋理
    ;push 1
    ;mov eax, redDrumTexture
    ;push eax
    ;mov ecx, DWORD PTR [noteSprites + esi*4]
    ;push ecx
    ;call sfSprite_setTexture
    ;add esp, 12

    ; 設定音符初始位置
    ;push dword ptr [notePosition+4] ; Y 座標
    ;push dword ptr [notePosition]   ; X 座標
    ;mov eax, DWORD PTR [noteSprites + esi*4]
    ;push eax
    ;call sfSprite_setPosition
    ;add esp, 12

    ; 更新音符數量
    ;inc noteCount
;@end:
    ;ret
;@generate_note ENDP

; 更新音符位置
;@update_notes PROC
    ;xor esi, esi

;@loop_notes:
    ;cmp esi, noteCount
    ;jge @end

    ; 檢查音符是否有效
    ;mov eax, DWORD PTR [noteSprites + esi*4]
    ;test eax, eax
    ;jz @next_note

    ; 移動音符
    ;push dword ptr [movePosition+4] ; Y 方向不變
    ;push scrollSpeed                ; X 方向移動
    ;push eax
    ;call sfSprite_move
    ;add esp, 12

;@next_note:
    ;inc esi
    ;jmp @loop_notes
;@end:
    ;ret
;@update_notes ENDP

; 清理音符
;@cleanup_notes PROC
    ;xor esi, esi

;@loop_cleanup:
    ;cmp esi, noteCount
    ;jge @end

    ; 檢查音符是否有效
    ;mov eax, DWORD PTR [noteSprites + esi*4]
    ;test eax, eax
    ;jz @next_cleanup

    ; 銷毀音符精靈
    ;push eax
    ;call sfSprite_destroy
    ;add esp, 4

;@next_cleanup:
    ;inc esi
    ;jmp @loop_cleanup
;@end:
    ;ret
;@cleanup_notes ENDP

main_game_page PROC window:DWORD

    ; 載入背景
    call @load_bg
    test eax, eax
    jz @exit_program

    ; 載入鼓面紋理
    ;call @load_drums
    ;test eax, eax
    ;jz @exit_program

    ;載入音樂
    call game_play_music
    test eax, eax
    jz @exit_program

    ; 載入tja檔
    ;push offset selected_beatmap_path
    ;call parseNoteChart
    ;test eax, eax
    ;jz @exit_program

    ; 初始化計時器
    ;call sfClock_create
    ;test eax, eax
    ;jz @exit_program
    ;mov clock, eax

@main_loop:

    ; 檢查音樂是否停止
    push bgMusic
    call sfMusic_getStatus
    add esp, 4
    cmp eax, 0
    je to_end_page

    ; 檢查視窗是否開啟
    mov eax, window
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exit_program

    ; 更新計時器
    ;mov eax, clock
    ;push eax
    ;call sfClock_getElapsedTime
    ;add esp, 4
    ;test eax, eax
    ;jz @exit_program               ; 如果時間返回無效，退出程式

    ; 提取微秒並轉換為秒數
    ;mov ebx, 1000000  ; 1,000,000 用於將微秒轉換為秒
    ;xor edx, edx      ; 清除 edx，準備進行除法操作
    ;div ebx           ; eax = microseconds / 1,000,000 (秒數)
    ;cvtsi2ss xmm0, eax

    ; 判斷是否生成新的音符
    ;movss xmm1, note_interval
    ;comiss xmm0, xmm1
    ;jb @skip_generate_note  ; 若音符生成間隔未達一秒，跳過

    ; 生成音符並重置計時器
    ;call @generate_note
    ;call sfClock_restart           ; 重置時鐘

;@skip_generate_note:
    ; 更新音符
    ;call @update_notes

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

    ;繪製軌道
    ;push 0
    ;mov eax, DWORD PTR [track_shape]
    ;push eax
    ;mov ecx, DWORD PTR [window]
    ;push ecx
    ;call sfRenderWindow_drawRectangleShape
    ;add esp, 12

    ; 繪製音符
    xor esi, esi
;@draw_notes_loop:
    ;cmp esi, noteCount
    ;jge @end_draw_notes

    ;mov eax, DWORD PTR [noteSprites + esi*4]
    ;test eax, eax
    ;jz @next_draw

    ;push 0
    ;push eax
    ;mov ecx, window
    ;push ecx
    ;call sfRenderWindow_drawSprite
    ;add esp, 12

;@next_draw:
    ;inc esi
    ;jmp @draw_notes_loop
;@end_draw_notes:

    ; 顯示視窗
    mov eax, window
    push eax
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

; 跳轉結算畫面
to_end_page:
    mov DWORD PTR [currentPage], 2
    jmp @exit_program

@exit_program:
    ;call @cleanup_notes

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push redDrumTexture
    call sfTexture_destroy
    add esp, 4

    push blueDrumTexture
    call sfTexture_destroy
    add esp, 4

    push clock
    call sfClock_destroy
    add esp, 4

    ;push dword ptr [track_shape]
    ;call sfRectangleShape_destroy
    ;add esp, 4

    ret
main_game_page ENDP

END main_game_page
