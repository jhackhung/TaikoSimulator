.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD

.data
    ; �ɮ׸��|
    musicPath db "C:\Users\User\source\repos\TaikoSimulator\TaikoSimulator\assets\main\v_title.ogg", 0
    picPath db "C:\Users\User\source\repos\TaikoSimulator\TaikoSimulator\assets\main\taiko_main.jpg", 0
    fontPath db "C:\Users\User\source\repos\TaikoSimulator\TaikoSimulator\assets\main\Taiko_No_Tatsujin_Official_Font.ttf", 0
    
    ; �����M�C�����D
    window_title db "Taiko Simulator", 0
    ; ���ܤ�r
    prompt_string db "Click or Press Enter to Start", 0
    
    ; CSFML����
    ;window dd 0
    bgTexture dd 0
    bgSprite dd 0
    bgMusic dd 0
    font dd 0
    titleText dd 0
    promptText dd 0
    titleBounds sfFloatRect <>
    textBounds sfFloatRect <>
    
    ; �����]�w
    ;window_videoMode sfVideoMode <1280, 720, 32>
    window_realWidth dd 044a00000r ; 1280.0
    ; �ƥ󵲺c
    event sfEvent <>
    
    ; �z���׬���
    opacity dd 043700000r ; 240.0
    minOpacity dd 042480000r ; 50.0
    maxOpacity dd 043700000r ; 240.0
    deltaOpacity dd 0bdcccccdr ; -0.1
    textColor sfColor <>
    outlineColor sfColor <>
    
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

main_play_music PROC
    push offset musicPath
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
main_play_music ENDP

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
    sub esp, 16
    lea eax, [esp]

    push DWORD PTR [titleText]
    push eax
    call sfText_getLocalBounds
    add esp, 8

    mov edx, DWORD PTR [eax]
    mov DWORD PTR [titleBounds.left], edx
    mov ecx, DWORD PTR [eax+4]
    mov DWORD PTR [titleBounds.top], ecx
    mov edx, DWORD PTR [eax+8]
    mov DWORD PTR [titleBounds._width], edx
    mov eax, DWORD PTR [eax+12]
    mov DWORD PTR [titleBounds.height], eax

    add esp, 16
    
    ; Adjust position
    movss xmm0, DWORD PTR [window_realWidth]
    subss xmm0, DWORD PTR [titleBounds._width]
    movss xmm1, DWORD PTR [two]
    divss xmm0, xmm1
    movss DWORD PTR [esp-8], xmm0
    
    movss xmm0, DWORD PTR [const_200]
    movss DWORD PTR [esp-4], xmm0

    mov esi, esp

    push DWORD PTR [esi-4] ; y (200.0)
    push DWORD PTR [esi-8] ; x (centered)
    push DWORD PTR [titleText]
    call sfText_setPosition
    add esp, 12

    ret
setup_title_text ENDP

; �]�w���ܤ�r
setup_prompt_text PROC
	; Create text object
	call sfText_create
	mov DWORD PTR [promptText], eax
	
	; Set font
	push font
	mov eax, DWORD PTR [promptText]
	push eax
	call sfText_setFont
	add esp, 8
	
	; Set string
	push offset prompt_string
	mov eax, DWORD PTR [promptText]
	push eax
	call sfText_setString
	add esp, 8
	
	; Set character size
	push 45
	mov eax, DWORD PTR [promptText]
	push eax
	call sfText_setCharacterSize
	add esp, 8
	
	; Set fill color
	push whiteColor
	mov eax, DWORD PTR [promptText]
	push eax
	call sfText_setFillColor
	add esp, 8

    ; Set outline color
    push redOutlineColor
    push DWORD PTR [promptText]
    call sfText_setOutlineColor
    add esp, 8

    ; Set outline thickness
    movss xmm0, DWORD PTR [two]
    sub esp, 4
    movss DWORD PTR [esp], xmm0

    push DWORD PTR [promptText]
    call sfText_setOutlineThickness
    add esp, 8
	
    ; Set position
    sub esp, 16
    lea eax, [esp]

    push DWORD PTR [promptText]
    push eax
    call sfText_getLocalBounds
    add esp, 8

    mov edx, DWORD PTR [eax]
    mov DWORD PTR [textBounds.left], edx
    mov ecx, DWORD PTR [eax+4]
    mov DWORD PTR [textBounds.top], ecx
    mov edx, DWORD PTR [eax+8]
    mov DWORD PTR [textBounds._width], edx
    mov eax, DWORD PTR [eax+12]
    mov DWORD PTR [textBounds.height], eax

    add esp, 16

	; Adjust position
	movss xmm0, DWORD PTR [window_realWidth]
	subss xmm0, DWORD PTR [textBounds._width]
	movss xmm1, DWORD PTR [two]
	divss xmm0, xmm1
	movss DWORD PTR [esp-8], xmm0
	
	movss xmm0, DWORD PTR [const_200]
    mulss xmm0, DWORD PTR [two]
	movss DWORD PTR [esp-4], xmm0

	mov esi, esp

	push DWORD PTR [esi-4] ; y (400.0)
	push DWORD PTR [esi-8] ; x (centered)
	push DWORD PTR [promptText]
	call sfText_setPosition
	add esp, 12

	ret
