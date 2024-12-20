.model flat, c
include csfml.inc
include windows.inc
;include stdio.h

extern currentPage: DWORD
extern create_button: PROC
EXTERN end_game_page:PROC
;EXTERN fopen: PROC

GENERIC_READ equ 80000000h
FILE_ATTRIBUTE_NORMAL equ 80h
STD_OUTPUT_HANDLE equ -11

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

    beatmapString db "1001201000102010,1001202000002222,1001201000102000,0000000000112212,1001201110102010,1001201110202222,1001201110102010,1020200022112212,1010211010102000,1011211010202000,1011202010100010,3000404000000000,1010211010102000,1011211010202000", 0

    ;常數
    MAX_DRUMS equ 100 
    Drum_struct_size equ 8     ; Drum 結構大小
    MAX_NOTES equ 10000
    MAX_LINE_LENGTH equ 1000
    SCREEN_WIDTH equ 1280.0
    SCREEN_HEIGHT equ 720
    DRUM_SPEED dd 0.5
    track_height REAL4 100.0
    track_width REAL4 1280.0
    track_x REAL4 640.0
    track_y REAL4 200.0
    spritePosX    dd 0.0
    spritePosY    dd 0.0
    const_60000 dd 60000.0
    four dd 4.0

    ;用來存great good miss 的次數和最後總分
    great_count DWORD 0
    good_count DWORD 0
    miss_count DWORD 0
    score DWORD 0

    ; CSFML 物件
    bgTexture dd 0
    bgSprite dd 0
    redDrumTexture dd 0
    blueDrumTexture dd 0
    drumQueue dd MAX_DRUMS * Drum_struct_size DUP(0)
    bgmusic dd 0
    trackBounds sfFloatRect <>
    current_drum Drum <>

    ;Queue 相關
    front dd 0
    rear dd 0
    qsize dd 0
    index dd 0

    ; 時間相關
    clock dd 0
    note_timer REAL4 0.0       ; 音符生成計時器

    ;譜面相關
    bpm dd 113.65 ; 預設 BPM
    noteSpawnInterval dd 0.0  ; 音符生成間隔 (毫秒)
    notes dd MAX_NOTES DUP(0) ; 儲存音符數據
    totalNotes dd 0
    currentNoteIndex dd 0

    ; 視窗設定
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0

    ; 顏色常數
    whiteColor sfColor <255, 255, 255, 255> ; 白色
    blackColor sfColor <0, 0, 0, 255>       ; 黑色

    initialPosition sfVector2f <SCREEN_WIDTH, 200.0>  ; 音符的 X 和 Y 座標

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

parseNoteChart PROC
    lea esi, [beatmapString]
    lea edi, [notes]
    xor ecx, ecx 

parse_loop:
    mov al, [esi]
    cmp al, 0 
    je parse_end

    cmp al, '0'
    jb next_char
    cmp al, '2'
    ja next_char

    sub al, '0'
    mov [edi], al
    inc edi 
    inc ecx 
    jmp next_char

next_char:
    inc esi
    jmp parse_loop

parse_end:
    mov [totalNotes], ecx
    movss xmm0, [const_60000]
    movss xmm1, [bpm]
    mulss xmm1, [four]
    divss xmm0, xmm1
    movss [noteSpawnInterval], xmm0
    ret
parseNoteChart ENDP

; 載入紅鼓紋理
@load_red_texture PROC
    push 0
    push offset red_drum_path
    call sfTexture_createFromFile
    add esp, 8
    mov redDrumTexture, eax
    ret
@load_red_texture ENDP

; 載入藍鼓紋理
@load_blue_texture PROC
    push 0
    push offset blue_drum_path
    call sfTexture_createFromFile
    add esp, 8
    mov blueDrumTexture, eax
    ret
@load_blue_texture ENDP

;full會return 1
isQueueFull PROC
    mov eax, qsize
    cmp eax, MAX_DRUMS
    je queue_full
    mov eax, 0

