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

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

#include <ranksystem/ranksystem_core>

#pragma semicolon 1
#pragma newdecls required

#define MAX_RANK_NAME 32
#define MAX_OVERRIDE_NAME 64

enum struct RankInfo
{
    int totalPointsRequired;
    char rankName[MAX_RANK_NAME];
}

int g_RankTypeConfig;

enum struct MatchData
{
	int tRounds;
	int ctRounds;

	void Reset()
	{
		this.tRounds = 0;
		this.ctRounds = 0;
	}
}

MatchData g_MatchData;

enum struct MatchPlayerData
{
    int playerScore;
    int roundsWon;
    int roundsLost;
    int playerSuicides;
    int playerShots;
    int playerHits;
    int bombPlanted;
    int bombDefused;
    int playerAssists;
    int playerAssistsFlash;
    int playerAssistsTeamKill;
    int playerWinsCtSide;
    int playerWinsTSide;
    int hostagesRescued;
    int playerMvp;

    void Reset()
    {
        this.playerScore = 0;
        this.roundsWon = 0;
        this.roundsLost = 0;
        this.playerSuicides = 0;
        this.playerShots = 0;
        this.playerHits = 0;
        this.bombPlanted = 0;
        this.bombDefused = 0;
        this.playerAssists = 0;
        this.playerAssistsFlash = 0;
        this.playerAssistsTeamKill = 0;
        this.playerWinsCtSide = 0;
        this.playerWinsTSide = 0;
        this.hostagesRescued = 0;
        this.playerMvp = 0;
    }
}

MatchPlayerData g_MatchPlayerData[MAXPLAYERS + 1]; // Mapping each clients match data

enum struct SessionPlayerMatchData
{
    int playerKills;
    int playerDeaths;
    char weaponName[32];
    int playerHeadshots;
    int playerNoScopes;
    int playerBlindKills;
    int playerSmokeKills;
    int playerWallKills;
    float longestDistanceKill;
    int firstBloods;
    int totalDamage;

    void Reset()
    {
        this.playerKills = 0;
        this.playerDeaths = 0;
        this.weaponName = "Brak";
        this.playerHeadshots = 0;
        this.playerNoScopes = 0;
        this.playerBlindKills = 0;
        this.playerSmokeKills = 0;
        this.playerWallKills = 0;
        this.longestDistanceKill = 0.0;
        this.firstBloods = 0;
        this.totalDamage = 0;
    }
}

SessionPlayerMatchData g_SessionPlayerMatchData[MAXPLAYERS + 1];

Database g_DB;
ArrayList g_RankData;

ConVar g_Cvar_DBName;

bool g_IsLateLoad;
bool g_IsClientConnectedFull[MAXPLAYERS + 1];
int g_CurrentMatchId;

int g_PlayerRankPosition[MAXPLAYERS + 1];
int g_PlayerRankLevel[MAXPLAYERS + 1];
int g_PlayertotalPointsRequired[MAXPLAYERS + 1];
int g_PlayerTotalPoints[MAXPLAYERS + 1];

int g_RankType;
int g_RankOffset;
int g_PlayerManagerEntity;

RankSettings g_RankSettings;
RankMisc g_RankMisc;
RankPoints g_RankPoints;

#include "rankdata.sp"
#include "config.sp"
#include "points.sp"
#include "commands.sp"
#include "util.sp"
#include "events.sp"
#include "database.sp"
#include "awardpoints.sp"
#include "menu.sp"
#include "natives.sp"

