/*	Copyright (C) 2023 ServerSquare.eu

    Author: Mesharsky
    Github: https://github.com/Mesharsky

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1
#pragma newdecls required

void CsPlayerEntityHookInitiate()
{
    g_PlayerManagerEntity = FindEntityByClassname(MaxClients + 1, "cs_player_manager");

    if (g_PlayerManagerEntity != -1)
    {
        SDKHookEx(g_PlayerManagerEntity, SDKHook_ThinkPost, Hook_OnThinkPost);
    }
}

public void Hook_OnThinkPost(int entity)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (g_RankTypeConfig != 2)
		{
			int value = g_PlayerRankLevel[i] + g_RankType;
			SetEntData(entity, g_RankOffset + i * 4, value == 50 ? 0 : value);
		}
		else
		{
			int value = g_PlayerRankLevel[i] + g_RankType;
			SetEntData(entity, g_RankOffset + i * 4, value);
		}
	}

	Handle usermsg = StartMessageAll("ServerRankRevealAll");
	if (usermsg == null)
		LogError("ServerRankRevealAll usermessage failed.");
	else
		EndMessage();
}

public Action Timer_DeleteOverlay(Handle timer, int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Handled;

    ClientCommand(client, "r_screenoverlay \"%s\"", "");

    return Plugin_Handled;
}

bool CanGainPoints(int client)
{
    if (IsClientAuthorized(client) && client > 0 && client <= MaxClients && IsClientInGame(client))
        return true;

    return false; 
}

bool IsClientAdmin(int client)
{
	return CheckCommandAccess(client, "ranksystem_admin", ADMFLAG_BAN);
}

bool IsMinimumPlayersAvailable()
{
    if (GetHumanPlayers() < g_RankSettings.MinimumPlayers)
        return false;

    return true;
}

bool IsWeaponKnife(const char[] classname)
{
    if (StrContains(classname, "knife", false) != -1 || StrContains(classname, "bayonet", false) != -1)
        return true;

    return false;
}

bool IsWeaponGrenade(const char[] classname)
{
    if (StrContains(classname, "hegrenade", false) != -1
        || StrContains(classname, "smokegrenade", false) != -1
        || StrContains(classname, "flashbang", false) != -1
        || StrContains(classname, "decoy", false) != -1
        || StrContains(classname, "molotov", false) != -1
        || StrContains(classname, "incgrenade", false) != -1
        || StrContains(classname, "breachcharge", false) != -1
        || StrContains(classname, "bumpmine", false) != -1
        || StrContains(classname, "snowball", false) != -1
        || StrContains(classname, "tagrenade", false) != -1)
    {
        return true;
    }
    return false;
}

bool ClientsAreTeammates(int clientA, int clientB)
{
    if (clientA < 1 || clientA > MaxClients)
        return false;
    if (clientB < 1 || clientB > MaxClients)
        return false;
    if (!IsClientInGame(clientA) || !IsClientInGame(clientB))
        return false;

    return GetClientTeam(clientA) == GetClientTeam(clientB);
}

/**
 * Truncates a longer string so it fits into the buffer, adding an indicator of clipped text.
 * 
 * @param text          The text to clip.
 * @param buffer        The buffer that will store the clipped text.
 * @param maxlen        The maximum length of the buffer.
 * @param clip          The string that will be used to indicate clipped text.
 * @param wordBreak     If true, will attempt to clip along word boundaries.  False will clip within
 * words.
 *
 * @note https://github.com/nosoop/stocksoup/blob/184f0762cc710136b01c5a0933300dea846fbfc8/string.inc#L30
 */
stock void TruncateString(const char[] text, char[] buffer, int maxlen,
		const char[] clip = "...", bool wordBreak = false) {
	strcopy(buffer, maxlen, text);
	
	if (strlen(text) > maxlen - 1) {
		int clipStart = maxlen - strlen(clip) - 1;
		
		if (wordBreak) {
			int nextBreak, partBreak;
			while ((partBreak = FindCharInString(text[nextBreak + 1], ' ', false)) != -1
					&& nextBreak + partBreak < clipStart) {
				nextBreak += partBreak + 1;
			}
			
			if (nextBreak && nextBreak <= clipStart) {
				clipStart = nextBreak;
			}
		}
		
		for (int i = 0; i < strlen(clip); i++) {
			buffer[clipStart + i] = clip[i];
		}
		
		if (strlen(text) > clipStart + strlen(clip) + 1) {
			buffer[clipStart + strlen(clip)] = '\0';
		}
	}
}

bool IsPlayerVip(int client)
{
	if (!g_RankSettings.RankVipSystemEnable)
		return false;

	char override[MAX_OVERRIDE_NAME];
	g_RankSettings.GetRankVipOverride(override, sizeof(override));

	if (GetUserFlagBits(client) & g_RankSettings.RankVipFlag == g_RankSettings.RankVipFlag)
		return true;
	
	if (CheckCommandAccess(client, override, ADMFLAG_ROOT))
		return true;
	
	return false;
}

bool IsWarmup()
{
    return GameRules_GetProp("m_bWarmupPeriod") != 0;
}

int GetHumanPlayers()
{
    int count;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && (!IsFakeClient(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR && GetClientTeam(i) != CS_TEAM_NONE))
            count++;
    }
    return count;
}