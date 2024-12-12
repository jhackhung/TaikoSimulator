.686P
.XMM
.model flat, c
include csfml.inc

EXTERN sfRectangleShape_create: PROC
EXTERN sfRectangleShape_setPosition: PROC
EXTERN sfRectangleShape_setSize: PROC
EXTERN sfRectangleShape_setFillColor: PROC
EXTERN sfRectangleShape_setOutlineThickness: PROC
EXTERN sfRenderWindow_drawRectangleShape: PROC
EXTERN sfRectangleShape_destroy: PROC
EXTERN sfRectangleShape_setOutlineColor: PROC

extern currentPage: DWORD

BUTTON_STATE_NORMAL equ 0
BUTTON_STATE_PRESSED equ 1

Button STRUCT
	shape dd ?
	state dd ?
Button ENDS

.data
    ; �ɮ׸��|
    bg_path db "assets/main/taiko_main.jpg", 0
    font_path db "assets/main/Taiko_No_Tatsujin_Official_Font.ttf", 0
    
    ; �������D
    window_title db "Song Selection", 0
    
    ; ���s��r
    song1_text db "Song 1", 0
    song2_text db "Song 2", 0
    song3_text db "Song 3", 0
    instruction_text db "Introduction", 0
    
    ; SFML����
    bgTexture dd 0
    bgSprite dd 0
    font dd 0
    
    ; ���s����
    button1_shape Button <>
    button2_shape Button <>
    button3_shape Button <>
    
    ; ���s��r����
    text1 dd 0
    text2 dd 0
    text3 dd 0
    
    ; �����ت���
    instruction_box dd 0
    instruction_text_obj dd 0
    
    ; �ƥ󵲺c
    event sfEvent <>
    
    ; �`��
    button_x REAL4 400.0
    button1_y REAL4 150.0
    button2_y REAL4 250.0
    button3_y REAL4 350.0
    button_width REAL4 480.0
    button_height REAL4 60.0
    outline_thickness REAL4 3.0

    ; �C��`��
    gray_color sfColor <169, 169, 169, 255>
    dark_gray_color sfColor <105, 105, 105, 255>
    light_gray_color sfColor <192, 192, 192, 255>
    darker_gray_color sfColor <128, 128, 128, 255>
    beige_color sfColor <255, 239, 198, 255>
    black_color sfColor <0, 0, 0, 255>

.code

; ���J�I��
@load_background PROC
    push 0
    push offset bg_path
    call sfTexture_createFromFile
    add esp, 8
    mov bgTexture, eax
    
    call sfSprite_create
    mov DWORD PTR [bgSprite], eax
    
    push 1
    push dword ptr [bgTexture]
    push dword ptr [bgSprite]
    call sfSprite_setTexture
    add esp, 12
    ret
@load_background ENDP

; �Ыث��s
create_button PROC
    
    push ebp
    mov ebp, esp

    ; �I�s��ƳЫدx��
    call sfRectangleShape_create
    mov esi, eax  ; �x�s�x�Ϊ���

    ; �Ыئ�m�V�q !�{����m�s�bebp+4
    push dword ptr [ebp+12] ; y �y��
    push dword ptr [ebp+8]  ; x �y��
    push esi
    call sfRectangleShape_setPosition
    add esp, 12

    ; �]�w�j�p
    push dword ptr [ebp+20] ; ����
    push dword ptr [ebp+16] ; �e��
    push esi
    call sfRectangleShape_setSize
    add esp, 12

    ; �]�w��R�C��
    push gray_color
    push esi
    call sfRectangleShape_setFillColor
    add esp, 8

    ; �]�w����C��
    push dark_gray_color
    push esi
    call sfRectangleShape_setOutlineColor
    add esp, 8

    ; �]�w��ثp��
    
    sub esp, 4
    movss xmm0, dword ptr [outline_thickness]
    movss dword ptr [esp], xmm0
    push esi
    call sfRectangleShape_setOutlineThickness
    add esp, 8

    ; ��^���s����
    mov eax, esi

    pop ebp
    ret
create_button ENDP

; ��l�ƫ��s
init_buttons PROC
    ; ��l�ƫ��s1
    push ecx
    movss xmm0, dword ptr [button_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button1_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [button1_shape], eax
    mov dword ptr [button1_shape.state], BUTTON_STATE_NORMAL
    ; ��l�ƫ��s2
    push ecx
    movss xmm0, dword ptr [button_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button2_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [button2_shape], eax
    mov dword ptr [button2_shape.state], BUTTON_STATE_NORMAL

    ; ��l�ƫ��s3
    push ecx
    movss xmm0, dword ptr [button_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button3_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [button_x]
    movss dword ptr [esp], xmm0

    call create_button
    add esp, 16
    mov dword ptr [button3_shape], eax
    mov dword ptr [button3_shape.state], BUTTON_STATE_NORMAL

    ret
init_buttons ENDP

; ����귽
cleanup PROC

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4
    
    push dword ptr [button1_shape]
    call sfRectangleShape_destroy
    add esp, 4
    
    push dword ptr [button2_shape]
    call sfRectangleShape_destroy
    add esp, 4
    
    push dword ptr [button3_shape]
    call sfRectangleShape_destroy
    add esp, 4
    
    ret
cleanup ENDP


select_music_page PROC window:DWORD
   ; ���J�I��
    call @load_background
    test eax, eax
    jz @exit_program

    ; ��l�ƫ��s
    call init_buttons

@main_loop:
    
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exit_program

    @event_loop:
        ; �ƥ�B�z
        lea esi, event
        push esi
        mov eax, window
        push eax
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @render_window
    
        ; �ˬd�����ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end
    
        ; �ˬd�ƹ��I��
        cmp dword ptr [esi].sfEvent._type, sfEvtMouseButtonPressed
        je @render_window
    
        ; �ˬd��L�ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @render_window

        jmp @event_loop
    
@render_window: 
    ; �M������
    push black_color
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

    push 0
    mov eax, DWORD PTR [button1_shape]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawRectangleShape
    add esp, 12

    push 0
    mov eax, DWORD PTR [button2_shape]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawRectangleShape
    add esp, 12
    
    push 0
    mov eax, DWORD PTR [button3_shape]
    push eax
    mov ecx, DWORD PTR [window]
    push ecx
    call sfRenderWindow_drawRectangleShape
    add esp, 12

    ; ��ܵ���
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_display
    add esp, 4

    jmp @main_loop

@end:
    mov DWORD PTR [currentPage], -1

@exit_program:
    ;call cleanup
    xor eax, eax
    ret

select_music_page ENDP

END select_music_page