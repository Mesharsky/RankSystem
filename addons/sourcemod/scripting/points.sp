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

void AddPoints(int client, int amount, bool &rankUp = false)
{
    if (!CanGainPoints(client))
        return;

    g_PlayerTotalPoints[client] += amount;

    int oldRank = g_PlayerRankLevel[client];
    g_PlayerRankLevel[client] = CalculateRankByPoints(g_PlayerTotalPoints[client], g_PlayertotalPointsRequired[client]);

    rankUp = g_PlayerRankLevel[client] != oldRank;

    if (rankUp)
        NotifyRankUp(client);
}

void NotifyRankUp(int client)
{
    RankInfo info;

    int len = g_RankData.Length;
    int playerRankLevel = g_PlayerRankLevel[client];

    if (playerRankLevel >= 0 && playerRankLevel < len)
        g_RankData.GetArray(playerRankLevel, info, sizeof(info));

    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));

    CPrintToChat(client, "%s %t", g_ChatTag, "Player Rank Up", info.rankName);
    AnnounceRankUp(name, info.rankName, playerRankLevel, client);
}

void AnnounceRankUp(const char[] name, const char[] rankName, int playerRankLevel, int client)
{
    if (g_RankMisc.RankGlobalMessageEnable)
        CPrintToChatAll("%s %t", g_ChatTag, "Player Rank Up Notify All", name, rankName);

    Rank_ApplyOverlayAndSound(client, playerRankLevel);
}

void RemovePoints(int client, int amount, bool &rankDown = false)
{
    if (!CanGainPoints(client))
        return;

    g_PlayerTotalPoints[client] -= amount;

    // Ensure points don't go below zero
    if (g_PlayerTotalPoints[client] < 0)
        g_PlayerTotalPoints[client] = 0;

    int oldRank = g_PlayerRankLevel[client];
    g_PlayerRankLevel[client] = CalculateRankByPoints(g_PlayerTotalPoints[client], g_PlayertotalPointsRequired[client]);

    rankDown = g_PlayerRankLevel[client] != oldRank;

    if (rankDown)
        NotifyRankDown(client);
}

void NotifyRankDown(int client)
{
    RankInfo info;

    int len = g_RankData.Length;
    int playerRankLevel = g_PlayerRankLevel[client];

    if (playerRankLevel >= 0 && playerRankLevel < len)
        g_RankData.GetArray(playerRankLevel, info, sizeof(info));

    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));

    CPrintToChat(client, "%s %t", g_ChatTag, "Player Rank Down", info.rankName);
    AnnounceRankDown(name, info.rankName, playerRankLevel, client);
}

void AnnounceRankDown(const char[] name, const char[] rankName, int playerRankLevel, int client)
{
    if (g_RankMisc.RankGlobalMessageEnable)
        CPrintToChatAll("%s %t", g_ChatTag, "Player Rank Down Notify All", name, rankName);

    RankDown_ApplyOverlayAndSound(client, playerRankLevel);
}

void SetPoints(int client, int points, bool &rankChanged = false)
{
    if (points < 0)
        return;

    int oldRank = g_PlayerRankLevel[client];
    g_PlayerTotalPoints[client] = points;

    g_PlayerRankLevel[client] = CalculateRankByPoints(g_PlayerTotalPoints[client], g_PlayertotalPointsRequired[client]);

    rankChanged = g_PlayerRankLevel[client] != oldRank;

    if (rankChanged)
        NotifyRankChanged(client);
}

void NotifyRankChanged(int client)
{
    RankInfo info;

    int len = g_RankData.Length;
    int playerRankLevel = g_PlayerRankLevel[client];

    if (playerRankLevel >= 0 && playerRankLevel < len)
        g_RankData.GetArray(playerRankLevel, info, sizeof(info));

    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));

    CPrintToChat(client, "%s %t", g_ChatTag, "Player Rank Changed", info.rankName);
    AnnounceRankChanged(name, info.rankName, playerRankLevel, client);
}

void AnnounceRankChanged(const char[] name, const char[] rankName, int playerRankLevel, int client)
{
    if (g_RankMisc.RankGlobalMessageEnable)
        CPrintToChatAll("%s %t", g_ChatTag, "Player Rank Notify All", name, rankName);

    Rank_ApplyOverlayAndSound(client, playerRankLevel);
}


void Rank_ApplyOverlayAndSound(int client, int playerRankLevel)
{
    if (g_RankMisc.RankOverlayEnable)
    {
        if (g_RankTypeConfig == 2)
            return;

        char buffer[64];
        FormatEx(buffer, sizeof(buffer), "serversquare/rank-overlays/rank_%d", playerRankLevel);
        ClientCommand(client, "r_screenoverlay \"%s\"", buffer);
        CreateTimer(2.0, Timer_DeleteOverlay, client);
    }

    if (g_RankMisc.RankRankUpSoundEnable)
        EmitSoundToClient(client, "*/serversquare/rank-sound/rankUp.mp3");
}

void RankDown_ApplyOverlayAndSound(int client, int playerRankLevel)
{
    if (g_RankMisc.RankOverlayEnable)
    {
        if (g_RankTypeConfig == 2)
            return;
        char buffer[64];
        FormatEx(buffer, sizeof(buffer), "serversquare/rank-overlays/rank_%d", playerRankLevel);
        ClientCommand(client, "r_screenoverlay \"%s\"", buffer);
        CreateTimer(2.0, Timer_DeleteOverlay, client);
    }

    if (g_RankMisc.RankRankUpSoundEnable)
        ClientCommand(client, "play */UI/armsrace_demoted.wav");
}

int CalculateRankByPoints(int totalPoints, int &pointsRemaining = 0)
{
    int len = g_RankData.Length;
    if (len <= 0)
    {
        pointsRemaining = 0;
        return 0;
    }

    if (totalPoints < 0)
        totalPoints = 0;

    RankInfo info;

    for (int nextRank = 1; nextRank < len; ++nextRank) // Skip unranked
    {
        g_RankData.GetArray(nextRank, info, sizeof(info));

        if (totalPoints < info.totalPointsRequired)
        {
            pointsRemaining = info.totalPointsRequired - totalPoints;
            return nextRank - 1;
        }
    }

    pointsRemaining = 0;
    return len - 1;
}