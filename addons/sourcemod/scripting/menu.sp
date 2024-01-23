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

public Action Command_RankMainMenu(int client, int args)
{
	Menu menu = new Menu(MenuHandler_RankMain, MENU_ACTIONS_ALL);
	menu.Pagination = true;

	char display[64];

	FormatEx(display, sizeof(display), "%T", "Main Menu Scoreboard Ranks", client);
	menu.AddItem("scoreboard-ranks", display);
	FormatEx(display, sizeof(display), "%T", "Main Menu Ranks", client);
	menu.AddItem("ranks", display);

	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int MenuHandler_RankMain(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Cancel: {}
		case MenuAction_DrawItem: {}
		case MenuAction_DisplayItem: {}
		case MenuAction_Display:
        {
			RankInfo info;

			int len = g_RankData.Length;
			int playerRankLevel = g_PlayerRankLevel[param1];

			if (playerRankLevel >= 0 && playerRankLevel < len)
				g_RankData.GetArray(playerRankLevel, info, sizeof(info));

			char name[MAX_NAME_LENGTH];
			GetClientName(param1, name, sizeof(name));

			char buffer[1024];
			FormatEx(buffer, sizeof(buffer), "%T", IsPlayerVip(param1) ? "Main Menu Title Vip" : "Main Menu Title", param1, name, "\n", "\n", "\n", info.rankName, "\n", g_PlayerTotalPoints[param1], "\n", g_PlayertotalPointsRequired[param1], "\n");

			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
        }

		case MenuAction_Select:
        {
			char info[64];
			menu.GetItem(param2, info, sizeof(info));

			if (StrEqual(info, "scoreboard-ranks"))
				Menu_OpenScoreboardRankMain(param1);
			else if (StrEqual(info, "ranks"))
				Menu_OpenRanksMain(param1);
        }
	}

	return 0;
}

void Menu_OpenScoreboardRankMain(int client)
{
	Menu menu = new Menu(MenuHandler_ScoreboardMain, MENU_ACTIONS_ALL);
	menu.Pagination = true;
	menu.ExitBackButton = true;

	menu.AddItem("scoreboard-top", "Przejdź do ➛ TOP Graczy");
	menu.AddItem("scoreboard-info", "Przejdź do ➛ Informacje o rangach");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ScoreboardMain(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
                Command_RankMainMenu(param1, 0);
        }
		case MenuAction_Display:
        {
			char name[MAX_NAME_LENGTH];
			GetClientName(param1, name, sizeof(name));

			char buffer[512];
			FormatEx(buffer, sizeof(buffer), "Witaj, %s\n❢◥ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ ◤❢\nWybierz jedną z poniższych opcji:\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", name);

			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
        }

		case MenuAction_Select:
        {
			char info[64];
			menu.GetItem(param2, info, sizeof(info));

			if (StrEqual(info, "scoreboard-top"))
			{
				char query[1024];
				g_DB.Format(query, sizeof(query), "SELECT p.`id` AS player_id, p.`name`, r.`points`, r.`rankname`"
					... " FROM `player` p"
					... " JOIN `rankdata` r ON p.`id` = r.`player_id`"
					... " ORDER BY r.`points` DESC"
					... " LIMIT 100");

				g_DB.Query(MenuScoreBoardTop_CallBack, query, GetClientUserId(param1));
			}
			else if (StrEqual(info, "scoreboard-info"))
			{
				MenuScoreBoardRankInfo_CallBack(param1);
			}
        }
	}

	return 0;
}

