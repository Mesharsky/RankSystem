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

#pragma newdecls required
#pragma semicolon 1

methodmap RankSettings < StringMap
{
    public RankSettings()
    {
        StringMap settings = new StringMap();
        return view_as<RankSettings>(settings);
    }

    property int MinimumPlayers
    {
        public get() { return RankSettings_GetCell(this, "_rank_minimum_players"); }
        public set(int value) { this.SetValue("_rank_minimum_players", value); }
    }

    property int RankLadeboardType
    {
        public get() { return RankSettings_GetCell(this, "_rank_system_laderboard"); }
        public set(int value) { this.SetValue("_rank_system_laderboard", value); }
    }

    property bool ScoreboardDisplayEnable
    {
        public get() { return RankSettings_GetCell(this, "_rank_display_scoreboard"); }
        public set(bool value) { this.SetValue("_rank_display_scoreboard", value); }
    }

    property int RankScoreboardStyle
    {
        public get() { return RankSettings_GetCell(this, "_rank_scoreboard_style"); }
        public set(int value) { this.SetValue("_rank_scoreboard_style", value); }
    }

    property bool RankVipSystemEnable
    {
        public get() { return RankSettings_GetCell(this, "_rank_system_vip"); }
        public set(bool value) { this.SetValue("_rank_system_vip", value); }
    }

    property int RankVipFlag
    {
        public get() { return RankSettings_GetCell(this, "_rank_system_vip_flag"); }
        public set(int flag) { this.SetValue("_rank_system_vip_flag", flag); }
    }

    public void GetRankVipOverride(char[] output, int size) { this.GetString("_rank_system_vip_override", output, size); }
    public void SetRankVipOvveride(const char[] override) { this.SetString("_rank_system_vip_override", override); }
}

static any RankSettings_GetCell(RankSettings settings, const char[] field)
{
    any value;
    if (!settings.GetValue(field, value))
        ThrowError("Settings %x is missing field '%s'", settings, field);
    return value;
}

methodmap RankMisc < StringMap
{
    public RankMisc()
    {
        StringMap misc = new StringMap();
        return view_as<RankMisc>(misc);   
    }

    property bool RankOverlayEnable
    {
        public get() { return RankMisc_GetCell(this, "_rankup_overlay"); }
        public set(bool value) { this.SetValue("_rankup_overlay", value); }
    }

    property bool RankRankUpSoundEnable
    {
        public get() { return RankMisc_GetCell(this, "_rankup_sound"); }
        public set(bool value) { this.SetValue("_rankup_sound", value); }
    }

    property bool RankGlobalMessageEnable
    {
        public get() { return RankMisc_GetCell(this, "_rankup_message"); }
        public set(bool value) { this.SetValue("_rankup_message", value); }
    }
}

static any RankMisc_GetCell(RankMisc misc, const char[] field)
{
    any value;
    if (!misc.GetValue(field, value))
        ThrowError("Misc %x is missing field '%s'", misc, field);
    return value;
}

methodmap RankPoints < StringMap
{
    public RankPoints()
    {
        StringMap points = new StringMap();
        return view_as<RankPoints>(points);
    }

    /**
     * Gaining points
     * Normal Players
     */

    property int PointsEarnKill
    {
        public get() { return RankPoints_GetCell(this, "_points_kill"); }
        public set(int value) { this.SetValue("_points_kill", value); }
    }
    property int PointsEarnHeadShot
    {
        public get() { return RankPoints_GetCell(this, "_points_headshot"); }
        public set(int value) { this.SetValue("_points_headshot", value); }
    }
    property int PointsEarnAssist
    {
        public get() { return RankPoints_GetCell(this, "_points_assist"); }
        public set(int value) { this.SetValue("_points_assist", value); }
    }
    property int PointsEarnMVP
    {
        public get() { return RankPoints_GetCell(this, "_points_mvp"); }
        public set(int value) { this.SetValue("_points_mvp", value); }
    }
    property int PointsEarnKnifeKill
    {
        public get() { return RankPoints_GetCell(this, "_points_knife_kill"); }
        public set(int value) { this.SetValue("_points_knife_kill", value); }
    }
    property int PointsEarnBombPlanted
    {
        public get() { return RankPoints_GetCell(this, "_points_bomb_planted"); }
        public set(int value) { this.SetValue("_points_bomb_planted", value); }
    }
    property int PointsEarnBombDefused
    {
        public get() { return RankPoints_GetCell(this, "_points_bomb_defused"); }
        public set(int value) { this.SetValue("_points_bomb_defused", value); }
    }
    property int PointsEarnRoundWin
    {
        public get() { return RankPoints_GetCell(this, "_points_round_win"); }
        public set(int value) { this.SetValue("_points_round_win", value); }
    }

    /**
     * Gaining points
     * Vip Players (if enabled)
     */

    property int PointsEarnKillVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_kill"); }
        public set(int value) { this.SetValue("_points_vip_kill", value); }
    }
    property int PointsEarnHeadShotVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_headshot"); }
        public set(int value) { this.SetValue("_points_vip_headshot", value); }
    }
    property int PointsEarnAssistVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_assist"); }
        public set(int value) { this.SetValue("_points_vip_assist", value); }
    }
    property int PointsEarnMVPVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_mvp"); }
        public set(int value) { this.SetValue("_points_vip_mvp", value); }
    }
    property int PointsEarnKnifeKillVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_knife_kill"); }
        public set(int value) { this.SetValue("_points_vip_knife_kill", value); }
    }
    property int PointsEarnBombPlantedVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_bomb_planted"); }
        public set(int value) { this.SetValue("_points_vip_bomb_planted", value); }
    }
    property int PointsEarnBombDefusedVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_bomb_defused"); }
        public set(int value) { this.SetValue("_points_vip_bomb_defused", value); }
    }
    property int PointsEarnRoundWinVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_round_win"); }
        public set(int value) { this.SetValue("_points_vip_round_win", value); }
    }

    /**
     * Losing Points
     * Normal Players
     */

    property int PointsLoseDeath
    {
        public get() { return RankPoints_GetCell(this, "_points_lose_death"); }
        public set(int value) { this.SetValue("_points_lose_death", value); }
    }
    property int PointsLoseLostRound
    {
        public get() { return RankPoints_GetCell(this, "_points_lose_lostround"); }
        public set(int value) { this.SetValue("_points_lose_lostround", value); }
    }

    /**
     * Losing Points
     * Vip Players (if enabled)
     */

    property int PointsLoseDeathVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_lose_death"); }
        public set(int value) { this.SetValue("_points_vip_lose_death", value); }
    }
    property int PointsLoseLostRoundVip
    {
        public get() { return RankPoints_GetCell(this, "_points_vip_lose_lostround"); }
        public set(int value) { this.SetValue("_points_vip_lose_lostround", value); }
    }
}

static any RankPoints_GetCell(RankPoints points, const char[] field)
{
    any value;
    if (!points.GetValue(field, value))
        ThrowError("Gaining Points %x is missing field '%s'", points, field);
    return value;
}