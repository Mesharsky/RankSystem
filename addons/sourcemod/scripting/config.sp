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

#define CONFIG_PATH "configs/rank_system.cfg"
char g_ChatTag[64];

void LoadConfig()
{
	KeyValues kv = new KeyValues("RankSystem - Configuration");

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CONFIG_PATH);

	if (!kv.ImportFromFile(path))
		SetFailState("[ERROR] Could not find: %s", path);

	delete g_RankSettings;
	g_RankSettings = new RankSettings();

	ProcessSettingsSection(kv, g_RankSettings);

	delete g_RankMisc;
	g_RankMisc = new RankMisc();

	ProcessMiscSection(kv, g_RankMisc);

	delete g_RankPoints;
	g_RankPoints = new RankPoints();

	ProcessGainingPointsSection(kv, g_RankPoints);
	ProcessLosingPointsSection(kv, g_RankPoints);
	ProcessRankPointsSettings(kv);

	PrintToServer("[Rank System] Configuration file fully loaded (no errors detected)");
	LogMessage("[Rank System] Configuration file fully loaded (no errors detected)");
}

static void ProcessSettingsSection(KeyValues kv, RankSettings settings)
{
	if (!kv.JumpToKey("Settings"))
	{
		SetFailState("Section `Settings` is missing in configuration file. Check your configuration file");
		kv.GoBack();
		return;
	}

	g_RankType = 0;

	settings.MinimumPlayers = kv.GetNum("rank_minimum_players", 4);
	settings.ScoreboardDisplayEnable = view_as<bool>(kv.GetNum("rank_system_laderboard", 1));
	settings.RankLadeboardType = kv.GetNum("rank_scoreboard_style", 1);
	
	if (settings.RankLadeboardType == 2)
	{
		g_RankTypeConfig = 1;
		g_RankType = 50;
	}
	else if (settings.RankLadeboardType == 1)
	{
		g_RankTypeConfig = 0;
		g_RankType = 0;
	}
	else if (settings.RankLadeboardType == 3)
	{
		g_RankTypeConfig = 2;
		g_RankType = 3000;
	}
	
	settings.RankVipSystemEnable = view_as<bool>(kv.GetNum("rank_system_vip", 1));

	char buffer[MAX_OVERRIDE_NAME];

	kv.GetString("rank_system_vip_flag", buffer, sizeof(buffer));
	int flag = ReadFlagString(buffer);
	settings.RankVipFlag = flag;

	kv.GetString("rank_system_vip_override", buffer, sizeof(buffer));

	settings.SetRankVipOvveride(buffer);

	kv.GoBack(); 	// We are at `RankSystem - Configuration`
}

static void ProcessMiscSection(KeyValues kv, RankMisc misc)
{
	if (!kv.JumpToKey("Misc"))
	{
		SetFailState("Section `Misc` is missing in configuration file. Check your configuration file");
		kv.GoBack();
		return;
	}

	kv.GetString("chat_tag", g_ChatTag, sizeof(g_ChatTag));

	misc.RankOverlayEnable = view_as<bool>(kv.GetNum("rankup_overlay", 1));
	misc.RankRankUpSoundEnable = view_as<bool>(kv.GetNum("rankup_sound", 1));
	misc.RankGlobalMessageEnable = view_as<bool>(kv.GetNum("rankup_message", 1));

	kv.GoBack();	// We are at `RankSystem - Configuration`
}

static void ProcessGainingPointsSection(KeyValues kv, RankPoints points)
{
	if (!kv.JumpToKey("Gaining Points"))
	{
		SetFailState("Section `Gaining Points` is missing in configuration file. Check your configuration file");
		kv.GoBack();
		return;
	}

	if (!kv.JumpToKey("Regular Players"))
	{
		SetFailState("Section `Regular Players` is missing in configuration file. Check your configuration file");
		kv.Rewind();
		return;
	}

	// Basic Points
	points.PointsEarnKill = kv.GetNum("points_kill", 2);
	points.PointsEarnHeadShot = kv.GetNum("points_headshot", 3);
	points.PointsEarnAssist = kv.GetNum("points_assist", 1);
	points.PointsEarnMVP = kv.GetNum("points_mvp", 4);
	points.PointsEarnKnifeKill = kv.GetNum("points_knife_kill", 5);

	// Bomb
	points.PointsEarnBombPlanted = kv.GetNum("points_bomb_planted", 2);
	points.PointsEarnBombDefused = kv.GetNum("points_bomb_defused", 2);

	// Round
	points.PointsEarnRoundWin = kv.GetNum("points_round_win", 1);

	kv.GoBack();	// We are at `Gaining Points` section now.

	if (!kv.JumpToKey("VIP Players"))
	{
		SetFailState("Section `VIP Players` is missing in configuration file. Check your configuration file");
		kv.Rewind();
		return;
	}

	// *VIP* Basic Points
	points.PointsEarnKillVip = kv.GetNum("points_vip_kill", 3);
	points.PointsEarnHeadShotVip = kv.GetNum("points_vip_headshot", 4);
	points.PointsEarnAssistVip = kv.GetNum("points_vip_assist", 2);
	points.PointsEarnMVPVip = kv.GetNum("points_vip_mvp", 5);
	points.PointsEarnKnifeKillVip = kv.GetNum("points_vip_knife_kill", 7);

	// *VIP* Bomb
	points.PointsEarnBombPlantedVip = kv.GetNum("points_vip_bomb_planted", 3);
	points.PointsEarnBombDefusedVip = kv.GetNum("points_vip_bomb_defused", 3);

	// *VIP* Round
	points.PointsEarnRoundWinVip = kv.GetNum("points_vip_round_win", 2);

	kv.GoBack();	// We are at `Gaining Points` section now.
	kv.GoBack();	// We are at `RankSystem - Configuration`
}

