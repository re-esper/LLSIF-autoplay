#include <mach/mach.h>
#include <mach-o/dyld.h>
#import <substrate.h>

int (*orig_luaL_loadbufferx)(void *L, const char *buff, unsigned long size, const char *name, const char *mode);

char settings_lua_scripts[] = R"(
local settings = {}
settings.WHEEL_GAP = 180
settings.BACKGROUND_PRIORITY = 0
settings.STAR_PRIORITY = 2800
settings.COMBO_PRIORITY = 2900
settings.NOTE_PRIORITY = 2950
settings.PAUSEMENU_PRIORITY = 3000
settings.CHARACTER_PRIORITY = 2405
settings.CLEAR_PRIORITY = settings.COMBO_PRIORITY + 100
settings.CHARACTER_COUNT = 9
settings.CHARACTER_ANGLE = (360 - settings.WHEEL_GAP) / (settings.CHARACTER_COUNT - 1)
settings.CHARACTER_CUTIN_OFFSET_X = 480
settings.CHARACTER_CUTIN_OFFSET_Y = 320
settings.ICON_OFFSET_X = 64
settings.ICON_OFFSET_Y = 64
settings.FULLCOMBO_DISPLAY_MSEC = 2000
settings.X = 480
settings.Y = 160
settings.R = 400
settings.R_ADJUSTED = settings.R * import("FullScreenBackground").getScaleValue()
settings.SCORE_X = 480
settings.SCORE_Y = 320
settings.SCORE_PRIORITY = 3000
settings.ACCURACY = {
    perfect = 16,
    great = 40,
    good = 64,
    bad = 112,
    miss = 128
}
settings.ACCURACY_LIMIT_SPEED = 0.8
settings.Priority = { Elements = 2900 }

define("Settings", settings)

include_once("file://install/m_live/note.lua")
local note = import("Note")
local dbapi = import("dbapi")
local const = import("const")
local orig_create = note.create
function note.create(_0, _1, _2, _3, _4, _5, _6, _7, _8)
    local isCheatModeEnabled = false
    local _rates = { 0, 0 }
    local scenario_adjustment = dbapi.loadBasicSettings().scenario_adjustment
    if scenario_adjustment == const.TEXT_SPEED.MIDDLE then
        _rates = { 0.005, 0.15 }
        isCheatModeEnabled = true
    elseif scenario_adjustment == const.TEXT_SPEED.FAST then
        _rates = { 0, 0.05 }
        isCheatModeEnabled = true
    end
    local inst = orig_create(_0, _1, _2, _3, _4, _5, _6, _7, _8)
    local orig_updateNormal = inst._updateNormal
    function inst._updateNormal(_0, _1, _2)
        if isCheatModeEnabled and _0:tapDistance(_1) >= settings.R then
            return orig_updateNormal(_0, _1, 1)
        end
        return orig_updateNormal(_0, _1, _2)
    end
    local orig_updateHoldAfterTap = inst._updateHoldAfterTap
    function inst._updateHoldAfterTap(_0, _1, _2, _3, _4, _5)
        if isCheatModeEnabled then
            return { tapped = _2 >= settings.R }
        end
        return orig_updateHoldAfterTap(_0, _1, _2, _3, _4, _5)
    end
    local orig_updateHoldBeforeTap = inst._updateHoldBeforeTap
    function inst._updateHoldBeforeTap(_0, _1, _2, _3, _4, _5)
        if isCheatModeEnabled and _1 >= settings.R then
            return { first_touch = true }
        end
        return orig_updateHoldBeforeTap(_0, _1, _2, _3, _4, _5)
    end
    local orig_getAccuracy = inst.getAccuracy
    function inst.getAccuracy(_0, _1)
        if isCheatModeEnabled then
            local r = math.random()
            if r > _rates[2] then
                return "perfect"
            elseif r > _rates[1] then
                return "great"
            else
                return "good"
            end
        end
        return orig_getAccuracy(_0, _1)
    end
    return inst
end
)";

int hook_luaL_loadbufferx(void *L, const char *buff, unsigned long size, const char *name, const char *mode) {	
	if (strcmp(name, "file://install/m_live/settings.lua") == 0) {
		return orig_luaL_loadbufferx(L, settings_lua_scripts, strlen(settings_lua_scripts), name, mode);
	}
	return orig_luaL_loadbufferx(L, buff, size, name, mode);
}

%ctor {
	NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];

	unsigned long addr = (unsigned long)_dyld_get_image_header(0);
	if ([bundleId isEqualToString:@"com.meiyu.lovelive"]) { // cn version
	 	addr += 0x50000; // replace with your current 'luaL_loadbufferx' offset
	}
	else if ([bundleId isEqualToString:@"jp.klab.lovelive"]) { // jp version
	 	addr += 0x50000; // replace with your current 'luaL_loadbufferx' offset
	}

	MSHookFunction((void*)addr, (void*)&hook_luaL_loadbufferx, (void**)&orig_luaL_loadbufferx);
}
