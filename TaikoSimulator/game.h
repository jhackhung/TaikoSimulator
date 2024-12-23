#ifndef GAME_H
#define GAME_H

#include <SFML/Graphics.h>
#include <SFML/Window.h>
#include <SFML/System.h>
#include <SFML/Audio.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

    // 定義遊戲中使用的結構
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
        float spawnTime;
        int currentBar;
        int notesInBar;
    } MusicInfo;

    // 主遊戲函數
    int main_game(sfRenderWindow* window);

#ifdef __cplusplus
}
#endif

#endif // GAME_H