.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD
extern selected_music_path: DWORD
extern selected_beatmap1_path: DWORD

.data
    ; �P�w���f (�H�@��p)
    hitWindowGreat DWORD 35   ; "Great" �P�w�d��
    hitWindowGood  DWORD 80   ; "Good" �P�w�d��
    hitWindowMiss  DWORD 120  ; "Miss" �P�w�d��

    ; ���G�έp
    greatCounter DWORD 0      ; "Great" �p��
    goodCounter  DWORD 0      ; "Good" �p��
    missCounter  DWORD 0      ; "Miss" �p��
    comboCounter DWORD 0      ; �ثe�s����
    maxCombo     DWORD 0      ; �̤j�s����
    scoreCounter DWORD 0      ; �`�o��

    ; �襤�����֩M�Э��ɮ�
    selectedMusicPath db 256 DUP(0)    ; �����ɮ׸��|
    selectedBeatmapPath db 256 DUP(0)  ; �Э��ɮ׸��|

    ; �ɶ��P�C�����A
    currentNoteIndex DWORD 0  ; ��e���ů���
    currentSongTime DWORD 0   ; ��e�q���ɶ� (�@��)
    lastJudgment DWORD -1     ; �W�@���P�w���G

    ; �Э����Ůɶ�
    noteTimings DWORD 256 DUP(?) ; �x�s���Ůɶ�
    noteCount DWORD 0            ; �`���żƶq

    ; CSFML ����
    bgTexture dd 0               ; �I�����z
    bgSprite dd 0                ; �I�����F
    circleTexture dd 0           ; ��έ��ů��z
    circleSprite dd 0            ; ��έ��ź��F
    font dd 0                    ; �r��
    scoreText dd 0               ; ���Ƥ�r
    comboText dd 0               ; �s����r
    window dd 0                  ; �C������

    ; �e���]�w
    window_videoMode sfVideoMode <1280, 720, 32> ; �����j�p�P�榡
    windowTitle db "Taiko Simulator", 0          ; �������D
    scrollSpeed REAL4 5.0        ; ���źu�ʳt��
    laneHeight REAL4 600.0       ; ���ŭy�D����

    ; �C��`��
    whiteColor sfColor <255, 255, 255, 255> ; �զ�
    blackColor sfColor <0, 0, 0, 255>       ; �¦�

.code

main_game_page PROC
    ; �Ыص���
    push OFFSET windowTitle
    push 0
    push OFFSET window_videoMode
    call sfRenderWindow_create
    mov window, eax
    test eax, eax
    jz ExitGame

    ; �[���I���P���ź��F
    call load_background
    call setup_notes

    ; ��l�Ƥ��ƻP��r���
    call setup_text

    ; �[���Э��ɮ�
    call load_beatmap

    ; ����襤������
    push OFFSET selectedMusicPath
    call sfMusic_createFromFile
    add esp, 4
    mov bgMusic, eax

    push bgMusic
    call sfMusic_play
    add esp, 4

    ; ��l�ƹC�����A
    mov currentNoteIndex, 0
    mov currentSongTime, 0

GameLoop:
    ; �ˬd�����O�_�}��
    push window
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    jz ExitGame

    ; �����ɶ��y�u (�C���j�黼�W 16 �@��)
    add currentSongTime, 16

    ; �ˬd�O�_�F��C����������
    mov eax, currentNoteIndex
    cmp eax, noteCount
    jge EndGame

    ; �B�z�ƥ�
    lea esi, event
    push esi
    push window
    call sfRenderWindow_pollEvent
    add esp, 8
    test eax, eax
    je RenderWindow

    ; �ˬd����ƥ� (���U�ť���������ŧP�w)
    cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
    je handle_key_input

RenderWindow:
    ; ��s�ô�V�e��
    call render_game_window

    ; �ˬd��e���Ū��P�w
    call check_notes
    jmp GameLoop

handle_key_input:
    cmp dword ptr [esi+4], sfKeySpace
    je check_notes
    jmp GameLoop

check_notes PROC
    ; ���o��e���Ū��ɶ��íp��P��e�q���ɶ����t�Z
    mov esi, OFFSET noteTimings
    mov eax, currentNoteIndex
    mov ebx, DWORD PTR [esi + eax * 4]
    sub ebx, currentSongTime

    ; �P�_�O�_�ŦX "Great" �����f
    cmp ebx, hitWindowGreat
    jle handle_great
    ; �P�_�O�_�ŦX "Good" �����f
    cmp ebx, hitWindowGood
    jle handle_good
    ; �p�G�W�L "Miss" ���f�A�h�����ӭ���
    cmp ebx, hitWindowMiss
    jg skip_note

handle_great:
    ; �W�[ "Great" �p�ƩM���ơA��s�̤j�s��
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
    ; �W�[ "Good" �p�ƩM����
    inc goodCounter
    add scoreCounter, 100
    inc comboCounter
    call update_score_text
    inc currentNoteIndex
    ret

skip_note:
    ; �p�G���Ťw�W�L "Miss" ���f
    cmp ebx, 0
    jg RenderWindow
    inc missCounter
    mov comboCounter, 0
    call update_score_text
    inc currentNoteIndex
    ret

EndGame:
    ; �C����������̲ܳ׵��G
    call display_results
    mov DWORD PTR [currentPage], -1
    ret

ExitGame:
    ; �M�z�귽�ðh�X�C��
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