void MenuScoreBoardTop_CallBack(Database db, DBResultSet results, const char[] error, any data)
{
	int playerIndex = GetClientOfUserId(data);
	if (playerIndex == 0)
		return;
	
	Menu menu = new Menu(MenuScoreBoardTop_Handler, MENU_ACTIONS_ALL);

	menu.Pagination = true;
	menu.ExitBackButton = true;

	if (db == null || results == null || error[0])
	{
		menu.AddItem("null", "ERROR WITH GETTING TOP PLAYERS");
		LogError("Could not get top players (error: %s)", error);
		menu.Display(playerIndex, MENU_TIME_FOREVER);
		return;
	}

	if (!results.RowCount)
	{
		menu.AddItem("null", "No players found in the top list.");
		menu.Display(playerIndex, MENU_TIME_FOREVER);
		return;
	}

	int count = 0;
	// Loop through the results and add each player to the menu
	while (results.FetchRow())
	{
		count++;
		int playerID = results.FetchInt(0);  // 0 for player_id
		
		char playerName[MAX_NAME_LENGTH];
		results.FetchString(1, playerName, sizeof(playerName));  // 1 for name
		
		// Truncate the playerName to a maximum of 16 characters
		char truncatedName[17];  // 16 characters + 1 for null terminator
		TruncateString(playerName, truncatedName, sizeof(truncatedName), "..", false);

		char rankName[65];
		results.FetchString(3, rankName, sizeof(rankName));  // 3 for rankname
		int rankPoints = results.FetchInt(2);  // 2 for points

		char sBuffer[16];
		IntToString(playerID, sBuffer, sizeof(sBuffer));

		char display[255];
		FormatEx(display, sizeof(display), "#%i - %s - %s - %i", count, truncatedName, rankName, rankPoints);
		
		menu.AddItem(sBuffer, display);
	}

	menu.Display(playerIndex, MENU_TIME_FOREVER);
}

public int MenuScoreBoardTop_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
                Menu_OpenScoreboardRankMain(param1);
        }
		case MenuAction_Display:
        {
			char buffer[1024];
			FormatEx(buffer, sizeof(buffer), "Top graczy - Rangi\n❢◥ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ ◤❢\nWybierz gracza aby uzyskać więcej informacji\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");

			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
        }

		case MenuAction_Select:
        {
			char info[64];
			menu.GetItem(param2, info, sizeof(info));

			int PlayerID = StringToInt(info);

			DataPack pack = new DataPack();

			pack.WriteCell(PlayerID);
			pack.WriteCell(GetClientUserId(param1));

			char query[4096];
			g_DB.Format(query, sizeof(query), 
				"SELECT "
				... "p.name AS playerName, "
				... "p.last_connected AS lastConnected, "
				... "r.rankname AS rankName, "
				... "r.points AS rankPoints "
				... "FROM `player` p "
				... "JOIN `rankdata` r ON p.id = r.player_id "
				... "WHERE p.id = %d", 
				PlayerID);
			g_DB.Query(Pre_ViewPlayer_CallBack, query, pack);
        }
	}

	return 0;
}

void Pre_ViewPlayer_CallBack(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();

	int PlayerID = pack.ReadCell();
	int client = GetClientOfUserId(pack.ReadCell());

	delete pack;

	if (db == null || results == null || error[0])
	{
		LogError("There was an error during the query (error: %s)", error);
		return;
	}

	if (!results.RowCount)
		return;

	while (results.FetchRow())
	{
		char playerName[MAX_NAME_LENGTH];
		results.FetchString(0, playerName, sizeof(playerName));  // 0 for playerName

		char lastConnected[64];
		results.FetchString(1, lastConnected, sizeof(lastConnected));  // 1 for lastConnected
		
		char rankName[65];
		results.FetchString(2, rankName, sizeof(rankName));  // 2 for rankName

		int rankPoints = results.FetchInt(3);  // 3 for rankPoints

		char truncatedName[19];  // 18 characters + 1 for null terminator
		TruncateString(playerName, truncatedName, sizeof(truncatedName), "", false);

		DataPack pck = new DataPack();

		pck.WriteCell(GetClientUserId(client));
		pck.WriteString(playerName);
		pck.WriteString(lastConnected);
		pck.WriteString(rankName);
		pck.WriteCell(rankPoints);

		char query[4096];

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
		... "WHERE player_id = (SELECT `id` FROM `player` WHERE `id` = '%i');", PlayerID);
		g_DB.Query(ViewPlayer_CallBack, query, pck);
	}
}

