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

void AwardPlayer_Kill(int attacker, int victim)
{
    if (IsPlayerVip(attacker))
        NotifyAddPoints(attacker, g_RankPoints.PointsEarnKillVip, "Award Add Points Kill Vip");
    else
        NotifyAddPoints(attacker, g_RankPoints.PointsEarnKill, "Award Add Points Kill");

    if (IsPlayerVip(victim))
        NotifyRemovePoints(victim, g_RankPoints.PointsLoseDeathVip, "Remove Points Death Vip");
    else
        NotifyRemovePoints(victim, g_RankPoints.PointsLoseDeath, "Remove Points Death");
}

void AwardPlayer_Headshot(int attacker)
{
    if (IsPlayerVip(attacker))
        NotifyAddPoints(attacker, g_RankPoints.PointsEarnHeadShotVip, "Award Add Points HeadShot Vip");
    else
        NotifyAddPoints(attacker, g_RankPoints.PointsEarnHeadShot, "Award Add Points HeadShot");
}

void AwardPlayer_Assist(int client)
{
    if (IsPlayerVip(client))
        NotifyAddPoints(client, g_RankPoints.PointsEarnAssistVip, "Award Add Points Assist Vip");
    else
        NotifyAddPoints(client, g_RankPoints.PointsEarnAssist, "Award Add Points Assist");
}

void AwardPlayer_Mvp(int client)
{
    if (IsPlayerVip(client))
        NotifyAddPoints(client, g_RankPoints.PointsEarnMVPVip, "Award Add Points Mvp Vip");
    else
        NotifyAddPoints(client, g_RankPoints.PointsEarnMVP, "Award Add Points Mvp");
}

void AwardPlayer_BombPlanted(int client)
{
    if (IsPlayerVip(client))
        NotifyAddPoints(client, g_RankPoints.PointsEarnBombPlantedVip, "Award Add Points Bomb Planted Vip");
    else
        NotifyAddPoints(client, g_RankPoints.PointsEarnBombPlanted, "Award Add Points Bomb Planted");
}

void AwardPlayer_BombDefused(int client)
{
    if (IsPlayerVip(client))
        NotifyAddPoints(client, g_RankPoints.PointsEarnBombDefusedVip, "Award Add Points Bomb Defused Vip");
    else
        NotifyAddPoints(client, g_RankPoints.PointsEarnBombDefused, "Award Add Points Bomb Defused");
}

void AwardPlayer_WonRound(int client)
{
    if (IsPlayerVip(client))
        NotifyAddPoints(client, g_RankPoints.PointsEarnRoundWinVip, "Award Add Points Won Round Vip");
    else
        NotifyAddPoints(client, g_RankPoints.PointsEarnRoundWin, "Award Add Points Won Round");
}

void AwardPlayer_KnifeKill(int client)
{
    if (IsPlayerVip(client))
        NotifyAddPoints(client, g_RankPoints.PointsEarnKnifeKillVip, "Award Add Points Knife Kill Vip");
    else
        NotifyAddPoints(client, g_RankPoints.PointsEarnKnifeKill, "Award Add Points Knife Kill");
}

static void NotifyAddPoints(int client, int points, const char[] translation)
{
    AddPoints(client, points);
    CPrintToChat(client, "%s %t", g_ChatTag, translation, points);
}

static void NotifyRemovePoints(int client, int points, const char[] translation)
{
    RemovePoints(client, points);
    CPrintToChat(client, "%s %t", g_ChatTag, translation, points);
}