.686P
.XMM
.model flat, c
include csfml.inc

.data
    ; �ɮ׸��|
    musicPath db "assets/main/v_title.ogg", 0
    picPath db "assets/main/taiko_main.jpg", 0
    fontPath db "assets/main/Taiko_No_Tatsujin_Official_Font.ttf", 0
    
    ; �����M�C�����D
    window_title db "Taiko Simulator", 0
    ; ���ܤ�r
    prompt_string db "Click or Press Enter to Start", 0
    
    ; SFML����
    window dd 0
    bgTexture dd 0
    bgSprite dd 0
    bgMusic dd 0
    font dd 0
    titleText dd 0
    promptText dd 0
    titleBounds sfFloatRect <>
    textBounds sfFloatRect <>
    
    ; �����]�w
    window_videoMode sfVideoMode <1280, 720, 32>
    window_realWidth dd 1280.0
    ; �ƥ󵲺c
    event sfEvent <>
    
    ; �z���׬���
    opacity dd 240.0
    minOpacity dd 50.0
    maxOpacity dd 240.0
    deltaOpacity dd -0.05
    
    ; �C��`��
    titleColor sfColor <229, 109, 50, 255>
    whiteColor sfColor <255, 255, 255, 255>
    blackColor sfColor <0, 0, 0, 0>
    redOutlineColor sfColor <255, 0, 0, 255>

    ; ��m�`��
    four dd 4.0
    two dd 2.0
    const_200 dd 200.0
.code

create_window PROC
    push 0
    push 6
    push offset window_title
    sub esp, 12
    mov eax, esp
    mov ecx, window_videoMode._width
    mov [eax], ecx
    mov ecx, window_videoMode.height
    mov [eax+4], ecx
    mov ecx, window_videoMode.bpp
    mov [eax+8], ecx
    call sfRenderWindow_create
    add esp, 24
    mov window, eax
    ret
create_window ENDP

; ���J�I��
load_background PROC
    ; �ЫحI�����z
    push 0
    push offset picPath
    call sfTexture_createFromFile
    add esp, 8
    mov bgTexture, eax
    
    ; �ЫحI�����F
    call sfSprite_create
    mov DWORD PTR [bgSprite], eax
    
    ; �]�w���z
    push 1
    mov eax, DWORD PTR [bgTexture]
    push eax
    mov ecx, DWORD PTR [bgSprite]
    push ecx
    call sfSprite_setTexture
    add esp, 12
    ret
load_background ENDP

play_music PROC
    push offset musicPath
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
play_music ENDP

; �]�w���D��r
setup_title_text PROC
    ; Create font
    push offset fontPath
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [titleText], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [titleText]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset window_title
    mov eax, DWORD PTR [titleText]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 56
    mov eax, DWORD PTR [titleText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push titleColor
    mov eax, DWORD PTR [titleText]
    push eax
    call sfText_setFillColor
    add esp, 8
    
    ; Set outline color
    push whiteColor
    mov eax, DWORD PTR [titleText]
    push eax
    call sfText_setOutlineColor
    add esp, 8
    
    ; Set outline thickness
    movss xmm0, DWORD PTR [four]  ; Load 4.0 into xmm0
    sub esp, 4
    movss DWORD PTR [esp], xmm0  ; Store xmm0 to memory

    push DWORD PTR [titleText]

    call sfText_setOutlineThickness
    add esp, 8
    
    ; Set position
    ;sub esp, 16
    ;lea eax, [esp]

    ;push DWORD PTR [titleText]
    ;call sfText_getLocalBounds

    ;mov eax, DWORD PTR [esp]
    ;mov ebx, DWORD PTR [esp+4]
    ;mov ecx, DWORD PTR [esp+8]
    ;mov edx, DWORD PTR [esp+12]

    ;add esp, 16
    
    ; Adjust position
    ;movss xmm0, DWORD PTR [window_realWidth]
    ;subss xmm0, DWORD PTR [titleBounds._width]
    ;movss xmm1, DWORD PTR [two]
    ;divss xmm0, xmm1
    ;movss DWORD PTR [esp-8], xmm0
    
    ;movss xmm0, DWORD PTR [const_200]
    ;movss DWORD PTR [esp-4], xmm0

    ;push DWORD PTR [esp-4] ; y (200.0)
    ;push DWORD PTR [esp-8] ; x (centered)
    ;push DWORD PTR [titleText]
    ;call sfText_setPosition
    ;add esp, 12
    
    push 0
    push 0
    mov eax, DWORD PTR [titleText]
    push eax
    call sfText_setPosition
    add esp, 12

    ret
setup_title_text ENDP


main PROC
    ; �Ыص���
    call create_window
    test eax, eax
    jz exit_program
    
   ; ���J�I��
    call load_background
    test eax, eax
    jz exit_program
    
    ; ���񭵼�
    call play_music
    
    ; �]�w���D��r
    call setup_title_text
    
    ; �]�w���ܤ�r
    ;call setup_prompt_text

main_loop:
    ; �M������
    push blackColor
    push window
    call sfRenderWindow_clear
    add esp, 8
    
    ; ø�s�I��
    push 0
    mov eax, DWORD PTR [bgSprite]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawSprite
    add esp, 12

    ; ø�s���D��r
    push 0
    mov eax, DWORD PTR [titleText]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawText
    add esp, 12
    

    ; ��ܵ���
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_display
    add esp, 4

    ; �ƥ�B�z
    lea esi, event
    push esi
    push window
    call sfRenderWindow_pollEvent
    test eax, eax
    jz main_loop
    
    ; �ˬd�����ƥ�
    cmp dword ptr [esi].sfEvent._type, sfEvtClosed
    je exit_program
    
    ; �ˬd�ƹ��I��
    cmp dword ptr [esi].sfEvent._type, sfEvtMouseButtonPressed
    je start_game
    
    ; �ˬd��L�ƥ�
    cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
    je start_game
    
    jmp main_loop

start_game:
    ; �o�̥i�H�K�[�i�J���ֿ�ܭ������޿�
    jmp main_loop

exit_program:
    ; ����귽
    push window
    call sfRenderWindow_destroy
    add esp, 4

    push bgMusic
    call sfMusic_destroy

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push titleText
    call sfText_destroy
    add esp, 4
main ENDP

END main