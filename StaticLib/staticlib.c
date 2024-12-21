// StaticLib.cpp : Defines the functions for the static library.
//

#include "pch.h"
#include "framework.h"
#include <SFML/Graphics.h>
#include <SFML/Window.h>
#include <SFML/System.h>
#include <SFML/Audio.h>
#include <stdio.h>

#define MAX_NOTES 10000
#define MAX_LINE_LENGTH 1000
#define SCREEN_WIDTH 1280
#define SCREEN_HEIGHT 720
#define MAX_DRUMS 100
#define HIT_POSITION_X 450  // �P�w�ꪺX�y��
#define GREAT_THRESHOLD 4  // Great�P�w���~�t�d��]�����^
#define GOOD_THRESHOLD 30   // Good�P�w���~�t�d��]�����^
#define INITIAL_DELAY  3.0f  // �C���}�l�e���˼Ʈɶ��]��^

typedef struct Drum {
    sfSprite* sprite;
    int type; // 1 = ���⹪, 2 = �Ŧ⹪
    float targetTime;
} Drum;

typedef struct {
    int great_count;
    int good_count;
    int miss_count;
    int current_combo;
    int max_combo;
    int total_score;
} GameStats;

typedef struct {
    float bpm;
    float offset;
    float spawnTime;  // �Ĥ@�ӭ��Ū��ͦ��ɶ�
    int currentBar;   // �ثe�B�z����Ӥp�`
    int notesInBar;   // �ثe�p�`�����żƶq
} MusicInfo;

GameStats stats = { 0, 0, 0, 0, 0, 0 };

MusicInfo musicInfo = { 0 };

Drum drumQueue[MAX_DRUMS];
int front = 0;
int rear = 0;
int size = 0;
sfTexture* redDrumTexture;
sfTexture* blueDrumTexture;

int notes[MAX_NOTES];
int totalNotes = 0;
float noteSpawnInterval; // �ھ�BPM�p�⪺�ͦ����j
float noteTimings[MAX_NOTES];  // �C�ӭ��Ū��ͦ��ɶ�
float drumStep = 0.25f;


// TODO: This is an example of a library function
void parseNoteChart(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("�L�k�}���ɮסI\n");
        return;
    }

    char line[MAX_LINE_LENGTH];
    int inNoteSection = 0;
    totalNotes = 0;

    float currentTime = 0.0f; // ������e���ťͦ����ɶ�
    char* context;

    while (fgets(line, sizeof(line), file)) {
        line[strcspn(line, "\n")] = 0; // ��������Ÿ�

        if (strncmp(line, "BPM:", 4) == 0) {
            sscanf_s(line, "BPM:%f", &musicInfo.bpm);
            continue;
        }

        if (strncmp(line, "OFFSET:", 7) == 0) {
            sscanf_s(line, "OFFSET:%f", &musicInfo.offset);
            //currentTime = musicInfo.offset; // ��l�Ʈɶ��������q
            continue;
        }

        if (strncmp(line, "#START", 6) == 0) {
            inNoteSection = 1;
            continue;
        }

        if (strncmp(line, "#END", 4) == 0) {
            break;
        }

        if (inNoteSection) {
            char* bar = strtok_s(line, ",", &context);
            while (bar != NULL) {
                int barLength = strlen(bar);
                int validNotes = 0;

                // �p�⦳�ĭ��żƶq
                for (int i = 0; i < barLength; i++) {
                    if (bar[i] >= '0' && bar[i] <= '2') {
                        validNotes++;
                    }
                }

                if (validNotes > 0) {
                    float beatTime = 60.0f / musicInfo.bpm;  // �@��ɶ�
                    //float barTime = validNotes / beatTime;  // �p�`�`�ɶ�
                    float barTime = 4 * beatTime; // ���]�@�p�`�O4��
                    float noteInterval = barTime / validNotes; // �歵�Ůɶ�

                    for (int i = 0; i < barLength; i++) {
                        char note = bar[i];
                        if (note >= '0' && note <= '2') {
                            if (note != '0') { // �ư��ũ�
                                notes[totalNotes] = note - '0';
                                noteTimings[totalNotes] = currentTime;
                                totalNotes++;
                            }
                            currentTime += noteInterval; // ��s��e�ɶ�
                        }
                    }
                }

                bar = strtok_s(NULL, ",", &context);
            }
        }
    }

    /*for (int i = 0; i < totalNotes; i++) {
        printf("note: %d, time: %f\n", notes[i], noteTimings[i]);
    }*/

    fclose(file);

    // ���ťͦ����j
    noteSpawnInterval = 60000.0f / (musicInfo.bpm * 4.0f);

    float drumSpeed = (SCREEN_WIDTH - HIT_POSITION_X) / (4 * 60.0f / musicInfo.bpm);
    drumStep = drumSpeed / 60;
    //printf("drumStep: %f drumSpeed: %f\n", drumStep, drumSpeed);

    //printf("BPM: %f, OFFSET: %f, ���ťͦ����j: %f�@��\n", musicInfo.bpm, musicInfo.offset, noteSpawnInterval);
}


