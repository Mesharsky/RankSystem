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

public Action Command_AddPoints(int client, int args)
{
    if (!IsClientAdmin(client))
    {
        CPrintToChat(client, "%s %t", g_ChatTag, "Command No Permissions");
        return Plugin_Handled;
    }

    if (args != 2)
    {
        CPrintToChat(client, "%s %t", g_ChatTag, "Command Add Points Invalid Params");
        return Plugin_Handled;
    }

    char arg1[MAX_NAME_LENGTH];
    char arg2[32];

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    int target = FindTarget(client, arg1, true);
    if (target == -1)
        return Plugin_Handled;

    GetClientName(target, arg1, sizeof(arg1));

    int amount = StringToInt(arg2);
    if (amount <= 0)
        CReplyToCommand(client, "%s %t", g_ChatTag, "Command Points Invalid Amount");

    AddPoints(target, amount);
    CPrintToChat(client, "%s %t", g_ChatTag, "Command Add Points Admin Notify", arg1, amount);
    CPrintToChat(client, "%s %t", g_ChatTag, "Command Add Points Player Notify", amount);

    return Plugin_Handled;
}

public Action Command_RemovePoints(int client, int args)
{
    if (!IsClientAdmin(client))
    {
        CPrintToChat(client, "%s %t", g_ChatTag, "No Permissions Command", g_ChatTag);
        return Plugin_Handled;
    }

    if (args != 2)
    {
        CPrintToChat(client, "%s %t", g_ChatTag, "Command Remove Points Invalid Params", g_ChatTag);
        return Plugin_Handled;
    }

    char arg1[MAX_NAME_LENGTH];
    char arg2[32];

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    int target = FindTarget(client, arg1, true);
    if (target == -1)
        return Plugin_Handled;

    GetClientName(target, arg1, sizeof(arg1));

    int amount = StringToInt(arg2);
    if (amount <= 0)
        CReplyToCommand(client, "%s %t", g_ChatTag, "Command Points Invalid Amount");

    RemovePoints(target, amount);
    CPrintToChat(client, "%s %t", g_ChatTag, "Command Remove Points Admin Notify", arg1, amount);
    CPrintToChat(client, "%s %t", g_ChatTag, "Command Remove Points Player Notify", amount);

    return Plugin_Handled;
}

public Action Command_SetPoints(int client, int args)
{
    if (!IsClientAdmin(client))
    {
        CPrintToChat(client, "%s %t", "No Permissions Command", g_ChatTag);
        return Plugin_Handled;
    }

    if (args != 2)
    {
        CPrintToChat(client, "%s %t", g_ChatTag, "Command Set Points Invalid Params");
        return Plugin_Handled;
    }

    char arg1[MAX_NAME_LENGTH];
    char arg2[32];

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    int target = FindTarget(client, arg1, true);
    if (target == -1)
        return Plugin_Handled;

    GetClientName(target, arg1, sizeof(arg1));

    int amount = StringToInt(arg2);
    if (amount <= 0)
        CReplyToCommand(client, "%s %t", g_ChatTag, "Command Points Invalid Amount");

    SetPoints(target, amount);
    CPrintToChat(client, "%s %t", g_ChatTag, "Command Set Points Admin Notify", arg1, amount);
    CPrintToChat(client, "%s %t", g_ChatTag, "Command Set Points Player Notify", amount);

    return Plugin_Handled;
}