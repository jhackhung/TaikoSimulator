includelib libucrtd.lib
includelib libvcruntimed.lib
includelib kernel32.lib
includelib libcmtd.lib

MAX_NOTES = 10000
MAX_LINE_LENGTH = 1000
SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
MAX_DRUMS = 100
HIT_POSITION_X = 450
GREAT_THRESHOLD = 4
GOOD_THRESHOLD = 30
INITIAL_DELAY = 3

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

extern parseNoteChart:PROC
extern isQueueFull:PROC 
extern isQueueEmpty:PROC 
extern enqueue:PROC 
extern dequeue:PROC 
extern spawnDrum:PROC 
extern updateDrums:PROC 
extern createJudgementCircle:PROC
extern processHit:PROC 
extern drawUI:PROC 
extern countdownEvent:PROC

