class Refour_Weather_Time_Dialog
{
    idd = 9999;
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
            h = 0.45 * safezoneH;
            colorBackground[] = {0,0,0,0.7};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_MARKER_ZONE_5";
            x = 0.29375 * safezoneW + safezoneX;
            y = 0.225 * safezoneH + safezoneY;
            w = 0.4125 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0,0.5,0.8,1};
            style = ST_CENTER;
        };
        class LabelTime: RscText
        {
             idc = -1;
             text = "$STR_LABEL_TIME";
             x = 0.30 * safezoneW + safezoneX;
             y = 0.28 * safezoneH + safezoneY;
             w = 0.39 * safezoneW;
             h = 0.03 * safezoneH;
        };
        class LabelClouds: RscText
        {
             idc = -1;
             text = "$STR_LABEL_CLOUDS";
             x = 0.30 * safezoneW + safezoneX;
             y = 0.36 * safezoneH + safezoneY;
             w = 0.39 * safezoneW;
             h = 0.03 * safezoneH;
        };
        class LabelFog: RscText
        {
             idc = -1;
             text = "$STR_LABEL_FOG";
             x = 0.30 * safezoneW + safezoneX;
             y = 0.44 * safezoneH + safezoneY;
             w = 0.39 * safezoneW;
             h = 0.03 * safezoneH;
        };
    };

    class controls
    {
        class ComboTime: RscCombo
        {
            idc = 2100;
            x = 0.30 * safezoneW + safezoneX;
            y = 0.31 * safezoneH + safezoneY;
            w = 0.39 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class ComboClouds: RscCombo
        {
            idc = 2101;
            x = 0.30 * safezoneW + safezoneX;
            y = 0.39 * safezoneH + safezoneY;
            w = 0.39 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class ComboFog: RscCombo
        {
            idc = 2102;
            x = 0.30 * safezoneW + safezoneX;
            y = 0.47 * safezoneH + safezoneY;
            w = 0.39 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class ButtonModify: RscButton
        {
            idc = -1;
            text = "$STR_BTN_MODIFY";
            x = 0.30 * safezoneW + safezoneX;
            y = 0.55 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['APPLY'] call MISSION_fnc_spawn_weather_and_time;";
        };
        class ButtonClose: RscButton
        {
            idc = -1;
            text = "$STR_CLOSE";
            x = 0.57 * safezoneW + safezoneX;
            y = 0.55 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
            action = "closeDialog 0;";
        };
    };
};
