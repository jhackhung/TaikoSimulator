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
    musicPath db "never-gonna-give-you-up-official-music-video.mp3", 0   ; �����ɮ׸��|
    window_t byte "SFML Window", 0
    ; �קﵲ�c���l�ơA���T���w�C�Ӧ���
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

    ; �ˬd�O�_���\�Ыص���
    test eax, eax
    jz exitLoop                    ; �Y��^�Ȭ� 0�A�h�����Ыإ��ѡA�h�X

    mov ebx, eax                   ; �O�s��������

    ; �[������
    push OFFSET musicPath
    call sfMusic_createFromFile
    mov edi, eax  ; �O�s���֫���

    ; ���񭵼�
    push edi
    call sfMusic_play

    ; �D�j��
mainLoop:
    ; �M�ŵ���
    mov ebx, window
    push ebx
    call sfRenderWindow_clear
    pop ebx

    push ebx
    ; ��ܵ������e
    call sfRenderWindow_display
    pop ebx

    ; �ˬd�����O�_�Q����
    call sfRenderWindow_pollEvent
    cmp eax, 0   ; ���]0��ܨS���ƥ�
    je mainLoop  ; �p�G�S���ƥ�A�~��j��

    ; �p�G���ƥ�A�ˬd�O�_�������ƥ�
    cmp eax, 1   ; ���]1�O�����ƥ�
    ; je exitLoop

    ; ���s�i�J�D�j��
    jmp mainLoop

exitLoop:
    ; �M�z�귽
    push edi
    call sfMusic_destroy

    push ebx
    call sfRenderWindow_destroy

    ret
main ENDP
END main