void ViewPlayer_CallBack(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();

	int client = GetClientOfUserId(pack.ReadCell());
	char playerName[MAX_NAME_LENGTH];
	pack.ReadString(playerName, sizeof(playerName));
	char lastConnected[64];
	pack.ReadString(lastConnected, sizeof(lastConnected));
	char rankName[65];
	pack.ReadString(rankName, sizeof(rankName));
	int rankPoints = pack.ReadCell();

	delete pack;

	char display[512];

	char truncatedName[19];  // 18 characters + 1 for null terminator
	TruncateString(playerName, truncatedName, sizeof(truncatedName), "", false);

	Menu menu = new Menu(MenuViewPlayer_CallBack, MENU_ACTIONS_ALL);
	menu.SetTitle("TESTTTTTTTT");

	menu.Pagination = true;
	menu.ExitBackButton = true;

	if (db == null || results == null || error[0])
	{
		menu.AddItem("null", "ERROR WITH GETTING STATS FOR PLAYER");
		LogError("There was an error during the query (error: %s)", error);
		menu.Display(client, MENU_TIME_FOREVER);
		return;
	}

	if (!results.RowCount)
	{
		Format(display, sizeof(display), "Przeglądasz gracza: %s\nOstatnie Połączenie: %s\nMiejsce w rankingu: BRAK\nRanga: %s - Punkty: %i\n", 
				truncatedName, lastConnected, rankName, rankPoints);
		menu.AddItem("null", display);
		menu.Display(client, MENU_TIME_FOREVER);
		return;
	}

	while (results.FetchRow())
	{
		DBResult res;
		int rank = results.FetchInt(4, res);
		if (res != DBVal_Data)
        {
            LogError("Failed to fetch rank for player %s (result: %i)", playerName, res);
            return;
        }
		Format(display, sizeof(display), "Przeglądasz gracza: %s\nOstatnie Połączenie: %s\nMiejsce w rankingu: %i\nRanga: %s - Punkty: %i\n", 
				truncatedName, lastConnected, rank, rankName, rankPoints);
		
		menu.AddItem("none", display);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}


public int MenuViewPlayer_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
        {
            delete menu;
        }

		case MenuAction_Select:
        {
			
        }
	}

	return 0;
}

void MenuScoreBoardRankInfo_CallBack(int client)
{
	Menu menu = new Menu(MenuScoreBoardRankInfo_Handler, MENU_ACTIONS_ALL);

	menu.Pagination = true;
	menu.ExitBackButton = true;

	RankInfo info;
	int len = g_RankData.Length;

	for	(int i = 0; i < len; ++i)
	{
		g_RankData.GetArray(i, info, sizeof(info));

		char sBuffer[256];
		FormatEx(sBuffer, sizeof(sBuffer), "%s - %i", info.rankName, info.totalPointsRequired);

		char index[32];
		IntToString(i, index, sizeof(index));

		menu.AddItem(index, sBuffer);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuScoreBoardRankInfo_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
                Menu_OpenScoreboardRankMain(param1);
        }
		case MenuAction_Display:
        {
			char buffer[512];
			FormatEx(buffer, sizeof(buffer), "Rangi - System Punktacji\n❢◥ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ ◤❢\nFormat: Ranga - Ilość punktów potrzebnych by ją uzyskać\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");

			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
        }

		case MenuAction_Select:
        {
			
        }
	}

	return 0;
}

