class Refour_Vehicle_Dialog
{
    idd = 8888;
    movingEnable = false;
    enableSimulation = true;

    class controlsBackground
    {
        class MainBackground: RscText
        {
            idc = -1;
            x = 0.15 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.55 * safezoneH;
            colorBackground[] = {0,0,0,0.7};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_GARAGE_TITLE";
            x = 0.15 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0,0.5,0.8,1};
            style = ST_CENTER;
        };
    };

    class controls
    {
        class UnitList: RscListBox
        {
            idc = 1500;
            x = 0.16 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.68 * safezoneW;
            h = 0.42 * safezoneH;
        };
        
        class ButtonRecruit: RscButton
        {
            idc = 5502;
            text = "$STR_GARAGE_TAKE_OUT";
            x = 0.16 * safezoneW + safezoneX;
            y = 0.61 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['SPAWN'] call MISSION_fnc_spawn_vehicles;";
        };

        class ButtonDelete: RscButton
        {
            idc = 5503;
            text = "$STR_BTN_DELETE";
            x = 0.40 * safezoneW + safezoneX;
            y = 0.61 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['DELETE'] call MISSION_fnc_spawn_vehicles;";
        };

        class ButtonClose: RscButton
        {
            idc = -1;
            text = "$STR_CLOSE";
            x = 0.64 * safezoneW + safezoneX;
            y = 0.61 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            action = "closeDialog 0;";
        };
    };
};
