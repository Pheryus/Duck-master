global.deaths += 1;
global.numenemy = 0;
audio_play_sound(quackDeath, 50, false);

if (global.die_mode)
    room_goto(Recorde);
else
    room_restart();