void Menu_OpenRanksMain(int client)
{
	Menu menu = new Menu(MenuHandler_RanksMain, MENU_ACTIONS_ALL);

	menu.AddItem("ranks-top", "Przejdź do ➛ TOP Graczy (KDR)");
	menu.AddItem("ranks-session-stats", "Przejdź do ➛ Twoje Statystyki - Ten Mecz");
	menu.AddItem("ranks-player-stats", "Przejdź do ➛ Twoje Statystyki - Ogólnie");

	GetPlayerCurrentSessionStats(client);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_RanksMain(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
                Command_RankMainMenu(param1, 0);
        }
		case MenuAction_Display:
        {
			Player_GetCurrentRankPosition(param1);
			char name[MAX_NAME_LENGTH];
			GetClientName(param1, name, sizeof(name));

			int rankPosition = g_PlayerRankPosition[param1];

			char buffer[512];
			if (rankPosition != 99999)
				FormatEx(buffer, sizeof(buffer), "Witaj, %s\nTwoja pozycja w rankingu to: %i\n❢◥ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ ◤❢\nWybierz jedną z poniższych opcji:\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", name, rankPosition);
			else
				FormatEx(buffer, sizeof(buffer), "Witaj, %s\nTwoja pozycja w rankingu to: BRAK\n❢◥ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ ◤❢\nWybierz jedną z poniższych opcji:\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", name);

			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
        }

		case MenuAction_Select:
        {
			char info[64];
			menu.GetItem(param2, info, sizeof(info));

			char query[4096];

			if (StrEqual(info, "ranks-top"))
			{
				g_DB.Format(query, sizeof(query), 
					"SELECT PlayerStats.player_id, p.`name`, PlayerStats.kills, PlayerStats.deaths, PlayerStats.normalized_kdr "
					... "FROM ("
					... " SELECT k1.attacker_id AS player_id, k1.kill_count AS kills, COALESCE(k2.death_count, 0) AS deaths, "
					... " CAST(k1.kill_count AS DECIMAL(10,2)) / GREATEST(COALESCE(k2.death_count, 0), 10) AS normalized_kdr "
					... " FROM ("
					... " SELECT attacker_id, COUNT(DISTINCT id) AS kill_count "
					... " FROM `kill` "
					... " GROUP BY attacker_id"
					... " ) AS k1 "
					... " LEFT JOIN ("
					... " SELECT victim_id, COUNT(DISTINCT id) AS death_count "
					... " FROM `kill` "
					... " GROUP BY victim_id"
					... " ) AS k2 ON k1.attacker_id = k2.victim_id "
					... ") AS PlayerStats "
					... "JOIN `player` p ON PlayerStats.player_id = p.`id` "
					... "ORDER BY "
					... "PlayerStats.normalized_kdr DESC, "
					... "PlayerStats.deaths ASC, "
					... "PlayerStats.player_id ASC "
					... "LIMIT 100;"
				);

				g_DB.Query(MenuRanksTop_CallBack, query, GetClientUserId(param1));
			}
			else if	(StrEqual(info, "ranks-session-stats"))
				Menu_ShowCurrentStats(param1);
        }
	}

	return 0;
}

void MenuRanksTop_CallBack(Database db, DBResultSet results, const char[] error, any data)
{
	int playerIndex = GetClientOfUserId(data);
	if (playerIndex == 0)
		return;
	
	Menu menu = new Menu(MenuRanksTop_Handler, MENU_ACTIONS_ALL);

	menu.Pagination = true;
	menu.ExitBackButton = true;

	if (db == null || results == null || error[0])
	{
		menu.AddItem("null", "ERROR WITH GETTING TOP PLAYERS");
		LogError("Could not get top players (error: %s)", error);
		menu.Display(playerIndex, MENU_TIME_FOREVER);
		return;
	}

	if (!results.RowCount)
	{
		menu.AddItem("null", "No players found in the top list.");
		menu.Display(playerIndex, MENU_TIME_FOREVER);
		return;
	}

	int count = 0;

	while (results.FetchRow())
	{
		count++;
		int playerID = results.FetchInt(0);  // 0 for player_id
		
		char playerName[MAX_NAME_LENGTH];
		results.FetchString(1, playerName, sizeof(playerName));  // 1 for name

		// Extracting player kills, deaths, and kdr
		int playerKills = results.FetchInt(2);  // 2 for kills
		int playerDeaths = results.FetchInt(3);  // 3 for deaths
		float playerKDR = results.FetchFloat(4);  // 4 for kdr
		
		char truncatedName[15];  // 14 characters + 1 for null terminator
		TruncateString(playerName, truncatedName, sizeof(truncatedName), "", false);

		char sBuffer[16];
		IntToString(playerID, sBuffer, sizeof(sBuffer));

		char display[512];
		FormatEx(display, sizeof(display), "Rank: %i - %s - Kille: %i - Zgony: %i - KDR: %.2f", count, truncatedName, playerKills, playerDeaths, playerKDR);
		
		menu.AddItem(sBuffer, display);
	}

	menu.Display(playerIndex, MENU_TIME_FOREVER);
}

