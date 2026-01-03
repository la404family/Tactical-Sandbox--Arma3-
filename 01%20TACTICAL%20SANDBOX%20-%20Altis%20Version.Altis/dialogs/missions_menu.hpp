class Refour_Missions_Dialog
{
    idd = 7777;
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
            h = 0.78 * safezoneH;
            colorBackground[] = {0,0,0,0.85};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_MISSIONS_MENU_TITLE";
            x = 0.15 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.1,0.3,0.6,1};
            style = ST_CENTER;
        };
        // Left panel label
        class LeftLabel: RscText
        {
            idc = -1;
            text = "$STR_MISSIONS_LIST_LABEL";
            x = 0.16 * safezoneW + safezoneX;
            y = 0.18 * safezoneH + safezoneY;
            w = 0.24 * safezoneW;
            h = 0.03 * safezoneH;
        };
        // Right panel background
        class RightBackground: RscText
        {
            idc = -1;
            x = 0.42 * safezoneW + safezoneX;
            y = 0.18 * safezoneH + safezoneY;
            w = 0.42 * safezoneW;
            h = 0.60 * safezoneH;
            colorBackground[] = {0.1,0.1,0.1,0.5};
        };
    };

    class controls
    {
        // Left panel - Task list
        class TaskList: RscListBox
        {
            idc = 2200;
            x = 0.16 * safezoneW + safezoneX;
            y = 0.22 * safezoneH + safezoneY;
            w = 0.24 * safezoneW;
            h = 0.56 * safezoneH;
            onLBSelChanged = "['SELECT', _this] call MISSION_fnc_spawn_missions;";
        };

        // Right panel - Task title
        class TaskTitle: RscText
        {
            idc = 2202;
            text = "";
            x = 0.42 * safezoneW + safezoneX;
            y = 0.19 * safezoneH + safezoneY;
            w = 0.42 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.2,0.4,0.7,1};
            style = ST_CENTER;
        };

        // Right panel - Description (position ajustée car plus de bouton sélectionner)
        class TaskDescription: RscText
        {
            idc = 2203;
            text = "";
            x = 0.42 * safezoneW + safezoneX;
            y = 0.24 * safezoneH + safezoneY;
            w = 0.42 * safezoneW;
            h = 0.53 * safezoneH;
            style = ST_MULTI;
            lineSpacing = 1;
        };

        // Bottom buttons
        class ButtonLaunch: RscButton
        {
            idc = -1;
            text = "$STR_MISSIONS_LAUNCH";
            x = 0.33 * safezoneW + safezoneX;
            y = 0.82 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.2,0.6,0.2,1};
            action = "['LAUNCH'] call MISSION_fnc_spawn_missions;";
        };
        class ButtonQuit: RscButton
        {
            idc = -1;
            text = "$STR_MISSIONS_QUIT";
            x = 0.52 * safezoneW + safezoneX;
            y = 0.82 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.6,0.2,0.2,1};
            action = "closeDialog 0;";
        };
    };
};