public Plugin myinfo =
{
    name = "[CSGO] Rank System + Scoreboard ranks",
    author = "Mesharsky",
    description = "Advanced Rank System for csgo",
    version = "0.1",
    url = "https://github.com/Mesharsky"
};

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("ranksystem.phrases");

    g_RankOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
    g_RankData = new ArrayList(sizeof(RankInfo));

    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_mvp", Event_RoundMvp);
    HookEvent("bomb_planted", Event_BombPlanted);
    HookEvent("bomb_defused", Event_BombDefused);
    HookEvent("hostage_rescued", Event_HostageRescued);
    HookEvent("weapon_fire", Event_WeaponFire);

    RegConsoleCmd("sm_addpoints", Command_AddPoints, "Adds points for a player");
    RegConsoleCmd("sm_dodajpunkty", Command_AddPoints, "Dodaj punkty graczowi");

    RegConsoleCmd("sm_removepoints", Command_RemovePoints, "Removes points from a player");
    RegConsoleCmd("sm_zabierzpunkty", Command_RemovePoints, "Odejmuje punkty graczowi");

    RegConsoleCmd("sm_setpoints", Command_SetPoints, "Sets points for a player");
    RegConsoleCmd("sm_ustawpunkty", Command_SetPoints, "Ustawia punkty graczowi");

    RegConsoleCmd("sm_lvl", Command_RankMainMenu, "Opens rank main menu");
    RegConsoleCmd("sm_rangi", Command_RankMainMenu, "Opens rank main menu");
    RegConsoleCmd("sm_ranga", Command_RankMainMenu, "Opens rank main menu");
    RegConsoleCmd("sm_rank", Command_RankMainMenu, "Opens rank main menu");

    g_Cvar_DBName = CreateConVar("rank_db_name", "ranksystem", "Tree name to connect to the database");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_IsLateLoad = late;

    CreateNative("Rank_GetPoints", Native_GetPoints);
    CreateNative("Rank_SetPoints", Native_SetPoints);
    CreateNative("Rank_AddPoints", Native_AddPoints);
    CreateNative("Rank_RemovePoints", Native_RemovePoints);
    
    RegPluginLibrary("ranksystem_core");
    return APLRes_Success;
}

public void OnMapStart()
{
    AutoExecConfig(true, "RankSystem.cfg");
    CsPlayerEntityHookInitiate();
    DownloadAndPrecache();

    CreateTimer(1.0, Timer_LoadMapData);
}

public Action Timer_LoadMapData(Handle timer)
{
    Database_LoadMapData();
    return Plugin_Handled;
}

public void OnMapEnd()
{
    if (g_PlayerManagerEntity != -1)
        SDKUnhook(g_PlayerManagerEntity, SDKHook_ThinkPost, Hook_OnThinkPost);
    
    Database_OnMapEnd();
}

public void OnPluginEnd()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        OnClientDisconnect(i);
    }
}

public void OnConfigsExecuted()
{
    LoadConfig();
    DatabaseConnect();

    if (g_IsLateLoad)
    {
        for (int i = 1; i <= MaxClients; i++)
            OnClientPutInServer(i);

        g_IsLateLoad = false;
    }
}

public void OnClientPutInServer(int client)
{
    if (!CanGainPoints(client))
        return;

    if (g_DB == null)
        return;

    g_IsClientConnectedFull[client] = false;
    ResetGlobalVariables(client);
    Database_LoadData(client);
}

public void OnClientDisconnect(int client)
{
    if (!CanGainPoints(client))
        return;

    if (g_DB == null)
        return;      

    Database_SaveData(client);
    Database_SaveMatchPlayerData(client);
}

void ResetGlobalVariables(int client)
{
    g_PlayerRankLevel[client] = 0;
    g_PlayertotalPointsRequired[client] = 0;
    g_PlayerTotalPoints[client] = 0;
    g_SessionPlayerMatchData[client].Reset();
}

void DownloadAndPrecache()
{
    char buffer[128];
    char path[] = "materials/panorama/images/icons/skillgroups/skillgroup%i.svg";

    int len = g_RankData.Length;

    for (int i = 1; i < len; i++)
    {
        Format(buffer, sizeof(buffer), "materials/serversquare/rank-overlays/rank_%d.vmt", i);
        AddFileToDownloadsTable(buffer);
        Format(buffer, sizeof(buffer), "materials/serversquare/rank-overlays/rank_%d.vtf", i);
        AddFileToDownloadsTable(buffer);
        Format(buffer, sizeof(buffer), "serversquare/rank-overlays/rank_%d.vmt", i);
        PrecacheDecal(buffer, true);
        Format(buffer, sizeof(buffer), "serversquare/rank-overlays/rank_%d.vtf", i);
        PrecacheDecal(buffer, true);
    }    

    for (int i = 1; i <= 18; i++)
	{
		FormatEx(buffer, sizeof(buffer), path, i + 50);
		AddFileToDownloadsTable(buffer);
	}

    for (int i = 1; i <= 40; i++)
    {
        FormatEx(buffer, sizeof(buffer), path, i + 3000);
        AddFileToDownloadsTable(buffer);
    }

    AddFileToDownloadsTable("sound/serversquare/rank-sound/rankUp.mp3");
    PrecacheSound("*/serversquare/rank-sound/rankUp.mp3", true);
}