int isQueueFull() {
    return size == MAX_DRUMS;
}

int isQueueEmpty() {
    return size == 0;
}

void enqueue(Drum drum) {
    if (isQueueFull()) {
        printf("Queue is full!\n");
        return;
    }
    drumQueue[rear] = drum;
    rear = (rear + 1) % MAX_DRUMS;
    size++;
}

void dequeue() {
    if (isQueueEmpty()) {
        printf("Queue is empty!\n");
        return;
    }
    sfSprite_destroy(drumQueue[front].sprite);
    front = (front + 1) % MAX_DRUMS;
    size--;
}

void spawnDrum(int type, float targetTime) {
    if (isQueueFull()) {
        printf("Queue is full, cannot spawn more drums!\n");
        return;
    }

    Drum drum;
    drum.type = type;
    drum.targetTime = targetTime;  // �]�w�ؼЮɶ�
    drum.sprite = sfSprite_create();

    if (drum.type == 1) {
        sfSprite_setTexture(drum.sprite, redDrumTexture, sfTrue);
    }
    else {
        sfSprite_setTexture(drum.sprite, blueDrumTexture, sfTrue);
    }

    // �ھڥؼЮɶ��p���l��m
    float initialX = SCREEN_WIDTH;
    sfSprite_setPosition(drum.sprite, (sfVector2f) { initialX, 200 });

    enqueue(drum);
}

void updateDrums() {
    // ���ˬd�O�_�ݭn�R�� front ����

    /*if (size>0 && sfSprite_getPosition(drumQueue[front].sprite).x == 404-32) {
        sfSleep(sfMilliseconds(1000) );
        printf("the position be like %f\n", sfSprite_getPosition(drumQueue[front].sprite).x);
    }*/

    if (size > 0 && sfSprite_getPosition(drumQueue[front].sprite).x < HIT_POSITION_X - 85) {
        sfSprite_destroy(drumQueue[front].sprite);
        stats.miss_count++;
        stats.current_combo = 0;
        front = (front + 1) % MAX_DRUMS;
        size--;
    }
    // ��s�Ѿl��������m
    int count = size;
    int index = front;
    while (count > 0) {
        sfVector2f pos = sfSprite_getPosition(drumQueue[index].sprite);
        pos.x -= drumStep;
        sfSprite_setPosition(drumQueue[index].sprite, pos);
        index = (index + 1) % MAX_DRUMS;
        count--;
    }
}

sfCircleShape* createJudgementCircle() {
    sfCircleShape* circle = sfCircleShape_create();
    sfCircleShape_setRadius(circle, 30);
    sfCircleShape_setPosition(circle,
        (sfVector2f) {
        HIT_POSITION_X, 200 + 25
    }); // �~�����
    sfCircleShape_setFillColor(circle, sfTransparent);
    sfCircleShape_setOutlineThickness(circle, 2);
    sfCircleShape_setOutlineColor(circle, sfBlack);
    return circle;
}

// �B�z�����P�w
void processHit(int hitType) {
    // �S�����Ůɪ�����^
    if (size == 0) return;

    // ����̫e�������Ŧ�m
    sfVector2f drumPos = sfSprite_getPosition(drumQueue[front].sprite);
    float distance = drumPos.x - (HIT_POSITION_X - 46);
    printf("�Z��: %f\n", distance);
    // �u�P�w�Z���P�w����񪺭���
    if (distance < -GOOD_THRESHOLD || distance > GOOD_THRESHOLD) {
        return;
    }

    // �ˬd���������O�_�ǰt
    if (drumQueue[front].type != hitType) {
        stats.miss_count++;
        stats.current_combo = 0;
        return;
    }

    // �ھڶZ���P�w���G
    float abs_distance = (distance < 0) ? -distance : distance;
    if (abs_distance <= GREAT_THRESHOLD) {
        // Great�P�w
        stats.great_count++;
        stats.current_combo++;
        stats.total_score += 300 + (stats.current_combo * 10);
        if (stats.current_combo > stats.max_combo) {
            stats.max_combo = stats.current_combo;
        }
        dequeue();  // �����R��������
    }
    else if (abs_distance <= GOOD_THRESHOLD) {
        // Good�P�w
        stats.good_count++;
        stats.current_combo++;
        stats.total_score += 100 + (stats.current_combo * 5);
        if (stats.current_combo > stats.max_combo) {
            stats.max_combo = stats.current_combo;
        }
        dequeue();  // �����R��������
    }
}

void drawUI(sfRenderWindow* window, sfText* scoreText, sfCircleShape* judgementCircle) {
    char scoreString[200];
    snprintf(scoreString, sizeof(scoreString),
        "Score: %d\nGreat: %d\nGood: %d\nMiss: %d\nCombo: %d\nMax Combo: %d",
        stats.total_score, stats.great_count, stats.good_count, stats.miss_count,
        stats.current_combo, stats.max_combo);
    sfText_setString(scoreText, scoreString);

    sfRenderWindow_drawCircleShape(window, judgementCircle, NULL);
    sfRenderWindow_drawText(window, scoreText, NULL);
}
