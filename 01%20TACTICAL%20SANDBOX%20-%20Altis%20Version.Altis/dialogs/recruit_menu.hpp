// ============================================================================
// Dialog de Sélection des Frères d'Armes
// ID: 8888
// Version avec multi-sélection (max 14 unités)
// ============================================================================

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
            x = 0.15 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.76 * safezoneH;
            colorBackground[] = {0,0,0,0.85};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_RECRUIT_TITLE";
            x = 0.15 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.8,0.5,0,1};
            style = ST_CENTER;
        };
    };

    class controls
    {
        // ===== SECTION UNITÉS SÉLECTIONNÉES (gauche) =====
        class LabelSelected: RscText
        {
            idc = 1501;
            text = "$STR_SELECTED_UNITS";
            x = 0.16 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.025 * safezoneH;
            colorBackground[] = {0.3,0.5,0.1,0.8};
            style = ST_LEFT;
        };
        
        class CounterSelected: RscText
        {
            idc = 1502;
            text = "0 / 14";
            x = 0.41 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.07 * safezoneW;
            h = 0.025 * safezoneH;
            colorText[] = {0.6,1,0.2,1};
            colorBackground[] = {0.2,0.35,0.05,0.8};
            style = ST_CENTER;
        };
        
        // Liste des unités sélectionnées
        class SelectedList: RscListBox
        {
            idc = 1503;
            x = 0.16 * safezoneW + safezoneX;
            y = 0.20 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.54 * safezoneH;
        };
        
        // ===== SECTION UNITÉS DISPONIBLES (droite) =====
        class LabelAvailable: RscText
        {
            idc = -1;
            text = "$STR_AVAILABLE_UNITS";
            x = 0.50 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.34 * safezoneW;
            h = 0.025 * safezoneH;
            colorBackground[] = {0.3,0.3,0.3,0.8};
            style = ST_CENTER;
        };
        
        class AvailableList: RscListBox
        {
            idc = 1500;
            x = 0.50 * safezoneW + safezoneX;
            y = 0.20 * safezoneH + safezoneY;
            w = 0.34 * safezoneW;
            h = 0.54 * safezoneH;
        };
        
        // ===== BOUTON D'AJOUT =====
        class BtnAdd: RscButton
        {
            idc = 1510;
            text = "$STR_BTN_ADD";
            x = 0.50 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.34 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.2,0.5,0.2,1};
            colorBackgroundActive[] = {0.3,0.7,0.3,1};
            action = "['ADD'] call MISSION_fnc_spawn_brothers_in_arms;";
        };

        // ===== BOUTONS DE VALIDATION =====
        class BtnValidate: RscButton
        {
            idc = 1520;
            text = "$STR_BTN_VALIDATE";
            x = 0.16 * safezoneW + safezoneX;
            y = 0.80 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0,0.5,0,1};
            colorBackgroundActive[] = {0,0.7,0,1};
            action = "['VALIDATE'] call MISSION_fnc_spawn_brothers_in_arms;";
        };
        
        class BtnReset: RscButton
        {
            idc = 1521;
            text = "$STR_BTN_RESET";
            x = 0.33 * safezoneW + safezoneX;
            y = 0.80 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.7,0,0,1};
            colorBackgroundActive[] = {1,0,0,1};
            action = "['RESET'] call MISSION_fnc_spawn_brothers_in_arms;";
        };
        
        class BtnClose: RscButton
        {
            idc = -1;
            text = "$STR_CLOSE";
            x = 0.68 * safezoneW + safezoneX;
            y = 0.80 * safezoneH + safezoneY;
            w = 0.16 * safezoneW;
            h = 0.05 * safezoneH;
            action = "closeDialog 0;";
        };
    };
};