static void ProcessLosingPointsSection(KeyValues kv, RankPoints points)
{
	if (!kv.JumpToKey("Losing Points"))
	{
		SetFailState("Section `Losing Points` is missing in configuration file. Check your configuration file");
		kv.GoBack();	// We are at `RankSystem - Configuration`
		return;
	}

	if (!kv.JumpToKey("Regular Players"))
	{
		SetFailState("Section `Regular Players` is missing in configuration file. Check your configuration file");
		kv.Rewind();	// We are at `RankSystem - Configuration`
		return;
	}

	points.PointsLoseDeath = kv.GetNum("points_lose_death", 2);
	points.PointsLoseLostRound = kv.GetNum("points_lose_lostround", 2);

	kv.GoBack();	// We are at `Losing Points`

	if (!kv.JumpToKey("VIP Players"))
	{
		SetFailState("Section `VIP Players` is missing in configuration file. Check your configuration file");
		kv.Rewind();
		return;
	}

	points.PointsLoseDeathVip = kv.GetNum("points_vip_lose_death", 1);
	points.PointsLoseLostRoundVip = kv.GetNum("points_vip_lose_lostround", 1);

	kv.GoBack();	// We are at `Losing Points`
	kv.GoBack();	// We are at `RankSystem - Configuration`
}

static void ProcessRankPointsSettings(KeyValues kv)
{
	if (!kv.JumpToKey("Rank Points Settings"))
	{
		SetFailState("Section `Rank Points Settings` is missing in configuration file. Check your configuration file");
		kv.GoBack();	// We are at `RankSystem - Configuration`
		return;
	}

	if (g_RankTypeConfig != 0 && g_RankTypeConfig != 1)
	{
		kv.Rewind();
		ProcessFaceitRankPointsSettings(kv);
		return;
	}

	g_RankData.Clear();

	RankInfo info;
	int count;
	char index[19] = "0";

	while (kv.JumpToKey(index))
	{
		info.totalPointsRequired = kv.GetNum("required_points");

		// Unranked must always be accessible to everyone, so it must require 0 points
		// Ranga unranked musi być dostępna dla wszystkich, więc musi on wymagać 0 punktów.
		if (count == 0 && info.totalPointsRequired != 0)
		{
			info.totalPointsRequired = 0;
			LogMessage("[Error] Unranked must have 'required_points' set to 0. Ignoring non-zero value.");
		}

		kv.GetString("rank_name", info.rankName, sizeof(RankInfo::rankName));

		g_RankData.PushArray(info);
		
		count++;
		IntToString(count, index, sizeof(index));
		
		kv.GoBack();
	}

	PrintToServer("[RankSystem] Pomyślnie załadowano %i rang. Wybrane rangi: Wingman/Normalne", count);

	delete kv;

	if (count == 0)
	{
		SetFailState("[ERROR] There is no ranks available in configuration file");
		delete kv;
		return;
	}
}

static void ProcessFaceitRankPointsSettings(KeyValues kv)
{
	if (!kv.JumpToKey("Faceit Rank Points Settings"))
	{
		SetFailState("Section `Faceit Rank Points Settings` is missing in configuration file. Check your configuration file");
		kv.GoBack();	// We are at `RankSystem - Configuration`
		return;
	}

	if (g_RankTypeConfig != 2)
		return;

	g_RankData.Clear();

	RankInfo info;
	int count;
	char index[41] = "0";

	while (kv.JumpToKey(index))
	{
		info.totalPointsRequired = kv.GetNum("required_points");

		// Unranked must always be accessible to everyone, so it must require 0 points
		// Ranga unranked musi być dostępna dla wszystkich, więc musi on wymagać 0 punktów.
		if (count == 0 && info.totalPointsRequired != 0)
		{
			info.totalPointsRequired = 0;
			LogMessage("[Error] Unranked must have 'required_points' set to 0. Ignoring non-zero value.");
		}

		kv.GetString("rank_name", info.rankName, sizeof(RankInfo::rankName));

		g_RankData.PushArray(info);
		
		count++;
		IntToString(count, index, sizeof(index));
		
		kv.GoBack();
	}

	PrintToServer("[RankSystem] Pomyślnie załadowano %i rang. Wybrane rangi: Faceit", count);

	delete kv;

	if (count == 0)
	{
		SetFailState("[ERROR] There is no ranks available in configuration file");
		delete kv;
		return;
	}
}