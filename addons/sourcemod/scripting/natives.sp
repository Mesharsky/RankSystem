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

// native int Rank_GetPoints(int client);
public int Native_GetPoints(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 0 || client > MaxClients)
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %i", client);
    if (!CanGainPoints(client))
        ThrowNativeError(SP_ERROR_NATIVE, "Client %i does not have points loaded.", client);
        
    return g_PlayerTotalPoints[client];
}

// native bool Rank_SetPoints(int client, int value);
public any Native_SetPoints(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 0 || client > MaxClients)
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %i", client);
    if (!CanGainPoints(client))
        return false;

    int value = GetNativeCell(2);

    return SetPoints(client, value);
}

// native bool Rank_AddPoints(int client, int value);
public any Native_AddPoints(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 0 || client > MaxClients)
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %i", client);
    if (!CanGainPoints(client))
        return false;

    int value = GetNativeCell(2);

    return AddPoints(client, value);
}

// native bool Rank_RemovePoints(int client, int value);
public any Native_RemovePoints(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 0 || client > MaxClients)
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %i", client);
    if (!CanGainPoints(client))
        return false;

    int value = GetNativeCell(2);

    return RemovePoints(client, value);
}