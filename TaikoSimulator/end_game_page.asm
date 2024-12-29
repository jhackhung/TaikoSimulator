.686P
.XMM
.model flat, c
include csfml.inc

extern currentPage: DWORD
PUBLIC end_game_page

BUTTON_STATE_NORMAL equ 0

Button STRUCT
    shape dd ?
    state dd ?
Button ENDS

.data
    music_path db "assets/music/Anata ni Koi wo Shite Mimashita.ogg", 0   
    bg_path db "assets/main/end_bg.jpg", 0
    font_path db "assets/fonts/Taiko_No_Tatsujin_Official_Font.ttf", 0

    ; ���ܤ�r
    string1 db "Great", 0          
    string2 db "Good", 0
    string3 db "Miss", 0
    string4 db "  Max", 0Dh, 0Ah,"Combo", 0

    ; CSFML����
    bgTexture dd 0
    bgSprite dd 0
    bgMusic dd 0
    font dd 0
    event sfEvent <>
    window_realWidth dd 044a00000r ; 1280.0

    countGreat dd 0
    countGood dd 0
    countMiss dd 0
    countScore dd 0
    countCombo dd 0

    countGreatText dd 0
    countGreatStr db 20 dup(0)
    buffer db 20 dup(0)
    countGoodText dd 0
    countGoodStr db 20 dup(0)
    buffer_1 db 20 dup(0)
    countMissText dd 0
    countMissStr db 20 dup(0)
    buffer_2 db 20 dup(0)
    countScoreText dd 0
    countScoreStr db 20 dup(0)
    buffer_3 db 20 dup(0)
    countComboText dd 0
    countComboStr db 20 dup(0)
    buffer_4 db 20 dup(0)

    string1Text dd 0
    string2Text dd 0
    string3Text dd 0
    string4Text dd 0
    string1Bounds sfFloatRect <>
    string2Bounds sfFloatRect <>
    string3Bounds sfFloatRect <>
    string4Bounds sfFloatRect <>

    rect_shape Button <>
    score_shape Button <>

    ; �`��
    rect_x REAL4 280.0
    rect_y REAL4 60.0
    rect_height REAL4 300.0
    rect_width REAL4 720.0
    score_x REAL4 515.0
    score_y REAL4 90.0
    score_height REAL4 60.0
    score_width REAL4 250.0

    two dd 2.0
    four dd 4.0    
    text_y dd 180.0
    great_x dd 300.0
    good_x dd 495.0
    miss_x dd 690.0
    combo_x dd 860.0
    combo_y dd 160.0

    countGreat_x dd 320.0 
    countGreat_y dd 250.0 
    countGood_x dd 520.0  
    countMiss_x dd 705.0  
    countCombo_x dd 890.0
    countScore_x dd 587.0  
    countScore_y dd 94.0 

    ; �C��`��
    orange_color sfColor <229, 109, 50, 255>
    white_color sfColor <255, 255, 255, 255>
    red_color sfColor <180, 50, 50, 185>
    black_color sfColor <0, 0, 0, 255>
    trans_white_color sfColor <255, 255, 255, 185>
    gray_color sfColor <80, 80, 80, 255>
    blue_color sfColor <20, 60, 100, 185>
    green_color sfColor <88, 148, 88, 255>

.code

; ���J�I��
load_end_background PROC
    ; �ЫحI�����z
    push 0
    push offset bg_path
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
load_end_background ENDP

; �]�w����
end_play_music PROC
    push offset music_path
    call sfMusic_createFromFile
    add esp, 4 
    mov bgMusic, eax

    push eax
    call sfMusic_play
    add esp, 4
    ret
end_play_music ENDP

