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

#if defined _ranksystem_core_included
    #endinput
#endif
#define _ranksystem_core_included

#include <sourcemod>

/**
 * Get a client's points.
 *
 * @param client    Client index.
 * @return          Amount of points.
 *
 * @error           Invalid client index or client's points aren't loaded.
 */
native int Rank_GetPoints(int client);

/**
 * Set a client's points.
 * This shouldn't be used unless necessary.
 *
 * This will fail if client's points afterwards would be higher than the
 * max limit or lower than 0.
 *
 * @param client    Client index.
 * @param value     Amount of points.
 * @return          True if points were set.
 *
 * @error           Invalid client index.
 */
native bool Rank_SetPoints(int client, int value);

/**
 * Give a client more points.
 *
 * This will fail if client's points afterwards would be higher than the
 * max limit or lower than 0.
 *
 * @param client    Client index.
 * @param value     Amount of points.
 * @return          True if points were added.
 *
 * @error           Invalid client index.
 */
native bool Rank_AddPoints(int client, int value);

/**
 * Remove points from a client.
 *
 * This will fail if client's points afterwards would be higher than the
 * max limit or lower than 0.
 *
 * @param client    Client index.
 * @param value     Amount of points.
 * @return          True if points were removed.
 *
 * @error           Invalid client index.
 */
native bool Rank_RemovePoints(int client, int value);


// ====[ LIBRARY CONFIG ]=======================================================

/**
 * Do not edit below this line!
 */
public SharedPlugin __pl_ranksystem_core =
{
    name = "ranksystem_core",
    file = "ranksystem_core.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
}

#if !defined REQUIRE_PLUGIN
public __pl_ranksystem_core_SetNTVOptional()
{
    MarkNativeAsOptional("Rank_GetPoints");
    MarkNativeAsOptional("Rank_SetPoints");
    MarkNativeAsOptional("Rank_AddPoints");
    MarkNativeAsOptional("Rank_RemovePoints");
}
#endif