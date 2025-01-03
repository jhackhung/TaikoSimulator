; CSFML.INC - SFML Definitions for x86 Assembly
; 使用 MASM 語法

includelib csfml-audio.lib
includelib csfml-graphics.lib
includelib csfml-system.lib
includelib csfml-window.lib

; sfBool 定義
sfFalse     equ 0
sfTrue      equ 1

; sfMusic status
sfStopped   equ 0
sfPaused    equ 1
sfPlaying   equ 2


; sfEventType 定義
sfEvtClosed               equ 0
sfEvtResized              equ 1
sfEvtLostFocus            equ 2
sfEvtGainedFocus          equ 3
sfEvtTextEntered          equ 4
sfEvtKeyPressed           equ 5
sfEvtKeyReleased          equ 6
sfEvtMouseWheelMoved      equ 7
sfEvtMouseWheelScrolled   equ 8
sfEvtMouseButtonPressed   equ 9
sfEvtMouseButtonReleased  equ 10
sfEvtMouseMoved           equ 11
sfEvtMouseEntered         equ 12
sfEvtMouseLeft            equ 13

; sfMouseButton 定義
sfMouseLeft   equ 0
sfMouseRight  equ 1
sfMouseMiddle equ 2

; sfKey 定義
sfKeyEnter    equ 58
sfKeyA        equ 0
sfKeyS        equ 18
sfKeyD        equ 3
sfKeyEscape   equ 36
sfKeyF        equ 5
sfKeyJ        equ 9
sfKeyK        equ 10

; 視窗風格定義
sfNone       equ 0
sfTitlebar   equ 1
sfResize     equ 2
sfClose      equ 4
sfFullscreen equ 8

; 結構體定義
sfVector2f STRUCT
    x REAL4 ?
    y REAL4 ?
sfVector2f ENDS

sfVector2i STRUCT
    x SDWORD ?
    y SDWORD ?
sfVector2i ENDS

sfVideoMode STRUCT
    _width  DWORD ?
    height DWORD ?
    bpp    DWORD ?
sfVideoMode ENDS

sfColor STRUCT
    r BYTE ?
    g BYTE ?
    b BYTE ?
    a BYTE ?
sfColor ENDS

sfFloatRect STRUCT
    left   REAL4 ?
    top    REAL4 ?
    _width  REAL4 ?
    height REAL4 ?
sfFloatRect ENDS

mouseButton STRUCT
    button DWORD ?
    x DWORD ?
    y DWORD ?
mouseButton ENDS

key STRUCT
    code DWORD ?
    alt DWORD ?
    control DWORD ?
    shift DWORD ?
    system DWORD ?
key ENDS

sfEvent STRUCT
    _type DWORD ?                
    _size DWORD ?                
    mouse mouseButton <>       
    _key key <>                 
    mouseMove sfVector2i <>     
sfEvent ENDS

; 函數原型 - 視窗相關
EXTERN sfRenderWindow_create:PROC
EXTERN sfRenderWindow_destroy:PROC
EXTERN sfRenderWindow_close:PROC
EXTERN sfRenderWindow_isOpen:PROC
EXTERN sfRenderWindow_clear:PROC
EXTERN sfRenderWindow_display:PROC
EXTERN sfRenderWindow_pollEvent:PROC
EXTERN sfRenderWindow_drawSprite:PROC
EXTERN sfRenderWindow_drawText:PROC

EXTERN sfWindow_setFramerateLimit:PROC

; 函數原型 - 紋理相關
EXTERN sfTexture_createFromFile:PROC
EXTERN sfTexture_destroy:PROC

; 函數原型 - 精靈相關
EXTERN sfSprite_create:PROC
EXTERN sfSprite_destroy:PROC
EXTERN sfSprite_setTexture:PROC
EXTERN sfSprite_setPosition:PROC
EXTERN sfSprite_getPosition:PROC

; 函數原型 - 音樂相關
EXTERN sfMusic_createFromFile:PROC
EXTERN sfMusic_destroy:PROC
EXTERN sfMusic_play:PROC
EXTERN sfMusic_setLoop:PROC
EXTERN sfMusic_stop: PROC
EXTERN sfMusic_getStatus: PROC

; 函數原型 - 文字相關
EXTERN sfFont_createFromFile:PROC
EXTERN sfFont_destroy:PROC
EXTERN sfText_create:PROC
EXTERN sfText_destroy:PROC
EXTERN sfText_setFont:PROC
EXTERN sfText_setString:PROC
EXTERN sfText_setCharacterSize:PROC
EXTERN sfText_setFillColor:PROC
EXTERN sfText_setOutlineColor:PROC
EXTERN sfText_setOutlineThickness:PROC
EXTERN sfText_getLocalBounds:PROC
EXTERN sfText_getGlobalBounds:PROC
EXTERN sfText_setPosition:PROC

; 函數原型 - 顏色相關
EXTERN sfColor_fromRGB:PROC
EXTERN sfColor_fromRGBA:PROC

; 函數原型 - 圓形相關
EXTERN sfCircleShape_create: PROC
EXTERN sfCircleShape_setPosition: PROC
EXTERN sfCircleShape_setRadius: PROC
EXTERN sfCircleShape_setFillColor: PROC
EXTERN sfRenderWindow_drawCircleShape: PROC
EXTERN sfCircleShape_destroy: PROC
EXTERN sfCircleShape_setOutlineThickness: PROC
EXTERN sfCircleShape_setOutlineColor: PROC

; 函數原型 - 矩形相關
EXTERN sfRectangleShape_create: PROC
EXTERN sfRectangleShape_setPosition: PROC
EXTERN sfRectangleShape_setSize: PROC
EXTERN sfRectangleShape_setFillColor: PROC
EXTERN sfRectangleShape_setOutlineThickness: PROC
EXTERN sfRenderWindow_drawRectangleShape: PROC
EXTERN sfRectangleShape_destroy: PROC
EXTERN sfRectangleShape_setOutlineColor: PROC

EXTERN sfSleep: PROC
EXTERN sfClock_create: PROC
EXTERN sfClock_getElapsedTime: PROC
EXTERN sfClock_restart: PROC