; �]�wString1��r
setup_string1_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [string1Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset string1
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push white_color
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setFillColor
    add esp, 8

    ; Set outline color
    push red_color
    mov eax, DWORD PTR [string1Text]
    push eax
    call sfText_setOutlineColor
    add esp, 8
    
    ; Set outline thickness
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0 
    push DWORD PTR [string1Text]
    call sfText_setOutlineThickness
    add esp, 8
    
    ; Set position
    movss xmm0, DWORD PTR [text_y]  
    movss xmm1, DWORD PTR [great_x]     
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0     
    push DWORD PTR [string1Text]      
    call sfText_setPosition
    add esp, 12                   

    ret
setup_string1_text ENDP

; �]�wString2��r
setup_string2_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [string2Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset string2
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push white_color
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setFillColor
    add esp, 8
  
      ; Set outline color
    push orange_color
    mov eax, DWORD PTR [string2Text]
    push eax
    call sfText_setOutlineColor
    add esp, 8
    
    ; Set outline thickness
    movss xmm0, DWORD PTR [four] 
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [string2Text]
    call sfText_setOutlineThickness
    add esp, 8

    ; Set position
    movss xmm0, DWORD PTR [text_y]  
    movss xmm1, DWORD PTR [good_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1           
    movss DWORD PTR [esp+4], xmm0         
    push DWORD PTR [string2Text]          
    call sfText_setPosition
    add esp, 12                         

    ret
setup_string2_text ENDP

; �]�wString3��r
setup_string3_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [string3Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset string3
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push white_color
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setFillColor
    add esp, 8
   
    ; Set outline color
    push blue_color
    mov eax, DWORD PTR [string3Text]
    push eax
    call sfText_setOutlineColor
    add esp, 8
    
    ; Set outline thickness
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [string3Text]
    call sfText_setOutlineThickness
    add esp, 8

    ; Set position
    movss xmm0, DWORD PTR [text_y] 
    movss xmm1, DWORD PTR [miss_x]  
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0        
    push DWORD PTR [string3Text]          
    call sfText_setPosition
    add esp, 12                    

    ret
setup_string3_text ENDP

; �]�wString4��r
setup_string4_text PROC
    ; Create font
    push offset font_path
    call sfFont_createFromFile
    add esp, 4
    mov font, eax
    
    ; Create text object
    call sfText_create
    mov DWORD PTR [string4Text], eax
    
    ; Set font
    push font
    mov eax, DWORD PTR [string4Text]
    push eax
    call sfText_setFont
    add esp, 8
    
    ; Set string
    push offset string4
    mov eax, DWORD PTR [string4Text]
    push eax
    call sfText_setString
    add esp, 8
    
    ; Set character size
    push 32
    mov eax, DWORD PTR [string4Text]
    push eax
    call sfText_setCharacterSize
    add esp, 8
    
    ; Set fill color
    push white_color
    mov eax, DWORD PTR [string4Text]
    push eax
    call sfText_setFillColor
    add esp, 8
   
    ; Set outline color
    push green_color
    mov eax, DWORD PTR [string4Text]
    push eax
    call sfText_setOutlineColor
    add esp, 8
    
    ; Set outline thickness
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [string4Text]
    call sfText_setOutlineThickness
    add esp, 8

    ; Set position
    movss xmm0, DWORD PTR [combo_y] 
    movss xmm1, DWORD PTR [combo_x]  
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0        
    push DWORD PTR [string4Text]          
    call sfText_setPosition
    add esp, 12                    

    ret
setup_string4_text ENDP

; �]�wcountGreat��r
setup_countgreat_text PROC

    call sfText_create
    mov DWORD PTR [countGreatText], eax
   
    push font
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer
    push dword ptr [countGreat]
    call int_to_str
    add esp, 8

    push offset countGreatStr
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
   
    push white_color
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setFillColor
    add esp, 8

    push red_color
    mov eax, DWORD PTR [countGreatText]
    push eax
    call sfText_setOutlineColor
    add esp, 8
   
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [countGreatText]
    call sfText_setOutlineThickness
    add esp, 8

    movss xmm0, DWORD PTR [countGreat_y]  
    movss xmm1, DWORD PTR [countGreat_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countGreatText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countgreat_text ENDP

; �]�wcountGood��r
setup_countgood_text PROC

    call sfText_create
    mov DWORD PTR [countGoodText], eax
   
    push font
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer_1
    push dword ptr [countGood]
    call int_to_str_1
    add esp, 8

    push offset countGoodStr
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setCharacterSize
    add esp, 8

    push white_color
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setFillColor
    add esp, 8

    push orange_color
    mov eax, DWORD PTR [countGoodText]
    push eax
    call sfText_setOutlineColor
    add esp, 8
   
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [countGoodText]
    call sfText_setOutlineThickness
    add esp, 8

    movss xmm0, DWORD PTR [countGreat_y]  
    movss xmm1, DWORD PTR [countGood_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countGoodText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countgood_text ENDP

; �]�wcountMiss��r
setup_countmiss_text PROC

    call sfText_create
    mov DWORD PTR [countMissText], eax
   
    push font
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer_2
    push dword ptr [countMiss]
    call int_to_str_2
    add esp, 8

    push offset countMissStr
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
   
    push white_color
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setFillColor
    add esp, 8

    push blue_color
    mov eax, DWORD PTR [countMissText]
    push eax
    call sfText_setOutlineColor
    add esp, 8
   
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [countMissText]
    call sfText_setOutlineThickness
    add esp, 8

    movss xmm0, DWORD PTR [countGreat_y]  
    movss xmm1, DWORD PTR [countMiss_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countMissText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countmiss_text ENDP

; �]�wcountCombo��r
setup_countcombo_text PROC

    call sfText_create
    mov DWORD PTR [countComboText], eax
   
    push font
    mov eax, DWORD PTR [countComboText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer_4
    push dword ptr [countCombo]
    call int_to_str_4
    add esp, 8

    push offset countComboStr
    mov eax, DWORD PTR [countComboText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countComboText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
   
    push white_color
    mov eax, DWORD PTR [countComboText]
    push eax
    call sfText_setFillColor
    add esp, 8

    push green_color
    mov eax, DWORD PTR [countComboText]
    push eax
    call sfText_setOutlineColor
    add esp, 8
   
    movss xmm0, DWORD PTR [four]  
    sub esp, 4
    movss DWORD PTR [esp], xmm0  
    push DWORD PTR [countComboText]
    call sfText_setOutlineThickness
    add esp, 8

    movss xmm0, DWORD PTR [countGreat_y]  
    movss xmm1, DWORD PTR [countCombo_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countComboText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countcombo_text ENDP

; �]�wcountScore��r
setup_countscore_text PROC

    call sfText_create
    mov DWORD PTR [countScoreText], eax
   
    push font
    mov eax, DWORD PTR [countScoreText]
    push eax
    call sfText_setFont
    add esp, 8
   
    push offset buffer_3
    push dword ptr [countScore]
    call int_to_str_3
    add esp, 8

    push offset countScoreStr
    mov eax, DWORD PTR [countScoreText]
    push eax
    call sfText_setString
    add esp, 8
   
    push 40
    mov eax, DWORD PTR [countScoreText]
    push eax
    call sfText_setCharacterSize
    add esp, 8
   
    push white_color
    mov eax, DWORD PTR [countScoreText]
    push eax
    call sfText_setFillColor
    add esp, 8

    movss xmm0, DWORD PTR [countScore_y]  
    movss xmm1, DWORD PTR [countScore_x]    
    sub esp, 8
    movss DWORD PTR [esp], xmm1          
    movss DWORD PTR [esp+4], xmm0    
    push DWORD PTR [countScoreText]      
    call sfText_setPosition
    add esp, 12                  

    ret
setup_countscore_text ENDP

strcpy PROC
    push ebp
    mov ebp, esp
    
    ; ���o�ӷ��M�ؼЦ�}
    mov esi, [ebp+8]   ; �ӷ��r��
    mov edi, [ebp+12]  ; �ؼЦr��

@copy_loop:
    mov al, [esi]     ; ���J�ӷ��r��
    mov [edi], al     ; �ƻs��ؼ�
    
    test al, al       ; �ˬd�O�_���r�굲���]0�^
    jz @done          ; �p�G�O�A�����ƻs
    
    inc esi           ; ���ʨӷ�����
    inc edi           ; ���ʥؼЫ���
    jmp @copy_loop

