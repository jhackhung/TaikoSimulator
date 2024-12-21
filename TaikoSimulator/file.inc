includelib ucrt.lib
includelib kernel32.lib


Drum struct
	sprite dword ?
	_type dword ?
	targetTime real4 ?
Drum ends

GameStats struct
	great_count dword ?
	good_count dword ?
	miss_count dword ?
	current_combo dword ?
	max_combo dword ?
	total_score dword ?
GameStats ends

MusicInfo struct
	bpm real4 ?
	_offset real4 ?
	spawnTime real4 ?
	currentBar dword ?
	notesInBar dword ?
MusicInfo ends

extern fopen:proc
extern fclose:proc
extern fgets:proc


; string

extern strcspn:proc
extern strncmp:proc
extern __stdio_common_vsscanf:proc
extern __stdio_common_vsprintf_s:proc
extern strtok_s:proc
extern strlen:proc