queue_full:
    mov eax, 1
    ret
isQueueFull ENDP

;empty會return 1
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
    mov eax, rear
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
    mov eax, front
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov dword ptr [front], edx
    dec dword ptr [qsize]

end_dequeue:
    ret
dequeue ENDP

spawnDrum PROC             ;call前type要先load到eax
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

    push eax
    call sfSprite_getPosition
    add esp, 8

    movss [spritePosX], xmm0
    add [spritePosX], 50
    cmp [spritePosX], 50
    jae end_update

    call dequeue

    mov ecx, qsize
    mov ebx, front
update_queue:
    ; 讀取 drum
    mov eax, [edi]           ;sprite

    push eax
    call sfSprite_getPosition
    add esp, 8
    
    movss [spritePosX], xmm0
    movss [spritePosY], xmm1
    movss xmm0, [spritePosX]
    movss xmm1, [DRUM_SPEED]
    subss xmm0, xmm1
    movss [spritePosX], xmm0

    push dword ptr [spritePosY] ; Y 座標
    push dword ptr [spritePosX]   ; X 座標
    push eax
    call sfSprite_setPosition
    add esp, 12

    inc ebx
    mov eax, ebx
    xor edx, edx
    mov ecx, MAX_DRUMS
    div ecx
    mov ebx, edx

loop update_queue

end_update:
    ret
updateDrums ENDP

main_game_page PROC window:DWORD

    ; 載入背景
    call @load_bg
    test eax, eax
    jz @exit_program

    ; 載入紅鼓紋理
    call @load_red_texture
    test eax, eax
    jz @exit_program

    ; 載入藍鼓紋理
    call @load_blue_texture
    test eax, eax
    jz @exit_program

    ;載入音樂
    call game_play_music
    test eax, eax
    jz @exit_program

    ;載入鼓面
    call parseNoteChart
    test eax, eax
    jz @exit_program

    ; 載入tja檔
    ;push offset selected_beatmap_path
    ;call parseNoteChart
    ;test eax, eax
    ;jz @exit_program

    ; 初始化計時器
    call sfClock_create
    test eax, eax
    jz @exit_program
    mov clock, eax

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

L1:
    ; 更新計時器
    mov eax, clock
    push eax
    call sfClock_getElapsedTime
    add esp, 4
    test eax, eax
    jz @exit_program 

    ; 提取微秒並轉換為秒數
    mov ebx, 1000 
    xor edx, edx
    div ebx
    cvtsi2ss xmm0, eax
    cmp eax, noteSpawnInterval
    jb update

L2:
    mov eax, [currentNoteIndex]
    cmp eax, totalNotes
    jae restart
    lea edi, notes
    add edi, eax
    inc currentNoteIndex

L3:
    mov eax, [edi]
    cmp eax, 0
    je restart
    call spawnDrum

restart:
    call sfClock_restart

update:
    call updateDrums

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

    mov ecx, [qsize]
    mov edx, [front]
    mov index, edx
;draw_loop:
    ; 繪製鼓
    ;lea edi, drumQueue
    ;mov eax, index
    ;mov edx, Drum_struct_size
    ;mul edx
    ;add edi, eax

    ;mov eax, [edi]           ;sprite

    ;push 0
    ;push DWORD PTR [eax]
    ;push DWORD PTR [window]
    ;call sfRenderWindow_drawSprite
    ;add esp, 12

    ;inc dword ptr [index]
    ;mov eax, index
    ;xor edx, edx
    ;mov ecx, MAX_DRUMS
    ;div ecx
    ;mov dword ptr [index], edx

;loop draw_loop

    ; 顯示視窗
    mov eax, window
    push eax
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

; 跳轉結算畫面
to_end_page:
    ;遊戲結束要切換到結尾畫面
    push score    
    push miss_count    
    push good_count   
    push great_count    
    push window        
    call end_game_page
    add esp, 20
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