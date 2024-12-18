.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD
extern selected_music_path: DWORD
extern selected_beatmap1_path: DWORD

.data


    ; 選中的音樂和譜面檔案
    selectedMusicPath db 256 DUP(0)    ; 音樂檔案路徑
    selectedBeatmapPath db 256 DUP(0)  ; 譜面檔案路徑

    ; 時間與遊戲狀態
    currentNoteIndex DWORD 0  ; 當前音符索引
    currentSongTime DWORD 0   ; 當前歌曲時間 (毫秒)
    lastJudgment DWORD -1     ; 上一次判定結果

    ; 譜面音符時間
    noteTimings DWORD 256 DUP(?) ; 儲存音符時間
    noteCount DWORD 0            ; 總音符數量

    ; CSFML 物件


    ; 視窗設定
    window_videoMode sfVideoMode <1280, 720, 32>
    windowTitle db "Taiko Simulator", 0
    scrollSpeed REAL4 -0.05      ; 音符滾動速度 (向左移動)

    ; 顏色常數
    whiteColor sfColor <255, 255, 255, 255> ; 白色
    blackColor sfColor <0, 0, 0, 255>       ; 黑色


    call sfMusic_createFromFile
    add esp, 4
    mov bgMusic, eax

    call sfMusic_play
    add esp, 4
    ret
game_play_music ENDP


    test eax, eax



    add esp, 8
    test eax, eax







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

    ret
@cleanup_notes ENDP

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


    add esp, 4
    test eax, eax
    jz @exit_program               ; 如果時間返回無效，退出程式

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

    add esp, 4

    call sfSprite_destroy
    add esp, 4

    add esp, 4

    add esp, 4

    add esp, 4

    ret
main_game_page ENDP

END main_game_page