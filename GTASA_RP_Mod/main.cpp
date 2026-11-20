#include <mod/amlmod.h>
#include <aml-psdk/game_sa/Events.h>
#include <aml-psdk/game_sa/entity/PlayerPed.h>
#include <aml-psdk/game_sa/engine/Font.h>
#include <aml-psdk/game_sa/engine/RsGlobal.h>
#include "core/rp_system.hpp"
#include <cstdio>
#include <algorithm>

// Original add-on: does not replace GTA San Andreas assets.
MYMOD(net.freelife.gtasa.rp, FreeLife RP HUD, 0.2.0, FreeLife Team)

namespace {
freelife::rp::Profile gProfile{};

const char* jobName(freelife::rp::Job job) {
    using freelife::rp::Job;
    switch (job) {
        case Job::Mechanic: return "MECHANIC";
        case Job::Taxi: return "TAXI";
        case Job::Teacher: return "TEACHER";
        case Job::Farmer: return "FARMER";
        case Job::Citizen: default: return "CITIZEN";
    }
}

void DrawLine(float x, float y, const char* value, float scale = 0.34f) {
    CFont::SetOrientation(ALIGN_LEFT);
    CFont::SetColor(CRGBA(245, 245, 245, 255));
    CFont::SetBackground(false, false);
    CFont::SetWrapx(static_cast<float>(RsGlobal.maximumWidth) - 12.0f);
    CFont::SetScale((scale * RsGlobal.maximumWidth) / 640.0f, (scale * RsGlobal.maximumHeight) / 448.0f);
    CFont::SetFontStyle(FONT_SUBTITLES);
    CFont::SetProportional(true);
    CFont::SetDropShadowPosition(1);
    CFont::SetDropColor(CRGBA(0, 0, 0, 220));
    CFont::PrintString(x, y, const_cast<char*>(value));
}
}

ON_MOD_LOAD() {
    logger->SetTag("FreeLifeRP");
    Events::drawHudEvent += []() {
        CPlayerPed* player = FindPlayerPed(0);
        if (!player || !player->IsAlive()) return;

        const float width = static_cast<float>(RsGlobal.maximumWidth);
        const float height = static_cast<float>(RsGlobal.maximumHeight);
        const float x = width - (178.0f * width / 640.0f);
        const float y = 34.0f * height / 448.0f;

        char healthText[48];
        char cashText[48];
        char hungerText[48];
        char thirstText[48];

        std::snprintf(healthText, sizeof(healthText), "HEALTH: %d",
            static_cast<int>(std::max(0.0f, player->GetHealth())));
        std::snprintf(cashText, sizeof(cashText), "CASH: $%d", gProfile.cash);
        std::snprintf(hungerText, sizeof(hungerText), "HUNGER: %d%%", gProfile.hunger);
        std::snprintf(thirstText, sizeof(thirstText), "THIRST: %d%%", gProfile.thirst);

        DrawLine(x, y, "FREELIFE RP", 0.40f);
        DrawLine(x, y + 22.0f, jobName(gProfile.job));
        DrawLine(x, y + 42.0f, cashText);
        DrawLine(x, y + 62.0f, healthText);
        DrawLine(x, y + 82.0f, hungerText);
        DrawLine(x, y + 102.0f, thirstText);
    };
    logger->Info("FreeLife RP HUD 0.2.0 loaded. RP profile is session-only; gameplay hooks are not yet connected.");
}
