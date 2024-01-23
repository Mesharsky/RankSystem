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

#define MAX_WEAPON_CLASSNAME_SIZE 32

#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7
#define HITGROUP_UNKNOWN   8

enum struct DamageData
{
	int generic;
	int head;
	int chest;
	int stomach;
	int left_arm;
	int right_arm;
	int left_leg;
	int right_leg;

	int Total()
	{
		int total;

		total += this.generic;
		total += this.head;
		total += this.chest;
		total += this.stomach;
		total += this.left_arm;
		total += this.right_arm;
		total += this.left_leg;
		total += this.right_leg;

		return total;
	}

	void Reset()
	{
		this.generic = 0;
		this.head = 0;
		this.chest = 0;
		this.stomach = 0;
		this.left_arm = 0;
		this.right_arm = 0;
		this.left_leg = 0;
		this.right_leg = 0;
	}
}

DamageData g_Damage[MAXPLAYERS + 1][MAXPLAYERS + 1]; // Maps damage dealt from from client X to client Y

static bool g_isFirstBlood;

void Event_PlayerHurt(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;
	
	if (IsWarmup())
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int attackerDamage = event.GetInt("dmg_health");
	int hitgroup = event.GetInt("hitgroup");

	if (attacker == 0 || attacker == victim)
        return;

	if (victim == 0 || IsFakeClient(victim))
		return;

	if (ClientsAreTeammates(attacker, victim))
        return;
	
	if (hitgroup == HITGROUP_UNKNOWN)
		hitgroup = HITGROUP_GENERIC;

	g_MatchPlayerData[attacker].playerHits++;

	switch (hitgroup)
	{
		case HITGROUP_GENERIC:  g_Damage[attacker][victim].generic += attackerDamage;
		case HITGROUP_HEAD:     g_Damage[attacker][victim].head += attackerDamage;
		case HITGROUP_CHEST:    g_Damage[attacker][victim].chest += attackerDamage;
		case HITGROUP_STOMACH:  g_Damage[attacker][victim].stomach += attackerDamage;
		case HITGROUP_LEFTARM:  g_Damage[attacker][victim].left_arm += attackerDamage;
		case HITGROUP_RIGHTARM: g_Damage[attacker][victim].right_arm += attackerDamage;
		case HITGROUP_LEFTLEG:  g_Damage[attacker][victim].left_leg += attackerDamage;
		case HITGROUP_RIGHTLEG: g_Damage[attacker][victim].right_leg += attackerDamage;
	}
}

void Event_WeaponFire(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;

	if (IsWarmup())
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	char weapon[MAX_WEAPON_CLASSNAME_SIZE];
	event.GetString("weapon", weapon, sizeof(weapon));

	if (!IsClientInGame(client) || IsFakeClient(client))
		return;
	
	if (IsWeaponKnife(weapon) || IsWeaponGrenade(weapon))
		return;

	g_MatchPlayerData[client].playerShots++;
}

void Event_PlayerDeath(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;
		
	if (IsWarmup())
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int assister = GetClientOfUserId(event.GetInt("assister"));

	bool headshot = event.GetBool("headshot", false);
	bool noscope = event.GetBool("noscope", false);
	bool smokeKill = event.GetBool("thrusmoke", false);
	bool blindKill = event.GetBool("attackerblind", false);
	bool flashAssist = event.GetBool("assistedflash", false);
	bool firstBlood;

	int objectsPenetrated = event.GetInt("penetrated");
	float distance = event.GetFloat("distance");

	char weapon[MAX_WEAPON_CLASSNAME_SIZE];
	event.GetString("weapon", weapon, sizeof(weapon));

	// Assist team kill
	if (assister)
	{
		AwardPlayer_Assist(assister);
		g_MatchPlayerData[assister].playerAssists++;

		if (GetClientTeam(victim) == GetClientTeam(assister))
		{
			if (flashAssist)
				g_MatchPlayerData[assister].playerAssistsTeamKill++;
		}
		else
		{
			if (flashAssist)
				g_MatchPlayerData[assister].playerAssistsFlash++;
		}
	}

	if (!g_isFirstBlood)
		firstBlood = true;
	else
		firstBlood = false;

	// Suicide
	if (victim == attacker || attacker == 0)
		g_MatchPlayerData[victim].playerSuicides++;

	if (attacker == 0 || attacker == victim)
		return;

	// If player is bot
	if (victim == 0 || IsFakeClient(victim))
		return;

	if (ClientsAreTeammates(attacker, victim))
        return;

	if (headshot)
		AwardPlayer_Headshot(attacker);
	else
		AwardPlayer_Kill(attacker, victim);

	if (IsWeaponKnife(weapon))
		AwardPlayer_KnifeKill(attacker);

	Database_InsertKill(attacker, victim, weapon, headshot, noscope, smokeKill, blindKill, objectsPenetrated, distance, firstBlood);

	g_isFirstBlood = true;
}

void Event_RoundMvp(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;
		
	if (IsWarmup())
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0)
		return;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	g_MatchPlayerData[client].playerMvp++;
	AwardPlayer_Mvp(client);
}

void Event_BombPlanted(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;
		
	if (IsWarmup())
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0)
		return;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	g_MatchPlayerData[client].bombPlanted++;
	AwardPlayer_BombPlanted(client);
}

void Event_BombDefused(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;
		
	if (IsWarmup())
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0)
		return;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	g_MatchPlayerData[client].bombDefused++;
	AwardPlayer_BombDefused(client);
}

void Event_HostageRescued(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;
		
	if (IsWarmup())
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0)
		return;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	g_MatchPlayerData[client].hostagesRescued++;
}

void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;
		
	if (IsWarmup())
		return;

	g_isFirstBlood = false;
}

void Event_RoundEnd(Event event, const char[] name, bool bDontBroadcast)
{
	if (!IsMinimumPlayersAvailable())
		return;
		
	if (IsWarmup())
		return;

	int winningTeam = GetEventInt(event, "winner");
 
	MatchData_RoundEnd(winningTeam);
	MatchPlayerData_RoundEnd(winningTeam);
}

void MatchData_RoundEnd(int winningTeam)
{
	if (winningTeam == CS_TEAM_CT)
		g_MatchData.ctRounds++;
	else if (winningTeam == CS_TEAM_T)
		g_MatchData.tRounds++;
}

void MatchPlayerData_RoundEnd(int winningTeam)
{
	for	(int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		int score = CS_GetClientContributionScore(i);

		g_MatchPlayerData[i].playerScore = score;

		if (GetClientTeam(i) == winningTeam)
		{
			g_MatchPlayerData[i].roundsWon++;
			AwardPlayer_WonRound(i);
			
			switch (winningTeam)
			{
				case CS_TEAM_CT:
					g_MatchPlayerData[i].playerWinsCtSide++;
				case CS_TEAM_T:
					g_MatchPlayerData[i].playerWinsTSide++;
			}
		}
		else
			g_MatchPlayerData[i].roundsLost++;	
	}
}

void ResetDamageData(int client)
{
    for (int i = 0; i < sizeof(g_Damage[]); ++i)
       g_Damage[client][i].Reset();
}