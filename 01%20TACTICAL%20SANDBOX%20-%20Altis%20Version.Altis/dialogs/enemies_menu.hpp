// ============================================================================
// Dialog de Sélection des Ennemis
// ID: 7777
// Version large - listes élargies pour noms complets
// ============================================================================

class Refour_Enemies_Dialog
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
            h = 0.76 * safezoneH;
            colorBackground[] = {0,0,0,0.85};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_ENEMIES_MENU_TITLE";
            x = 0.15 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.6,0.1,0.1,1};
            style = ST_CENTER;
        };
    };

    class controls
    {
        // ===== SECTION OFFICIERS (gauche, haut) =====
        class LabelOfficers: RscText
        {
            idc = 3001;
            text = "$STR_SELECT_OFFICERS";
            x = 0.16 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.025 * safezoneH;
            colorBackground[] = {0.4,0.2,0,0.8};
            style = ST_LEFT;
        };
        
        class CounterOfficers: RscText
        {
            idc = 3002;
            text = "0 / 3";
            x = 0.41 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.07 * safezoneW;
            h = 0.025 * safezoneH;
            colorText[] = {1,0.8,0,1};
            colorBackground[] = {0.3,0.15,0,0.8};
            style = ST_CENTER;
        };
        
        // Liste Officiers (beaucoup plus large)
        class OfficersList: RscListBox
        {
            idc = 3003;
            x = 0.16 * safezoneW + safezoneX;
            y = 0.20 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.18 * safezoneH;
        };
        
        // ===== SECTION SOLDATS (gauche, bas) =====
        class LabelSoldiers: RscText
        {
            idc = 3004;
            text = "$STR_SELECT_SOLDIERS";
            x = 0.16 * safezoneW + safezoneX;
            y = 0.39 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.025 * safezoneH;
            colorBackground[] = {0.2,0.3,0,0.8};
            style = ST_LEFT;
        };
        
        class CounterSoldiers: RscText
        {
            idc = 3005;
            text = "0 / 12";
            x = 0.41 * safezoneW + safezoneX;
            y = 0.39 * safezoneH + safezoneY;
            w = 0.07 * safezoneW;
            h = 0.025 * safezoneH;
            colorText[] = {0.6,1,0.2,1};
            colorBackground[] = {0.15,0.2,0,0.8};
            style = ST_CENTER;
        };
        
        // Liste Soldats (beaucoup plus large)
        class SoldiersList: RscListBox
        {
            idc = 3006;
            x = 0.16 * safezoneW + safezoneX;
            y = 0.42 * safezoneH + safezoneY;
            w = 0.32 * safezoneW;
            h = 0.36 * safezoneH;
        };
        
        // ===== LISTE OPFOR DISPONIBLES (droite) =====
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
            idc = 3007;
            x = 0.50 * safezoneW + safezoneX;
            y = 0.20 * safezoneH + safezoneY;
            w = 0.34 * safezoneW;
            h = 0.54 * safezoneH;
        };
        
        // ===== BOUTONS D'AJOUT =====
        class BtnAddOfficer: RscButton
        {
            idc = 3010;
            text = "$STR_BTN_ADD_OFFICER";
            x = 0.50 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.16 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.5,0.3,0,1};
            colorBackgroundActive[] = {0.7,0.4,0,1};
            action = "['ADD_OFFICER'] call MISSION_fnc_spawn_ennemies;";
        };
        
        class BtnAddSoldier: RscButton
        {
            idc = 3011;
            text = "$STR_BTN_ADD_SOLDIER";
            x = 0.68 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.16 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.2,0.4,0,1};
            colorBackgroundActive[] = {0.3,0.6,0,1};
            action = "['ADD_SOLDIER'] call MISSION_fnc_spawn_ennemies;";
        };
        
        // ===== BOUTONS DE VALIDATION =====
        class BtnValidate: RscButton
        {
            idc = 3020;
            text = "$STR_BTN_VALIDATE";
            x = 0.16 * safezoneW + safezoneX;
            y = 0.80 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0,0.5,0,1};
            colorBackgroundActive[] = {0,0.7,0,1};
            action = "['VALIDATE'] call MISSION_fnc_spawn_ennemies;";
        };
        
        class BtnReset: RscButton
        {
            idc = 3021;
            text = "$STR_BTN_RESET";
            x = 0.33 * safezoneW + safezoneX;
            y = 0.80 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.7,0,0,1};
            colorBackgroundActive[] = {1,0,0,1};
            action = "['RESET'] call MISSION_fnc_spawn_ennemies;";
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
