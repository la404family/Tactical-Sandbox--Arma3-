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
            x = 0.1 * safezoneW + safezoneX;
            y = 0.1 * safezoneH + safezoneY;
            w = 0.8 * safezoneW;
            h = 0.8 * safezoneH;
            colorBackground[] = {0,0,0,0.85};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_MISSIONS_MENU_TITLE";
            x = 0.1 * safezoneW + safezoneX;
            y = 0.1 * safezoneH + safezoneY;
            w = 0.8 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.1,0.3,0.6,1};
            style = ST_CENTER;
        };
        // Left panel label
        class LeftLabel: RscText
        {
            idc = -1;
            text = "$STR_MISSIONS_LIST_LABEL";
            x = 0.11 * safezoneW + safezoneX;
            y = 0.16 * safezoneH + safezoneY;
            w = 0.28 * safezoneW;
            h = 0.03 * safezoneH;
        };
        // Right panel background
        class RightBackground: RscText
        {
            idc = -1;
            x = 0.41 * safezoneW + safezoneX;
            y = 0.16 * safezoneH + safezoneY;
            w = 0.48 * safezoneW;
            h = 0.62 * safezoneH;
            colorBackground[] = {0.1,0.1,0.1,0.5};
        };
    };

    class controls
    {
        // Left panel - Task list
        class TaskList: RscListBox
        {
            idc = 2200;
            x = 0.11 * safezoneW + safezoneX;
            y = 0.20 * safezoneH + safezoneY;
            w = 0.28 * safezoneW;
            h = 0.58 * safezoneH;
            onLBSelChanged = "['SELECT', _this] call MISSION_fnc_spawn_missions;";
        };

        // Right panel - Task title
        class TaskTitle: RscText
        {
            idc = 2202;
            text = "";
            x = 0.42 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.46 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.2,0.4,0.7,1};
            style = ST_CENTER;
        };

        // Right panel - Checkbox label
        class SelectLabel: RscText
        {
            idc = -1;
            text = "$STR_MISSIONS_SELECT";
            x = 0.42 * safezoneW + safezoneX;
            y = 0.22 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.03 * safezoneH;
        };

        // Right panel - Select Button
        class TaskCheckbox: RscButton
        {
            idc = 2201;
            text = "$STR_BTN_SELECT";
            x = 0.62 * safezoneW + safezoneX;
            y = 0.22 * safezoneH + safezoneY;
            w = 0.10 * safezoneW;
            h = 0.03 * safezoneH;
            // Couleurs - Gris foncé par défaut (devient vert via script quand sélectionné)
            colorText[] = {1,1,1,1};              // Texte blanc
            colorBackground[] = {0.3,0.3,0.3,1};  // Fond gris foncé
            colorBackgroundActive[] = {0.25,0.25,0.25,1}; // Fond quand cliqué
            colorFocused[] = {0.3,0.3,0.3,1};     // Fond quand focus
            colorBackgroundDisabled[] = {0.3,0.3,0.3,1};
            colorDisabled[] = {0.5,0.5,0.5,1};
            action = "['TOGGLE'] call MISSION_fnc_spawn_missions;";
        };

        // Right panel - Description
        class TaskDescription: RscText
        {
            idc = 2203;
            text = "";
            x = 0.42 * safezoneW + safezoneX;
            y = 0.27 * safezoneH + safezoneY;
            w = 0.46 * safezoneW;
            h = 0.50 * safezoneH;
            style = ST_MULTI;
            lineSpacing = 1;
        };

        // Bottom buttons
        class ButtonLaunch: RscButton
        {
            idc = -1;
            text = "$STR_MISSIONS_LAUNCH";
            x = 0.35 * safezoneW + safezoneX;
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
