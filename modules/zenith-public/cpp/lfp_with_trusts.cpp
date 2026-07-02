/************************************************************************
 * LFP With Trusts Module
 *************************************************************************
 * Copyright (c) 2026 ZenithXI Dev Teams
 *************************************************************************
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/
 *************************************************************************
 * This module allows players to toggle LFP status while trusts are
 * deployed, bypassing client-side restrictions.
 *
 * Exposes player:setSeekingParty(value) method binding to Lua.
 ************************************************************************/
#include "map/utils/moduleutils.h"

#include "common/lua.h"
#include "map/entities/char_entity.h"
#include "map/lua/lua_base_entity.h"
#include "map/packets/char_status.h"
#include "map/packets/char_sync.h"
#include "map/packets/s2c/0x0b4_config.h"
#include "map/utils/charutils.h"

class LfpWithTrustsModule : public CPPModule
{
    void OnInit() override
    {
        TracyZoneScoped;

        // Bind setSeekingParty as a method on CBaseEntity
        // Usage: player:setSeekingParty(true/false)
        lua["CBaseEntity"]["setSeekingParty"] = [](CLuaBaseEntity* PLuaEntity, bool value) -> bool
        {
            TracyZoneScoped;

            if (PLuaEntity == nullptr)
            {
                return false;
            }

            CBaseEntity* PEntity = PLuaEntity->GetBaseEntity();
            if (PEntity == nullptr || PEntity->objtype != TYPE_PC)
            {
                return false;
            }

            auto* PChar = static_cast<CCharEntity*>(PEntity);

            if (PChar->playerConfig.InviteFlg != value)
            {
                PChar->playerConfig.InviteFlg = value;
                PChar->updatemask |= UPDATE_HP;
                charutils::SaveCharStats(PChar);
                charutils::SavePlayerSettings(PChar);
                PChar->pushPacket<GP_SERV_COMMAND_CONFIG>(PChar);
                PChar->pushPacket<CCharStatusPacket>(PChar);
                PChar->pushPacket<CCharSyncPacket>(PChar);
            }

            return true;
        };
    }
};

REGISTER_CPP_MODULE(LfpWithTrustsModule);
