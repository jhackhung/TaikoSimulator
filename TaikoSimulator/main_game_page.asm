.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD
extern selected_music_path: DWORD
extern selected_beatmap1_path: DWORD

.data
    ; 判定窗口 (以毫秒計)
    hitWindowGreat DWORD 35   ; "Great" 判定範圍
    hitWindowGood  DWORD 80   ; "Good" 判定範圍
    hitWindowMiss  DWORD 120  ; "Miss" 判定範圍

    ; 結果統計
    greatCounter DWORD 0      ; "Great" 計數
    goodCounter  DWORD 0      ; "Good" 計數
    missCounter  DWORD 0      ; "Miss" 計數
    comboCounter DWORD 0      ; 目前連擊數
    maxCombo     DWORD 0      ; 最大連擊數
    scoreCounter DWORD 0      ; 總得分

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
    bgTexture dd 0               ; 背景紋理
    bgSprite dd 0                ; 背景精靈
    circleTexture dd 0           ; 圓形音符紋理
    circleSprite dd 0            ; 圓形音符精靈
    font dd 0                    ; 字型
    scoreText dd 0               ; 分數文字
    comboText dd 0               ; 連擊文字
    window dd 0                  ; 遊戲視窗

    ; 畫面設定
    window_videoMode sfVideoMode <1280, 720, 32> ; 視窗大小與格式
    windowTitle db "Taiko Simulator", 0          ; 視窗標題
    scrollSpeed REAL4 5.0        ; 音符滾動速度
    laneHeight REAL4 600.0       ; 音符軌道高度

    ; 顏色常數
    whiteColor sfColor <255, 255, 255, 255> ; 白色
    blackColor sfColor <0, 0, 0, 255>       ; 黑色

.code

main_game_page PROC
    ; 創建視窗
    push OFFSET windowTitle
    push 0
    push OFFSET window_videoMode
    call sfRenderWindow_create
    mov window, eax
    test eax, eax
    jz ExitGame

    ; 加載背景與音符精靈
    call load_background
    call setup_notes

    ; 初始化分數與文字顯示
    call setup_text

    ; 加載譜面檔案
    call load_beatmap

    ; 播放選中的音樂
    push OFFSET selectedMusicPath
    call sfMusic_createFromFile
    add esp, 4
    mov bgMusic, eax

    push bgMusic
    call sfMusic_play
    add esp, 4

    ; 初始化遊戲狀態
    mov currentNoteIndex, 0
    mov currentSongTime, 0

GameLoop:
    ; 檢查視窗是否開啟
    push window
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    jz ExitGame

    ; 模擬時間流逝 (每次迴圈遞增 16 毫秒)
    add currentSongTime, 16

    ; 檢查是否達到遊戲結束條件
    mov eax, currentNoteIndex
    cmp eax, noteCount
    jge EndGame

    ; 處理事件
    lea esi, event
    push esi
    push window
    call sfRenderWindow_pollEvent
    add esp, 8
    test eax, eax
    je RenderWindow

    ; 檢查按鍵事件 (按下空白鍵模擬音符判定)
    cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
    je handle_key_input

RenderWindow:
    ; 更新並渲染畫面
    call render_game_window

    ; 檢查當前音符的判定
    call check_notes
    jmp GameLoop

handle_key_input:
    cmp dword ptr [esi+4], sfKeySpace
    je check_notes
    jmp GameLoop

check_notes PROC
    ; 取得當前音符的時間並計算與當前歌曲時間的差距
    mov esi, OFFSET noteTimings
    mov eax, currentNoteIndex
    mov ebx, DWORD PTR [esi + eax * 4]
    sub ebx, currentSongTime

    ; 判斷是否符合 "Great" 的窗口
    cmp ebx, hitWindowGreat
    jle handle_great
    ; 判斷是否符合 "Good" 的窗口
    cmp ebx, hitWindowGood
    jle handle_good
    ; 如果超過 "Miss" 窗口，則忽略該音符
    cmp ebx, hitWindowMiss
    jg skip_note

handle_great:
    ; 增加 "Great" 計數和分數，更新最大連擊
    inc greatCounter
    add scoreCounter, 300
    inc comboCounter
    cmp comboCounter, maxCombo
    jle skip_max_combo
    mov maxCombo, comboCounter
skip_max_combo:
    call update_score_text
    inc currentNoteIndex
    ret

handle_good:
    ; 增加 "Good" 計數和分數
    inc goodCounter
    add scoreCounter, 100
    inc comboCounter
    call update_score_text
    inc currentNoteIndex
    ret

skip_note:
    ; 如果音符已超過 "Miss" 窗口
    cmp ebx, 0
    jg RenderWindow
    inc missCounter
    mov comboCounter, 0
    call update_score_text
    inc currentNoteIndex
    ret

EndGame:
    ; 遊戲結束時顯示最終結果
    call display_results
    mov DWORD PTR [currentPage], -1
    ret

ExitGame:
    ; 清理資源並退出遊戲
    push bgMusic
    call sfMusic_destroy
    add esp, 4

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push circleSprite
    call sfSprite_destroy
    add esp, 4

    push font
    call sfFont_destroy
    add esp, 4

    push window
    call sfRenderWindow_close
    add esp, 4

    push window
    call sfRenderWindow_destroy
    add esp, 4

    ret
main_game_page ENDP

