includelib ucrt.lib
includelib kernel32.lib


Drum struct
	sprite dword ?
	_type dword ?
	targetTime real4 ?
Drum ends

GameStats struct
	great_count DWORD ? 
	good_count DWORD ? 
	miss_count DWORD ? 
	current_combo DWORD ? 
	max_combo DWORD ? 
	total_score DWORD ? 
GameStats ends

MusicInfo struct
	bpm real4 ?
	_offset real4 ?
	spawnTime real4 ?
	currentBar dword ?
	notesInBar dword ?
MusicInfo ends

extern malloc:proc
extern fopen:proc
extern fclose:proc
extern fgets:proc


; string

extern strcspn:proc
extern strncmp:proc
;extern __imp____stdio_common_vsscanf:proc
extern strtok_s:proc
extern strlen:proc