setup_prompt_text ENDP

update_text_opacity PROC
    ; ���J��e�z����
    fld dword ptr [opacity]
    fadd dword ptr [deltaOpacity]
    fstp dword ptr [opacity]
    
    ; �ˬd�z�������
    fld dword ptr [minOpacity]
    fld dword ptr [opacity]
    fcomip st(0), st(1)
    fstp st(0)
    jb reverse_opacity
    
    fld dword ptr [maxOpacity]
    fld dword ptr [opacity]
    fcomip st(0), st(1)
    fstp st(0)
    ja reverse_opacity

continue_opacity:
    ; ��s��R�C��z����
    cvttss2si eax, DWORD PTR [opacity] ; Floating-Point Value to Integer
    movzx ecx, al
    push ecx
    push 255
    push 255
    push 255
    call sfColor_fromRGBA
    add esp, 16
    mov DWORD PTR [textColor], eax

    ; ��s�����C��z����
    cvttss2si eax, DWORD PTR [opacity] ; Floating-Point Value to Integer
    movzx ecx, al
    push ecx
    push 0
    push 0
    push 255
    call sfColor_fromRGBA
    add esp, 16
    mov DWORD PTR [outlineColor], eax
    
    ; �]�w�z���C��
    push textColor
    push DWORD PTR [promptText]
    call sfText_setFillColor
    add esp, 8
    
    push outlineColor
    push DWORD PTR [promptText]
    call sfText_setOutlineColor
    add esp, 8
    
    ret

reverse_opacity:
    ; ����z�����ܤƤ�V
    fld dword ptr [deltaOpacity]
    fchs
    fstp dword ptr [deltaOpacity]
    jmp continue_opacity
update_text_opacity ENDP

main_page_proc PROC window:DWORD
    
   ; ���J�I��
    call load_background
    test eax, eax
    jz exit_program
    
    ; ���񭵼�
    call main_play_music
    
    ; �]�w���D��r
    call setup_title_text
    
    ; �]�w���ܤ�r
    call setup_prompt_text

main_loop:
    
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je exit_program

    event_loop:
        ; �ƥ�B�z
        lea esi, event
        push esi
        mov eax, DWORD PTR [window]
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je render_window
    
        ; �ˬd�����ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end
    
        ; �ˬd�ƹ��I��
        cmp dword ptr [esi].sfEvent._type, sfEvtMouseButtonPressed
        je start_game
    
        ; �ˬd��L�ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je enterPressed

        jmp event_loop

        enterPressed:
            cmp dword ptr [esi+4], sfKeyEnter ; �O���餤�AsfEvtKeyPressed����L����N�X(58)�b����4����m
            je start_game
            jmp event_loop
    
    render_window:
        ; ��s�z����
        call update_text_opacity
        push 0
        mov eax, DWORD PTR [promptText]
        push eax
        mov ecx, DWORD PTR [window]
        push ecx
        call sfRenderWindow_drawText
        add esp, 12

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

        ; ø�s���ܤ�r
        push 0
        push DWORD PTR [promptText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ��ܵ���
        mov eax, DWORD PTR [window]
        push eax
        call sfRenderWindow_display
        add esp, 4

        jmp main_loop

start_game:
    ; �o�̥i�H�K�[�i�J���ֿ�ܭ������޿�
    mov DWORD PTR [currentPage], 1
    jmp exit_program

@end:
    mov DWORD PTR [currentPage], -1

exit_program:
    ; ����귽
    push bgMusic
    call sfMusic_destroy
    add esp, 4

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push titleText
    call sfText_destroy
    add esp, 4

    push promptText
    call sfText_destroy
    add esp, 4

    push font
    call sfFont_destroy
    add esp, 4

    ret
main_page_proc ENDP

END main_page_proc