public int MenuRanksTop_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
                Menu_OpenRanksMain(param1);
        }
		case MenuAction_Display:
        {
			int rankPosition = g_PlayerRankPosition[param1];

			char buffer[1024];

			if (rankPosition != 99999)
				FormatEx(buffer, sizeof(buffer), "Top Graczy - KDR\nTwoja Pozycja: %i", rankPosition);
			else
				FormatEx(buffer, sizeof(buffer), "Top Graczy - KDR\nTwoja Pozycja: BRAK");

			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
        }

		case MenuAction_Select:
        {
			
        }
	}

	return 0;
}

void Menu_ShowCurrentStats(int client)
{
	Menu menu = new Menu(MenuRanksSession_Handler, MENU_ACTIONS_ALL);
	menu.Pagination = true;
	menu.ExitBackButton = true;

	int kills = g_SessionPlayerMatchData[client].playerKills;
	int deaths = g_SessionPlayerMatchData[client].playerDeaths;
	int headshots = g_SessionPlayerMatchData[client].playerHeadshots;
	int noscopes = g_SessionPlayerMatchData[client].playerNoScopes;
	int onFlashKills = g_SessionPlayerMatchData[client].playerBlindKills;
	int throughSmoke = g_SessionPlayerMatchData[client].playerSmokeKills;
	int throughWalls = g_SessionPlayerMatchData[client].playerWallKills;
	float distance = g_SessionPlayerMatchData[client].longestDistanceKill;
	int firstBloods = g_SessionPlayerMatchData[client].firstBloods;
	int totalDamage = g_SessionPlayerMatchData[client].totalDamage;

	int score = g_MatchPlayerData[client].playerScore;
	int playerAssists = g_MatchPlayerData[client].playerAssists;
	int roundsWin = g_MatchPlayerData[client].roundsWon;
	int roundsLost = g_MatchPlayerData[client].roundsLost;
	int suicides = g_MatchPlayerData[client].playerSuicides;
	int shots = g_MatchPlayerData[client].playerShots;
	int hits = g_MatchPlayerData[client].playerHits;

	char buffer[128];

	FormatEx(buffer, sizeof(buffer), "Zabójstwa: %i -- Zgony: %i -- Asysty: %i -- Samobójstwa: %i", kills, deaths, playerAssists, suicides);
	menu.AddItem("null", buffer);

	FormatEx(buffer, sizeof(buffer), "HeadShoty: %i -- NoScope: %i -- Zabójstwa będąc oślepionym: %i", headshots, noscopes, onFlashKills);
	menu.AddItem("null", buffer);

	FormatEx(buffer, sizeof(buffer), "Zabójstwa przez smoke: %i -- Zabójstwa przez ściane: %i -- Pierwsza Krew: %i", throughSmoke, throughWalls, firstBloods);
	menu.AddItem("null", buffer);

	FormatEx(buffer, sizeof(buffer), "Największy dystans przy zabójstwie: %2.f M -- Ogólnie obrażeń: %i", distance, totalDamage);
	menu.AddItem("null", buffer);

	FormatEx(buffer, sizeof(buffer), "Wynik: %i -- Oddane Strzały: %i -- Trafione Strzały: %i", score, shots, hits);
	menu.AddItem("null", buffer);

	FormatEx(buffer, sizeof(buffer), "Wygrane Rundy: %i -- Przegrane Rundy: %i", roundsWin, roundsLost);
	menu.AddItem("null", buffer);

	menu.Display(client, 0);
}

public int MenuRanksSession_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
        {
            delete menu;
        }

		case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
                Menu_OpenRanksMain(param1);
        }
		
		case MenuAction_Display:
        {
			int rankPosition = g_PlayerRankPosition[param1];

			char buffer[1024];

			if (rankPosition != 99999)
				FormatEx(buffer, sizeof(buffer), "Statystyki z aktualnej sesji\nTwoja pozycja w rankingu: %i", rankPosition);
			else
				FormatEx(buffer, sizeof(buffer), "Statystyki z aktualnej sesji\nTwoja pozycja w rankingu: BRAK");

			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
        }

		case MenuAction_Select:
        {
			
        }
	}

	return 0;
}