@done:
    pop ebp
    ret
strcpy ENDP

; �����r�ꪺ�{��
int_to_str PROC
    push ebp
    mov ebp, esp

    ; �ѼơGnumber(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; ���o�Ʀr
    mov esi, [ebp+12]  ; ���o�w�İϦ�}
    mov ecx, 10        ; ����
    mov edi, 0         ; ��ƭp�ƾ�

    ; �S���p�G�Ʀr�� 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; �M�� edx �ǳư��k
    div ecx           ; ���H 10
    add edx, '0'      ; �ഫ�l�Ƭ��r��
    push edx          ; �Ȧs�r��
    inc edi           ; �W�[���
    test eax, eax     ; �O�_�٦��Ʀr
    jnz @convert_loop

@reverse_loop:
    pop edx           ; ���X�r��
    mov [esi], dl     ; �s�J�w�İ�
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; �[�J������

@done:
    ; ���ʦr��� countGreatStr
    push offset countGreatStr
    push offset buffer
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str ENDP

; �����r�ꪺ�{��
int_to_str_1 PROC
    push ebp
    mov ebp, esp

    ; �ѼơGnumber(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; ���o�Ʀr
    mov esi, [ebp+12]  ; ���o�w�İϦ�}
    mov ecx, 10        ; ����
    mov edi, 0         ; ��ƭp�ƾ�

    ; �S���p�G�Ʀr�� 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; �M�� edx �ǳư��k
    div ecx           ; ���H 10
    add edx, '0'      ; �ഫ�l�Ƭ��r��
    push edx          ; �Ȧs�r��
    inc edi           ; �W�[���
    test eax, eax     ; �O�_�٦��Ʀr
    jnz @convert_loop

@reverse_loop:
    pop edx           ; ���X�r��
    mov [esi], dl     ; �s�J�w�İ�
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; �[�J������

@done:
    ; ���ʦr��� countGoodStr
    push offset countGoodStr
    push offset buffer_1
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str_1 ENDP

; �����r�ꪺ�{��
int_to_str_2 PROC
    push ebp
    mov ebp, esp

    ; �ѼơGnumber(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; ���o�Ʀr
    mov esi, [ebp+12]  ; ���o�w�İϦ�}
    mov ecx, 10        ; ����
    mov edi, 0         ; ��ƭp�ƾ�

    ; �S���p�G�Ʀr�� 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; �M�� edx �ǳư��k
    div ecx           ; ���H 10
    add edx, '0'      ; �ഫ�l�Ƭ��r��
    push edx          ; �Ȧs�r��
    inc edi           ; �W�[���
    test eax, eax     ; �O�_�٦��Ʀr
    jnz @convert_loop

@reverse_loop:
    pop edx           ; ���X�r��
    mov [esi], dl     ; �s�J�w�İ�
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; �[�J������

@done:
    push offset countMissStr
    push offset buffer_2
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str_2 ENDP

; �����r�ꪺ�{��
int_to_str_3 PROC
    push ebp
    mov ebp, esp

    ; �ѼơGnumber(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; ���o�Ʀr
    mov esi, [ebp+12]  ; ���o�w�İϦ�}
    mov ecx, 10        ; ����
    mov edi, 0         ; ��ƭp�ƾ�

    ; �S���p�G�Ʀr�� 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; �M�� edx �ǳư��k
    div ecx           ; ���H 10
    add edx, '0'      ; �ഫ�l�Ƭ��r��
    push edx          ; �Ȧs�r��
    inc edi           ; �W�[���
    test eax, eax     ; �O�_�٦��Ʀr
    jnz @convert_loop

@reverse_loop:
    pop edx           ; ���X�r��
    mov [esi], dl     ; �s�J�w�İ�
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; �[�J������

@done:
    push offset countScoreStr
    push offset buffer_3
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str_3 ENDP

; �����r�ꪺ�{��
int_to_str_4 PROC
    push ebp
    mov ebp, esp

    ; �ѼơGnumber(esp+8), buffer(esp+12)
    mov eax, [ebp+8]   ; ���o�Ʀr
    mov esi, [ebp+12]  ; ���o�w�İϦ�}
    mov ecx, 10        ; ����
    mov edi, 0         ; ��ƭp�ƾ�

    ; �S���p�G�Ʀr�� 0
    test eax, eax
    jnz @convert_loop
    mov byte ptr [esi], '0'
    mov byte ptr [esi+1], 0
    jmp @done

@convert_loop:
    xor edx, edx      ; �M�� edx �ǳư��k
    div ecx           ; ���H 10
    add edx, '0'      ; �ഫ�l�Ƭ��r��
    push edx          ; �Ȧs�r��
    inc edi           ; �W�[���
    test eax, eax     ; �O�_�٦��Ʀr
    jnz @convert_loop

@reverse_loop:
    pop edx           ; ���X�r��
    mov [esi], dl     ; �s�J�w�İ�
    inc esi
    dec edi
    jnz @reverse_loop

    mov byte ptr [esi], 0  ; �[�J������

@done:
    push offset countComboStr
    push offset buffer_4
    call strcpy
    add esp, 8

    pop ebp
    ret
int_to_str_4 ENDP

; �Ы�rect
create_rect PROC
    
    push ebp
    mov ebp, esp

    call sfRectangleShape_create
    mov esi, eax  

    push dword ptr [ebp+12] 
    push dword ptr [ebp+8]  
    push esi
    call sfRectangleShape_setPosition
    add esp, 12

    ; �]�w�j�p
    push dword ptr [ebp+20] 
    push dword ptr [ebp+16] 
    push esi
    call sfRectangleShape_setSize
    add esp, 12

    ; �]�w��R�C��
    push trans_white_color
    push esi
    call sfRectangleShape_setFillColor
    add esp, 8

    ; ��^���s����
    mov eax, esi

    pop ebp
    ret
create_rect ENDP

init_rect PROC
    ; ��l��rect
    push ecx
    movss xmm0, dword ptr [rect_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [rect_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [rect_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [rect_x]
    movss dword ptr [esp], xmm0

    call create_rect
    add esp, 16
    mov dword ptr [rect_shape], eax
    mov dword ptr [rect_shape.state], BUTTON_STATE_NORMAL

    ; ��l��score
    push ecx
    movss xmm0, dword ptr [score_height]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [score_width]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [score_y]
    movss dword ptr [esp], xmm0

    push ecx
    movss xmm0, dword ptr [score_x]
    movss dword ptr [esp], xmm0

    call create_rect
    add esp, 16
    mov dword ptr [score_shape], eax
    mov dword ptr [score_shape.state], BUTTON_STATE_NORMAL

    push gray_color 
    push dword ptr [score_shape]
    call sfRectangleShape_setFillColor
    add esp, 8

    ret
init_rect ENDP

; ����귽
end_cleanup PROC

    push bgMusic
    call sfMusic_destroy
    add esp, 4

    push bgSprite
    call sfSprite_destroy
    add esp, 4

    push bgTexture
    call sfTexture_destroy
    add esp, 4

    push string1Text
    call sfText_destroy
    add esp, 4

    push string2Text
    call sfText_destroy
    add esp, 4

    push string3Text
    call sfText_destroy
    add esp, 4

    push string4Text
    call sfText_destroy
    add esp, 4

    push font
    call sfFont_destroy
    add esp, 4
    
    push dword ptr [rect_shape]
    call sfRectangleShape_destroy
    add esp, 4

    push dword ptr [score_shape]
    call sfRectangleShape_destroy
    add esp, 4

    push countGreatText
    call sfText_destroy
    add esp, 4

    push countGoodText
    call sfText_destroy
    add esp, 4

    push countMissText
    call sfText_destroy
    add esp, 4    

    push countScoreText
    call sfText_destroy
    add esp, 4 

    push countComboText
    call sfText_destroy
    add esp, 4 
    ret
end_cleanup ENDP

end_game_page PROC window:DWORD, great_count:DWORD, good_count:DWORD, miss_count:DWORD, score:DWORD, combo_count:DWORD

    mov eax, great_count
    mov countGreat, eax
    mov eax, good_count
    mov countGood, eax
    mov eax, miss_count
    mov countMiss, eax
    mov eax, score
    mov countScore, eax
    mov eax, combo_count
    mov countCombo, eax

    ; ���J�I��
    call end_play_music
    call load_end_background
    test eax, eax
    jz @exitLoop

    mov bgMusic, 0

    ; �]�w���s
    call init_rect

    ; �]�w���ܤ�r
    call setup_string1_text
    call setup_string2_text
    call setup_string3_text
    call setup_string4_text
    call setup_countgreat_text
    call setup_countgood_text
    call setup_countmiss_text
    call setup_countscore_text
    call setup_countcombo_text

@main_loop:
    
    mov eax, DWORD PTR [window]
    push eax
    call sfRenderWindow_isOpen
    add esp, 4
    test eax, eax
    je @exitLoop

    @event_loop:

        ; �ƥ�B�z
        lea esi, event
        push esi
        push window
        call sfRenderWindow_pollEvent
        add esp, 8
        test eax, eax
        je @render_window
    
        ; �ˬd�����ƥ�
        cmp dword ptr [esi].sfEvent._type, sfEvtClosed
        je @end

        cmp dword ptr [esi].sfEvent._type, sfEvtKeyPressed
        je @check_key

        jmp @event_loop

        @check_key:
            cmp dword ptr [esi+4], sfKeyEscape
            je @end
    
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

        ; ø�srect
        push 0
        mov eax, DWORD PTR [rect_shape]
        push eax
        mov ecx, DWORD PTR [window]
        push ecx
        call sfRenderWindow_drawRectangleShape
        add esp, 12

        ; ø�sscore
        push 0
        mov eax, DWORD PTR [score_shape]
        push eax
        mov ecx, DWORD PTR [window]
        push ecx
        call sfRenderWindow_drawRectangleShape
        add esp, 12

        ; ø�sstring1
        push 0
        push DWORD PTR [string1Text]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ø�sstring2
        push 0
        push DWORD PTR [string2Text]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ø�sstring3
        push 0
        push DWORD PTR [string3Text]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ø�sstring4
        push 0
        push DWORD PTR [string4Text]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ø�scountgreat
        push 0
        push DWORD PTR [countGreatText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ø�scountgood
        push 0
        push DWORD PTR [countGoodText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ø�scountmiss
        push 0
        push DWORD PTR [countMissText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ø�scountscore
        push 0
        push DWORD PTR [countScoreText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ø�scountcombo
        push 0
        push DWORD PTR [countComboText]
        push DWORD PTR [window]
        call sfRenderWindow_drawText
        add esp, 12

        ; ��ܵ���
        mov eax, DWORD PTR [window]
        push eax
        call sfRenderWindow_display
        add esp, 4

        jmp @main_loop
@end: 
    mov dword ptr [currentPage], -1

@exitLoop:
    call end_cleanup
    xor eax, eax
    ret

end_game_page ENDP

END end_game_page
