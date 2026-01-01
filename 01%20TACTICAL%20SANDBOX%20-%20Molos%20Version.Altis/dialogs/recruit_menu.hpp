class Refour_Recruit_Dialog
{
    idd = 8888;
    movingEnable = false;
    enableSimulation = true;

    class controlsBackground
    {
        class MainBackground: RscText
        {
            idc = -1;
            x = 0.29375 * safezoneW + safezoneX;
            y = 0.225 * safezoneH + safezoneY;
            w = 0.4125 * safezoneW;
            h = 0.55 * safezoneH;
            colorBackground[] = {0,0,0,0.7};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_RECRUIT_TITLE";
            x = 0.29375 * safezoneW + safezoneX;
            y = 0.225 * safezoneH + safezoneY;
            w = 0.4125 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.8,0.5,0,1};
            style = ST_CENTER;
        };
    };

    class controls
    {
        class UnitList: RscListBox
        {
            idc = 1500;
            x = 0.304062 * safezoneW + safezoneX;
            y = 0.28 * safezoneH + safezoneY;
            w = 0.391875 * safezoneW;
            h = 0.42 * safezoneH;
        };
        
        class ButtonRecruit: RscButton
        {
            idc = 5502;
            text = "$STR_RECRUIT_BUTTON";
            x = 0.304062 * safezoneW + safezoneX;
            y = 0.72 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['SPAWN'] call MISSION_fnc_spawn_brothers_in_arms;";
        };

        class ButtonReset: RscButton
        {
            idc = 5503;
            text = "$STR_BTN_RESET";
            x = 0.4395 * safezoneW + safezoneX;
            y = 0.72 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.8, 0.7, 0, 1};
            colorBackgroundActive[] = {1, 0.85, 0, 1};
            colorFocused[] = {0.9, 0.75, 0, 1};
            action = "['RESET'] call MISSION_fnc_spawn_brothers_in_arms;";
        };

        class ButtonClose: RscButton
        {
            idc = -1;
            text = "$STR_CLOSE";
            x = 0.575 * safezoneW + safezoneX;
            y = 0.72 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
            action = "closeDialog 0;";
        };
    };
};
