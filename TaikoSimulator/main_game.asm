.686P
.XMM
.model flat, c
include csfml.inc
include file.inc

extern currentPage: DWORD

; Constants
MAX_NOTES = 10000
MAX_LINE_LENGTH = 1000
SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
MAX_DRUMS = 100
HIT_POSITION_X = 450
GREAT_THRESHOLD = 4
GOOD_THRESHOLD = 30
INITIAL_DELAY = 3

.data
	stats GameStats <>
	msInfo MusicInfo <>

	; queue for drums
	drumQueue Drum MAX_DRUMS dup(<>)
	front dword 0
	rear dword 0
	_size dword 0

	; texture
	redDrumTexture dword ?
	blueDrumTexture dword ?

	notes dword MAX_NOTES dup(?)
	totalNotes dword 0
	noteSpawnInterval real4 0.0
	noteTimings real4 MAX_NOTES dup(?)
	drumStep real4 0.25

	; file
	readA byte "r", 0

	; ¦r¦ê±`¶q
	str_bpm db "BPM:", 0
	str_offset db "OFFSET:", 0
	str_start db "#START", 0
	str_end db "#END", 0
	comma db ",", 0

	getBmp db "BMP:%f", 0
	getOffset db "OFFSET:%f", 0

	real_60 real4 60.0
	real_4 real4 4.0
	real_60000 real4 60000.0

.code
ParseNoteChart PROC filename:PTR BYTE
	LOCAL filePtr:PTR FILE
	LOCAL line[256]:BYTE
	LOCAL inNoteSection:DWORD
	LOCAL bar:PTR BYTE
	LOCAL context:ptr byte
	local barlength:DWORD
	local validNotes:DWORD
	local i:DWORD
	local note:byte
	local currentTIme:real4
	local beatTime:real4
	local barTime:real4
	local noteInterval:real4

	; init variables
	mov inNoteSection, 0
	fldz ; currentTime 0

	; open file
	push dword ptr [readA]
	push filename
	call fopen
	add esp, 8

	test eax, eax
	jz FileOpenError
	mov filePtr, eax

ParseLineLoop:
	; read first line
	push filePtr
	push 256
	push dword ptr [line]
	call fgets
	add esp, 12

	test eax, eax
	jz EndParse

	; remove \n
	push 10
	push dword ptr [line]
	call strcspn
	add esp, 8

	movzx ecx, al
	mov byte ptr [line + ecx], 0

	; check bpm
	push 4
	push offset str_bpm
	push dword ptr [line]
	call strncmp
	add esp, 12

	test eax, eax
	jnz CheckOffset
	
	push offset msInfo.bpm
	push offset getBmp
	push dword ptr [line]
	call dword ptr __imp____stdio_common_vsscanf
	add esp, 12

	jmp ParseLineLoop

	; check offset
	
CheckOffset:
	push 7
	push offset str_offset
	push dword ptr [line]
	call strncmp
	add esp, 12

	test eax, eax
	jnz CheckStart
	push msInfo._offset
	push offset getOffset
	push dword ptr [line]
	call dword ptr __imp____stdio_common_vsscanf
	add esp, 12

	jmp ParseLineLoop

CheckStart:
	push 6
	push offset str_start
	push dword ptr [line]
	call strncmp
	add esp, 12

	test eax, eax
	jnz CheckEnd
	mov inNoteSection, 1
	jmp ParseLineLoop

CheckEnd:
	push 4
	push offset str_end
	push dword ptr [line]
	call strncmp
	add esp, 12

	test eax, eax
	jz EndParse
	
	cmp inNoteSection, 1
	jnz ParseLineLoop

	; allocate notes
	push context
	push dword ptr [comma]
	push dword ptr [line]
	call strtok_s
	add esp, 12

	test eax, eax
	jz ParseLineLoop

	mov bar, eax

ProcessBar:
	; get bar length
	push bar
	call strlen
	add esp, 4

	mov barlength, eax

	; get valid notes
	mov validNotes, 0
	mov ecx, barlength

	mov eax, i
	xor eax, eax
	mov i, eax
CountValidNotes:
	cmp i, ecx
	jge ComputeNoteTiming
	movzx eax, byte ptr [bar + i]
	cmp al, '0'
	jb SkipNote
	cmp al, '2'
	ja SkipNote
	inc validNotes
SkipNote:
	inc i
	jmp CountValidNotes

ComputeNoteTiming:
	; check if there are notes in the bar
	mov eax, validNotes
	cmp eax, 0
	je ProcessNextBar

	; calculate note time
	fld dword ptr [msInfo.bpm]
	fld1
	fdiv
	fmul dword ptr [real_60]
	fstp beatTime	; beatTime = 60 / bpm
	fmul dword ptr [real_4]
	fstp barTime	; barTime = 4 * beatTime
	fld barTIme
	fdiv validNotes
	fstp noteInterval  ; noteInterval = barTime / validNotes

	mov eax, i
	xor eax, eax
	mov i, eax

NoteLoop:
	mov eax, i
    cmp eax, barlength
	jge ProcessNextBar
	movzx eax, byte ptr [bar + i]
	cmp al, '0'
	jbe SkipToNextNote
	cmp al, '2'
	ja SkipToNextNote

	; store note and timing
	mov eax, totalNotes
	mov notes[eax], eax
	fld currentTIme
	fstp noteTimings[eax*4]
	inc totalNotes

SkipToNextNote:
    fld currentTime
	fld noteInterval
	fadd
	fstp currentTime
	inc i
	jmp NoteLoop

ProcessNextBar:
    push context
	push dword ptr [comma]
	push 0
	call strtok_s
	add esp, 12

	test eax, eax
	jnz ProcessBar
	mov bar, eax

	jmp ParseLineLoop

EndParse:
	push filePtr
	call fclose
	add esp, 4

	fld dword ptr [msInfo.bpm]
	fmul dword ptr [real_4]
	fld1
	fdiv
	fmul dword ptr [real_60000]
	fstp noteSpawnInterval

	mov eax, SCREEN_WIDTH
	sub eax, HIT_POSITION_X

	push eax
	fild dword ptr [esp]
	add esp, 4

	fld dword ptr [barTime]
	fdiv
	fstp dword ptr [drumStep]

	ret

FileOpenError:
	ret
ParseNoteChart ENDP

main_game_proc PROC window:dword,musicPath:dword,noteChart:dword
	push dword ptr [noteChart]
	call ParseNoteChart
	add esp, 4


@main_loop:
		


	@event_loop:






	@render_window:


@end:

@end_game:

	ret
main_game_proc ENDP

END main_game_proc
