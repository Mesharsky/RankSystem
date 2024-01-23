/*	Copyright (C) 2023 ServerSquare.eu

    Author: Mesharsky
    Github: https://github.com/Mesharsky

    NOTE: Only MySQL Supported

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

void DatabaseConnect()
{
    char name[32];
    g_Cvar_DBName.GetString(name, sizeof(name));
    if (!Database_Init(name))
        SetFailState("[Rank System] Failed to connect to database: %s", name);

    PrintToServer("[Rank System] Connected to database: %s", name);
}

void Database_LoadMapData()
{
    char mapName[40];
    GetCurrentMap(mapName, sizeof(mapName));

    Transaction t = new Transaction();

    char query[512];
    g_DB.Format(query, sizeof(query), "INSERT INTO `map` (`name`) VALUES ('%s') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`)", mapName);
    t.AddQuery(query);

    g_DB.Format(query, sizeof(query), "INSERT INTO `match` (`map_id`, `start_time`, `end_time`, `winning_team`, `rounds_t`, `rounds_ct`) "
        ... "VALUES ((SELECT id FROM map WHERE name = '%s'), NOW(), 0, 'IN PROGRESS', 0, 0)", mapName);
    t.AddQuery(query);

    g_DB.Execute(t, LoadMapData_Success, OnInitFailed, 0, DBPrio_High);
}

void LoadMapData_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
    g_CurrentMatchId = results[1].InsertId;
}

bool Database_Init(const char[] databaseName)
{
    if (!SQL_CheckConfig(databaseName))
        SetFailState("[Rank System] Missing configuration key for database '%s'", databaseName);

    char error[512];
    g_DB = SQL_Connect(databaseName, false, error, sizeof(error));
    if (g_DB == null)
        return false;

    Transaction t = new Transaction();

    Tx_CreateTables(t);
    Tx_InsertWeaponsNames(t);

    g_DB.Execute(t, INVALID_FUNCTION, OnInitFailed, 0, DBPrio_High);
    g_DB.SetCharset("utf8mb4");

    return true;
}

Transaction Tx_CreateTables(Transaction tx=null)
{
    if (tx == null)
        tx = new Transaction();

    tx.AddQuery("CREATE TABLE IF NOT EXISTS `player` ("
        ... "`id` INT NOT NULL AUTO_INCREMENT,"
        ... "`steamid` VARCHAR(127) NOT NULL,"
        ... "`name` VARCHAR(127) NOT NULL,"
        ... "`last_connected` DATETIME NOT NULL,"
        ... "`is_connected` BOOL NOT NULL,"
        ... "UNIQUE KEY (`steamid`),"
        ... "PRIMARY KEY (`id`)"
        ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci");

    tx.AddQuery("CREATE TABLE IF NOT EXISTS `map` ("
        ... "`id` INT NOT NULL AUTO_INCREMENT,"
        ... "`name` VARCHAR(64) NOT NULL,"
        ... "PRIMARY KEY (`id`),"
        ... "UNIQUE (`name`)"
        ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci");


    tx.AddQuery("CREATE TABLE IF NOT EXISTS `weapon` ("
        ... "`id` INT NOT NULL AUTO_INCREMENT,"
        ... "`entity_name` VARCHAR(32) NOT NULL UNIQUE,"
        ... "`display_name` VARCHAR(32) NOT NULL,"
        ... "PRIMARY KEY (`id`)"
        ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci");


    tx.AddQuery("CREATE TABLE IF NOT EXISTS `match` ("
        ... "`id` INT NOT NULL AUTO_INCREMENT,"
        ... "`map_id` INT NOT NULL,"
        ... "`start_time` DATETIME NOT NULL,"
        ... "`end_time` DATETIME NOT NULL,"
        ... "`winning_team` VARCHAR(32) NOT NULL,"
        ... "`rounds_t` INT NOT NULL,"
        ... "`rounds_ct` INT NOT NULL,"
        ... "PRIMARY KEY (`id`),"
        ... "FOREIGN KEY (`map_id`) REFERENCES `map` (`id`)"
        ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci");

    tx.AddQuery("CREATE TABLE IF NOT EXISTS `kill` ("
        ... "`id` INT NOT NULL AUTO_INCREMENT,"
        ... "`match_id` INT NOT NULL,"
        ... "`attacker_id` INT NOT NULL,"
        ... "`victim_id` INT NOT NULL,"
        ... "`weapon_id` INT NOT NULL,"
        ... "`headshot` BOOL NOT NULL,"
        ... "`noscope` BOOL NOT NULL,"
        ... "`blind` BOOL NOT NULL,"
        ... "`through_smoke` BOOL NOT NULL,"
        ... "`through_wall` BOOL NOT NULL,"
        ... "`distance` FLOAT NOT NULL,"
        ... "`first_blood` BOOL NOT NULL,"
        ... "`total_damage` SMALLINT NOT NULL,"
        ... "`generic_damage` SMALLINT NOT NULL,"
        ... "`damage_head` SMALLINT NOT NULL,"
        ... "`damage_stomach` SMALLINT NOT NULL,"
        ... "`damage_chest` SMALLINT NOT NULL,"
        ... "`damage_left_arm` SMALLINT NOT NULL,"
        ... "`damage_right_arm` SMALLINT NOT NULL,"
        ... "`damage_left_leg` SMALLINT NOT NULL,"
        ... "`damage_right_leg` SMALLINT NOT NULL,"
        ... "PRIMARY KEY (`id`),"
        ... "FOREIGN KEY (`match_id`) REFERENCES `match` (`id`),"
        ... "FOREIGN KEY (`attacker_id`) REFERENCES `player` (`id`),"
        ... "FOREIGN KEY (`victim_id`) REFERENCES `player` (`id`),"
        ... "FOREIGN KEY (`weapon_id`) REFERENCES `weapon` (`id`)"
        ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci");

    tx.AddQuery("CREATE TABLE IF NOT EXISTS `rankdata` ("
        ... "`player_id` INT NOT NULL,"
        ... "`points` INT NOT NULL,"
        ... "`rankname` VARCHAR(64) NOT NULL,"    
        ... "`rank_index` INT NOT NULL,"
        ... "PRIMARY KEY (`player_id`),"
        ... "FOREIGN KEY (`player_id`) REFERENCES `player` (`id`)"
        ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci");

    tx.AddQuery("CREATE TABLE IF NOT EXISTS `match_player_data` ("
        ... "`id` INT NOT NULL AUTO_INCREMENT,"
        ... "`player_id` INT NOT NULL,"
        ... "`match_id` INT NOT NULL,"
        ... "`rounds_won` INT NOT NULL,"
        ... "`rounds_lost` INT NOT NULL,"
        ... "`score` INT NOT NULL,"
        ... "`suicides` INT NOT NULL,"
        ... "`shots` INT NOT NULL,"
        ... "`hits` INT NOT NULL,"
        ... "`c4_planted` INT NOT NULL,"
        ... "`c4_defused` INT NOT NULL,"
        ... "`assist` INT NOT NULL,"
        ... "`assist_flash` INT NOT NULL,"
        ... "`assist_team_kill` INT NOT NULL,"
        ... "`ct_win` INT NOT NULL,"
        ... "`tr_win` INT NOT NULL,"
        ... "`hostages_rescued` INT NOT NULL,"
        ... "`mvp` INT NOT NULL,"
        ... "PRIMARY KEY (`id`),"
        ... "UNIQUE KEY (`match_id`, `player_id`),"
        ... "FOREIGN KEY (`match_id`) REFERENCES `match` (`id`),"
        ... "FOREIGN KEY (`player_id`) REFERENCES `player` (`id`)"
        ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci");

    return tx;
}

Transaction Tx_InsertWeaponsNames(Transaction tx = null)
{
    Transaction t = tx;
    if (t == null)
        t = new Transaction();

    t.AddQuery("INSERT INTO `weapon` (`entity_name`, `display_name`) VALUES"
        ... "('unknown', 'Unknown Weapon'),"
        ... "('weapon_sawedoff', 'Sawed-Off'),"
        ... "('weapon_mag7', 'Mag-7'),"
        ... "('weapon_nova', 'Nova'),"
        ... "('weapon_xm1014', 'XM1014'),"
        ... "('weapon_mp7', 'MP7'),"
        ... "('weapon_mp9', 'MP9'),"
        ... "('weapon_ssg08', 'SSG 08 (Scout)'),"
        ... "('weapon_awp', 'AWP'),"
        ... "('weapon_famas', 'FAMAS'),"
        ... "('weapon_ump45', 'UMP-45'),"
        ... "('weapon_bizon', 'PP-Bizon'),"
        ... "('weapon_mac10', 'Mac-10'),"
        ... "('weapon_galilar', 'Galil AR'),"
        ... "('weapon_p90', 'P90'),"
        ... "('weapon_ak47', 'AK-47'),"
        ... "('weapon_m4a1_silencer', 'M4A1-S'),"
        ... "('weapon_m4a1', 'M4A4'),"
        ... "('weapon_sg556', 'SG 553'),"
        ... "('weapon_aug', 'AUG'),"
        ... "('weapon_m249', 'M249'),"
        ... "('weapon_negev', 'Negev'),"
        ... "('weapon_scar20', 'Scar-20'),"
        ... "('weapon_g3sg1', 'G3SG1'),"
        ... "('weapon_cz75a', 'CZ-75'),"
        ... "('weapon_usp_silencer', 'USP-S'),"
        ... "('weapon_usp_silencer_off', 'USP-S'),"
        ... "('weapon_deagle', 'Deagle'),"
        ... "('weapon_revolver', 'Revolver'),"
        ... "('weapon_glock', 'Glock'),"
        ... "('weapon_p250', 'P250'),"
        ... "('weapon_hkp2000', 'P2000'),"
        ... "('weapon_tec9', 'TEC-9'),"
        ... "('weapon_fiveseven', 'Five Seven'),"
        ... "('weapon_elite', 'Dual Elites'),"
        ... "('weapon_fists', 'Fist'),"
        ... "('weapon_axe', 'Axe'),"
        ... "('weapon_hammer', 'Hammer'),"
        ... "('weapon_spanner', 'Wrench'),"
        ... "('weapon_breachcharge', 'Breach Charge'),"
        ... "('weapon_bumpmine', 'Bump Mine'),"
        ... "('weapon_smokegrenade', 'Smoke Grenade'),"
        ... "('weapon_flashbang', 'Flashbang'),"
        ... "('weapon_molotov', 'Molotov'),"
        ... "('weapon_incgrenade', 'Incendiary Grenade'),"
        ... "('weapon_he', 'HE Grenade'),"
        ... "('weapon_decoy', 'Decoy Grenade'),"
        ... "('weapon_taser', 'Zeus'),"
        ... "('weapon_shield', 'Shield'),"
        ... "('weapon_knifegg', 'Golden Knife'),"
        ... "('weapon_knife_t', 'T Knife'),"
        ... "('weapon_knife', 'Knife')"
        ... "ON DUPLICATE KEY UPDATE `entity_name` = `entity_name`");

    return t;
}


void Database_LoadData(int client)
{
    char steamid2[MAX_AUTHID_LENGTH];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid2, sizeof(steamid2)))
    {
        LogError("[DB_LoadData] Couldn't get SteamID2 for client: %N", client);
        return;
    }

    char query[512];
    g_DB.Format(query, sizeof(query), "SELECT p.`name`, p.`last_connected`, r.`points`, r.`rankname` "
        ...	"FROM `player` p "
        ...	"JOIN `rankdata` r ON p.`id` = r.`player_id` "
        ...	"WHERE p.`steamid` = '%s'", steamid2);

    char name[MAX_NAME_LENGTH * 2 + 1];
    GetClientName(client, name, sizeof(name));

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteString(steamid2);
    pack.WriteString(name);

    g_DB.Query(LoadData_Callback, query, pack);
}

void LoadData_Callback(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    pack.Reset();

    char name[MAX_NAME_LENGTH];
    char steamid[MAX_AUTHID_LENGTH];

    int client = GetClientOfUserId(pack.ReadCell());
    pack.ReadString(steamid, sizeof(steamid));
    pack.ReadString(name, sizeof(name));

    delete pack;

    if (client == 0)
        return;

    if (db == null || results == null || error[0])
    {
        LogError("Could not load players data (error: %s)", error);
        return;
    }

    if (results.FetchRow())
    {
        DBResult res;
        g_PlayerTotalPoints[client] = results.FetchInt(2, res);
        if (res != DBVal_Data)
        {
            LogError("Failed to fetch player Points (result: %i)", res);
            return;
        }

        char updateQuery[512];
        g_DB.Format(updateQuery, sizeof(updateQuery), "UPDATE `player` SET `name` = '%s', `last_connected` = NOW(), `is_connected` = 1 WHERE `steamid` = '%s'", name, steamid);

        g_DB.Query(UpdateQuery_CallBack, updateQuery);
    }
    else
    {
        char playerQuery[512];
        g_DB.Format(playerQuery, sizeof(playerQuery), "INSERT INTO `player` ("
            ... "`steamid`,"
            ... "`name`,"
            ... "`last_connected`,"
            ... "`is_connected`)"
            ... " VALUES ('%s', '%s', NOW(), 1)"
            ... " ON DUPLICATE KEY UPDATE `name` = '%s', `last_connected` = NOW(), `is_connected` = 1",
            steamid,
            name,
            name);

        g_DB.Query(UpdateQuery_CallBack, playerQuery);
    }

    g_PlayerRankLevel[client] = CalculateRankByPoints(g_PlayerTotalPoints[client], g_PlayertotalPointsRequired[client]);
    Player_GetCurrentRankPosition(client);
    g_SessionPlayerMatchData[client].Reset();
    g_IsClientConnectedFull[client] = true;
}

void UpdateQuery_CallBack(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0])
    {
        LogError("Could not update players data (error: %s)", error);
        return;
    }
}

void Database_SaveData(int client)
{
    if (!CanGainPoints(client))
        return;

    if (!g_IsClientConnectedFull[client])
        return;

    char steamid2[MAX_AUTHID_LENGTH];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid2, sizeof(steamid2)))
    {
        LogError("[DB_SaveData] Couldn't get SteamID2 for client: %N", client);
        return;
    }

    char name[MAX_NAME_LENGTH * 2 + 1];
    GetClientName(client, name, sizeof(name));

    RankInfo info;
    int playerRankLevel = g_PlayerRankLevel[client];
    g_RankData.GetArray(playerRankLevel, info, sizeof(info));

    Transaction t = new Transaction();

    char playerQuery[512];
    g_DB.Format(playerQuery, sizeof(playerQuery), "INSERT INTO `player` ("
        ... "`steamid`,"
        ... "`name`)"
        ... " VALUES ('%s', '%s')"
        ... " ON DUPLICATE KEY UPDATE `name` = '%s'",
        steamid2,
        name,
        name);

    t.AddQuery(playerQuery);

    char rankDataQuery[512];
    g_DB.Format(rankDataQuery, sizeof(rankDataQuery), "INSERT INTO `rankdata` ("
        ... "`player_id`,"
        ... "`points`,"
        ... "`rankname`,"
        ... "`rank_index`)"
        ... " VALUES ((SELECT `id` FROM `player` WHERE `steamid` = '%s'), %i, '%s', %i)"
        ... " ON DUPLICATE KEY UPDATE `points` = %i, `rankname` = '%s', `rank_index` = %i",
        steamid2,
        g_PlayerTotalPoints[client],
        info.rankName,
        playerRankLevel,
        g_PlayerTotalPoints[client],
        info.rankName,
        playerRankLevel);

    t.AddQuery(rankDataQuery);

    // Player is not connected anymore, set is_connected to 0
    char updateQuery[256];
    g_DB.Format(updateQuery, sizeof(updateQuery),
        "UPDATE `player` SET `is_connected` = 0 WHERE `steamid` = '%s'", 
        steamid2);

    t.AddQuery(updateQuery);

    SQL_ExecuteTransaction(g_DB, t, INVALID_FUNCTION, OnInitFailed, 0, DBPrio_High);
    g_DB.SetCharset("utf8mb4");

    ResetGlobalVariables(client);
}

void OnInitFailed(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    SetFailState("Database query failed. Error: %s", error);
}

void Database_InsertKill(
    int attacker,
    int victim,
    const char[] weapon,
    bool isHeadshot,
    bool isNoscope,
    bool isThroughSmoke,
    bool isBlindKill,
    int objectsPenetrated,
    float killDistance,
    bool isFirstBlood)
{
    char attackerSteamID[MAX_AUTHID_LENGTH];
    char victimSteamID[MAX_AUTHID_LENGTH];

    if (!GetClientAuthId(attacker, AuthId_Steam2, attackerSteamID, sizeof(attackerSteamID)))
    {
        LogError("Could not save kill for %L. Failed to get SteamID2 for attacker,", attacker);
        return;
    }

    if (!GetClientAuthId(victim, AuthId_Steam2, victimSteamID, sizeof(victimSteamID)))
    {
        LogError("Could not save kill for %L. Failed to get SteamID2 for victim: %L", attacker, victim);
        return;
    }

    char fullWeaponName[MAX_WEAPON_CLASSNAME_SIZE];
    FormatEx(fullWeaponName, sizeof(fullWeaponName), "weapon_%s", weapon);

    char query[1024];
    g_DB.Format(query, sizeof(query),
        "INSERT INTO `kill` ("
            ... "`match_id`,"
            ... "`attacker_id`,"
            ... "`victim_id`,"
            ... "`weapon_id`,"
            ... "`headshot`,"
            ... "`noscope`,"
            ... "`blind`,"
            ... "`through_smoke`,"
            ... "`through_wall`,"
            ... "`distance`,"
            ... "`first_blood`,"
            ... "`total_damage`,"
            ... "`generic_damage`,"
            ... "`damage_head`,"
            ... "`damage_stomach`,"
            ... "`damage_chest`,"
            ... "`damage_left_arm`,"
            ... "`damage_right_arm`,"
            ... "`damage_left_leg`,"
            ... "`damage_right_leg`"
        ... ") SELECT "
            ... "%d,"
            ... "attacker.`id`,"
            ... "victim.`id`,"
            ... "COALESCE((SELECT `id` FROM `weapon` WHERE `entity_name` = '%s'), 1),"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%f,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d,"
            ... "%d"
        ... " FROM `player` AS attacker, `player` AS victim "
        ... " WHERE attacker.`steamid` = '%s' AND victim.`steamid` = '%s'",
        g_CurrentMatchId,
        fullWeaponName,
        isHeadshot,
        isNoscope,
        isBlindKill,
        isThroughSmoke,
        objectsPenetrated > 0,
        killDistance,
        isFirstBlood,
        g_Damage[attacker][victim].Total(),
        g_Damage[attacker][victim].generic,
        g_Damage[attacker][victim].head,
        g_Damage[attacker][victim].stomach,
        g_Damage[attacker][victim].chest,
        g_Damage[attacker][victim].left_arm,
        g_Damage[attacker][victim].right_arm,
        g_Damage[attacker][victim].left_leg,
        g_Damage[attacker][victim].right_leg,
        attackerSteamID,
        victimSteamID);

    ResetDamageData(victim);

    g_DB.Query(OnInsertKill, query);
}

void OnInsertKill(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0])
    {
        LogError("Could not insert kill (error: %s)", error);
        return;
    }
}

void Database_OnMapEnd()
{
    char winningTeam[64];

    if (g_MatchData.tRounds == g_MatchData.ctRounds)
        FormatEx(winningTeam, sizeof(winningTeam), "DRAW");
    else 
        FormatEx(winningTeam, sizeof(winningTeam), g_MatchData.ctRounds > g_MatchData.tRounds ? "Counter Terrorists" : "Terrorists");

    Transaction t = new Transaction();

    char matchData[1024];
    g_DB.Format(matchData, sizeof(matchData), "UPDATE `match` SET `end_time` = NOW(), `winning_team` = '%s', `rounds_t` = %d, `rounds_ct` = %d WHERE `id` = %d",
        winningTeam, g_MatchData.tRounds, g_MatchData.ctRounds, g_CurrentMatchId);

    t.AddQuery(matchData);

    g_DB.Execute(t, INVALID_FUNCTION, OnInitFailed, 0, DBPrio_High);

    g_MatchData.Reset();

    // WE NEED TO SAVE BEFORE RESETING
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        
        Database_SaveMatchPlayerData(i);
    }
}

void Database_SaveMatchPlayerData(int client)
{
    if (!CanGainPoints(client))
        return;

    char steamid2[MAX_AUTHID_LENGTH];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid2, sizeof(steamid2)))
    {
        LogError("Could not save Match player data for %L. Failed to get SteamID2 for client,", client);
        return;
    }

    char query[2056];
    g_DB.Format(query, sizeof(query), "INSERT INTO `match_player_data` ("
        ... "`player_id`,"
        ... "`match_id`,"
        ... "`rounds_won`,"
        ... "`rounds_lost`,"
        ... "`score`,"
        ... "`suicides`,"
        ... "`shots`,"
        ... "`hits`,"
        ... "`c4_planted`,"
        ... "`c4_defused`,"
        ... "`assist`,"
        ... "`assist_flash`,"
        ... "`assist_team_kill`,"
        ... "`ct_win`,"
        ... "`tr_win`,"
        ... "`hostages_rescued`,"
        ... "`mvp`)"
        ... " VALUES ((SELECT `id` FROM `player` WHERE `steamid` = '%s'),"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i,"
            ... "%i)"
        ... " ON DUPLICATE KEY UPDATE "
            ... "`rounds_won` = `rounds_won` + %i,"
            ... "`rounds_lost` = `rounds_lost` + %i,"
            ... "`score` = `score` + %i,"
            ... "`suicides` = `suicides` + %i,"
            ... "`shots` = `shots` + %i,"
            ... "`hits` = `hits` + %i,"
            ... "`c4_planted` = `c4_planted` + %i,"
            ... "`c4_defused` = `c4_defused` + %i,"
            ... "`assist` = `assist` + %i,"
            ... "`assist_flash` = `assist_flash` + %i,"
            ... "`assist_team_kill` = `assist_team_kill` + %i,"
            ... "`ct_win` = `ct_win` + %i,"
            ... "`tr_win` = `tr_win` + %i,"
            ... "`hostages_rescued` = `hostages_rescued` + %i,"
            ... "`mvp` = `mvp` + %i",
        steamid2,
        g_CurrentMatchId,
        g_MatchPlayerData[client].roundsWon,
        g_MatchPlayerData[client].roundsLost,
        g_MatchPlayerData[client].playerScore,
        g_MatchPlayerData[client].playerSuicides,
        g_MatchPlayerData[client].playerShots,
        g_MatchPlayerData[client].playerHits,
        g_MatchPlayerData[client].bombPlanted,
        g_MatchPlayerData[client].bombDefused,
        g_MatchPlayerData[client].playerAssists,
        g_MatchPlayerData[client].playerAssistsFlash,
        g_MatchPlayerData[client].playerAssistsTeamKill,
        g_MatchPlayerData[client].playerWinsCtSide,
        g_MatchPlayerData[client].playerWinsTSide,
        g_MatchPlayerData[client].hostagesRescued,
        g_MatchPlayerData[client].playerMvp,
        // Additional params for the ON DUPLICATE KEY UPDATE
        g_MatchPlayerData[client].roundsWon,
        g_MatchPlayerData[client].roundsLost,
        g_MatchPlayerData[client].playerScore,
        g_MatchPlayerData[client].playerSuicides,
        g_MatchPlayerData[client].playerShots,
        g_MatchPlayerData[client].playerHits,
        g_MatchPlayerData[client].bombPlanted,
        g_MatchPlayerData[client].bombDefused,
        g_MatchPlayerData[client].playerAssists,
        g_MatchPlayerData[client].playerAssistsFlash,
        g_MatchPlayerData[client].playerAssistsTeamKill,
        g_MatchPlayerData[client].playerWinsCtSide,
        g_MatchPlayerData[client].playerWinsTSide,
        g_MatchPlayerData[client].hostagesRescued,
        g_MatchPlayerData[client].playerMvp);

    g_MatchPlayerData[client].Reset();
    g_DB.Query(OnSaveMatchPlayerData, query);
}

void OnSaveMatchPlayerData(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0])
    {
        LogError("Could not insert MatchPlayerData (error: %s)", error);
        return;
    }
}

void Player_GetCurrentRankPosition(int client)
{
    if (!CanGainPoints(client))
    {
        LogError("Can't get current rank position for player: `%L`", client);
        return;
    }

    char steamid2[MAX_AUTHID_LENGTH];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid2, sizeof(steamid2)))
    {
        LogError("Could not get player rank position for %L. Failed to get SteamID2 for client,", client);
        return;
    }

    char query[2048];
    g_DB.Format(query, sizeof(query),
        "SELECT PlayerStats.player_id, PlayerStats.kills, PlayerStats.deaths, PlayerStats.normalized_kdr, "
        ... "(SELECT COUNT(*) + 1 FROM ("
        ... "SELECT attacker_id, "
        ... "COUNT(DISTINCT id) AS kills, "
        ... "COALESCE((SELECT COUNT(DISTINCT id) FROM `kill` WHERE victim_id = k.attacker_id), 0) AS deaths, "
        ... "CAST(COUNT(DISTINCT id) AS DECIMAL(10,2)) / GREATEST(COALESCE((SELECT COUNT(DISTINCT id) FROM `kill` WHERE victim_id = k.attacker_id), 0), 10) AS inner_normalized_kdr "
        ... "FROM `kill` k "
        ... "GROUP BY attacker_id"
        ... ") temp "
        ... "WHERE temp.inner_normalized_kdr > PlayerStats.normalized_kdr OR (temp.inner_normalized_kdr = PlayerStats.normalized_kdr AND temp.deaths < PlayerStats.deaths) OR (temp.inner_normalized_kdr = PlayerStats.normalized_kdr AND temp.deaths = PlayerStats.deaths AND temp.attacker_id < PlayerStats.player_id)) AS rank "
        ... "FROM ("
        ... "SELECT attacker_id AS player_id, "
        ... "COUNT(DISTINCT id) AS kills, "
        ... "COALESCE((SELECT COUNT(DISTINCT id) FROM `kill` WHERE victim_id = k.attacker_id), 0) as deaths, "
        ... "CAST(COUNT(DISTINCT id) AS DECIMAL(10,2)) / GREATEST(COALESCE((SELECT COUNT(DISTINCT id) FROM `kill` WHERE victim_id = k.attacker_id), 0), 10) AS normalized_kdr "
        ... "FROM `kill` k "
        ... "GROUP BY attacker_id "
        ... ") AS PlayerStats "
        ... "WHERE player_id = (SELECT `id` FROM `player` WHERE `steamid` = '%s');", steamid2);


    g_DB.Query(OnGetCurrentRankPosition, query, GetClientUserId(client));
}

void OnGetCurrentRankPosition(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    
    if (client == 0)
        return;

    if (db == null || results == null || error[0])
    {
        LogError("Could not get current rank position for player (error: %s)", error);
        return;
    }

    if (results.FetchRow())
    {
        DBResult res;
        int rank = results.FetchInt(4, res); // 4 for the rank column

        if (res != DBVal_Data)
        {
            LogError("Failed to fetch rank for player: `%L` (result: %i)", client, res);
            return;
        }

        g_PlayerRankPosition[client] = rank;
    }
    else
    {
        g_PlayerRankPosition[client] = 99999;
        LogMessage("No rank data found for player: `%L`", client);
        return;
    }
}

void GetPlayerCurrentSessionStats(int client)
{
    if (!CanGainPoints(client))
    {
        LogError("Can't get current session stats for player: `%L`", client);
        return;
    }

    char steamid2[MAX_AUTHID_LENGTH];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid2, sizeof(steamid2)))
    {
        LogError("Could not get current session stats for player: %L. Failed to get SteamID2 for client,", client);
        return;
    }

    char query[5000];
    g_DB.Format(query, sizeof(query), "SELECT "
        ... "SUM(CASE WHEN k.attacker_id = p.id THEN 1 ELSE 0 END) AS playerKills, "
        ... "SUM(CASE WHEN k.victim_id = p.id THEN 1 ELSE 0 END) AS playerDeaths, "
        ... "SUM(CASE WHEN k.attacker_id = p.id THEN k.headshot ELSE 0 END) AS playerHeadshots, "
        ... "SUM(CASE WHEN k.attacker_id = p.id THEN k.noscope ELSE 0 END) AS playerNoScopes, "
        ... "SUM(CASE WHEN k.attacker_id = p.id THEN k.blind ELSE 0 END) AS playerBlindKills, "
        ... "SUM(CASE WHEN k.attacker_id = p.id THEN k.through_smoke ELSE 0 END) AS playerSmokeKills, "
        ... "SUM(CASE WHEN k.attacker_id = p.id THEN k.through_wall ELSE 0 END) AS playerWallKills, "
        ... "MAX(CASE WHEN k.attacker_id = p.id THEN k.distance ELSE 0 END) AS longestDistanceKill, "
        ... "SUM(CASE WHEN k.attacker_id = p.id THEN k.first_blood ELSE 0 END) AS firstBloods, "
        ... "SUM(CASE WHEN k.attacker_id = p.id THEN k.total_damage ELSE 0 END) AS totalDamage "
        ... "FROM `kill` k "
        ... "JOIN `player` p ON p.steamid = '%s' "
        ... "WHERE k.match_id = %d AND "
        ... "(k.attacker_id = p.id OR k.victim_id = p.id)",
        steamid2, g_CurrentMatchId);

    g_DB.Query(OnGetAllSessionPlayerStats, query, GetClientUserId(client));
}

void OnGetAllSessionPlayerStats(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientOfUserId(data);
    if (client == 0)
        return;

    if (db == null || results == null || error[0])
    {
        LogError("Could not get player stats (error: %s)", error);
        return;
    }

    if (results.FetchRow())
    {
        g_SessionPlayerMatchData[client].playerKills = results.FetchInt(0);
        g_SessionPlayerMatchData[client].playerDeaths = results.FetchInt(1);
        g_SessionPlayerMatchData[client].playerHeadshots = results.FetchInt(2);
        g_SessionPlayerMatchData[client].playerNoScopes = results.FetchInt(3);
        g_SessionPlayerMatchData[client].playerBlindKills = results.FetchInt(4);
        g_SessionPlayerMatchData[client].playerSmokeKills = results.FetchInt(5);
        g_SessionPlayerMatchData[client].playerWallKills = results.FetchInt(6);
        g_SessionPlayerMatchData[client].longestDistanceKill = results.FetchFloat(7);
        g_SessionPlayerMatchData[client].firstBloods = results.FetchInt(8);
        g_SessionPlayerMatchData[client].totalDamage = results.FetchInt(9);
    }
    else
    {
        LogError("FAILED OnGetAllSessionPlayerStats, error: %s", error);
        return;
    }
}

