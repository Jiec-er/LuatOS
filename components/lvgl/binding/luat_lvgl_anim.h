
#ifndef LUAT_LVGL_ANIM
#define LUAT_LVGL_ANIM

#include "luat_base.h"
#include "lvgl.h"

int luat_lv_anim_create(lua_State *L);
int luat_lv_anim_free(lua_State *L);

#define LUAT_LV_ANIM2_RLT {"anim_create", luat_lv_anim_create, 0},\
{"anim_free", luat_lv_anim_free, 0},\

#endif