/*
    Description :
    Cette fonction gère le menu de sélection des ennemis.
    Permet de choisir 3 officiers et 12 soldats OPFOR pour personnaliser les ennemis de mission.
    
    Modes :
    - INIT : Initialisation de l'action dans la zone enemies_request
    - OPEN : Ouverture du menu et population des listes
    - ADD_OFFICER : Ajoute l'unité sélectionnée comme officier
    - ADD_SOLDIER : Ajoute l'unité sélectionnée comme soldat
    - VALIDATE : Valide la sélection et met à jour la mémoire
    - RESET : Réinitialise la sélection
*/

params [["_mode", ""]];

// Variables globales pour stocker la sélection temporaire
if (isNil "ENEMIES_temp_officers") then { ENEMIES_temp_officers = []; };
if (isNil "ENEMIES_temp_soldiers") then { ENEMIES_temp_soldiers = []; };

switch (_mode) do {
    
    // ============================================================================
    // INIT - Ajoute l'action au joueur
    // ============================================================================
    case "INIT": {
        if (!hasInterface) exitWith {};
        
        waitUntil { !isNull player };
        
        player addAction [
            localize "STR_ACTION_ENEMIES",
            {
                if (missionNamespace getVariable ["MISSION_var_mission_active", false]) exitWith {
                    hint (localize "STR_MISSION_ALREADY_ACTIVE");
                };
                ["OPEN"] call MISSION_fnc_spawn_ennemies;
            },
            [],
            1.5,
            true,
            true,
            "",
            "player inArea enemies_request"
        ];
    };
    
    // ============================================================================
    // OPEN - Ouvre le dialogue et remplit la liste OPFOR
    // ============================================================================
    case "OPEN": {
        // Réinitialise les sélections temporaires
        ENEMIES_temp_officers = [];
        ENEMIES_temp_soldiers = [];
        
        createDialog "Refour_Enemies_Dialog";
        waitUntil { !isNull (findDisplay 7777) };
        
        private _display = findDisplay 7777;
        private _ctrlAvailable = _display displayCtrl 3007;
        private _ctrlOfficers = _display displayCtrl 3003;
        private _ctrlSoldiers = _display displayCtrl 3006;
        
        // Vide les listes
        lbClear _ctrlAvailable;
        lbClear _ctrlOfficers;
        lbClear _ctrlSoldiers;
        
        // Récupère toutes les unités OPFOR (East = 1)
        private _cfgVehicles = configFile >> "CfgVehicles";
        private _units = "
            (getNumber (_x >> 'scope') == 2) && 
            (getText (_x >> 'simulation') == 'soldier') && 
            (getNumber (_x >> 'side') == 0)
        " configClasses _cfgVehicles;
        
        // Prépare un tableau triable
        private _sortableUnits = [];
        
        {
            private _class = _x;
            private _displayName = getText (_class >> "displayName");
            private _className = configName _class;
            private _factionClass = getText (_class >> "faction");
            
            private _factionDisplayName = getText (configFile >> "CfgFactionClasses" >> _factionClass >> "displayName");
            if (_factionDisplayName == "") then { _factionDisplayName = _factionClass; };
            
            private _entryText = format ["[%1] %2", _factionDisplayName, _displayName];
            _sortableUnits pushBack [_entryText, _className];
        } forEach _units;
        
        // Tri alphabétique
        _sortableUnits sort true;
        
        // Remplit la liste disponible
        {
            _x params ["_text", "_data"];
            private _index = _ctrlAvailable lbAdd _text;
            _ctrlAvailable lbSetData [_index, _data];
        } forEach _sortableUnits;
        
        // Sélectionne le premier élément
        if (lbSize _ctrlAvailable > 0) then {
            _ctrlAvailable lbSetCurSel 0;
        };
        
        // Met à jour les compteurs
        ["UPDATE_COUNTERS"] call MISSION_fnc_spawn_ennemies;
    };
    
    // ============================================================================
    // ADD_OFFICER - Ajoute l'unité sélectionnée comme officier
    // ============================================================================
    case "ADD_OFFICER": {
        disableSerialization;
        private _display = findDisplay 7777;
        if (isNull _display) exitWith {};
        
        private _ctrlAvailable = _display displayCtrl 3007;
        private _ctrlOfficers = _display displayCtrl 3003;
        
        private _index = lbCurSel _ctrlAvailable;
        if (_index == -1) exitWith {};
        
        // Vérifie limite (3 officiers max)
        if (count ENEMIES_temp_officers >= 3) exitWith {
            hint localize "STR_ERR_MAX_OFFICERS";
        };
        
        private _className = _ctrlAvailable lbData _index;
        private _displayName = _ctrlAvailable lbText _index;
        
        // Ajoute à la liste temporaire
        ENEMIES_temp_officers pushBack [_className, _displayName];
        
        // Ajoute à la ListBox affichée
        private _newIndex = _ctrlOfficers lbAdd _displayName;
        _ctrlOfficers lbSetData [_newIndex, _className];
        _ctrlOfficers lbSetColor [_newIndex, [1, 0.7, 0, 1]];
        
        // Met à jour les compteurs
        ["UPDATE_COUNTERS"] call MISSION_fnc_spawn_ennemies;
        
        playSound "3DEN_notificationDefault";
    };
    
    // ============================================================================
    // ADD_SOLDIER - Ajoute l'unité sélectionnée comme soldat
    // ============================================================================
    case "ADD_SOLDIER": {
        disableSerialization;
        private _display = findDisplay 7777;
        if (isNull _display) exitWith {};
        
        private _ctrlAvailable = _display displayCtrl 3007;
        private _ctrlSoldiers = _display displayCtrl 3006;
        
        private _index = lbCurSel _ctrlAvailable;
        if (_index == -1) exitWith {};
        
        // Vérifie limite (12 soldats max)
        if (count ENEMIES_temp_soldiers >= 12) exitWith {
            hint localize "STR_ERR_MAX_SOLDIERS";
        };
        
        private _className = _ctrlAvailable lbData _index;
        private _displayName = _ctrlAvailable lbText _index;
        
        // Ajoute à la liste temporaire
        ENEMIES_temp_soldiers pushBack [_className, _displayName];
        
        // Ajoute à la ListBox affichée
        private _newIndex = _ctrlSoldiers lbAdd _displayName;
        _ctrlSoldiers lbSetData [_newIndex, _className];
        _ctrlSoldiers lbSetColor [_newIndex, [0.6, 1, 0.2, 1]];
        
        // Met à jour les compteurs
        ["UPDATE_COUNTERS"] call MISSION_fnc_spawn_ennemies;
        
        playSound "3DEN_notificationDefault";
    };
    
    // ============================================================================
    // UPDATE_COUNTERS - Met à jour les compteurs affichés
    // ============================================================================
    case "UPDATE_COUNTERS": {
        disableSerialization;
        private _display = findDisplay 7777;
        if (isNull _display) exitWith {};
        
        private _ctrlCountOfficers = _display displayCtrl 3002;
        private _ctrlCountSoldiers = _display displayCtrl 3005;
        
        _ctrlCountOfficers ctrlSetText format ["%1 / 3", count ENEMIES_temp_officers];
        _ctrlCountSoldiers ctrlSetText format ["%1 / 12", count ENEMIES_temp_soldiers];
        
        // Change la couleur si complet
        if (count ENEMIES_temp_officers >= 3) then {
            _ctrlCountOfficers ctrlSetTextColor [0, 1, 0, 1];
        } else {
            _ctrlCountOfficers ctrlSetTextColor [1, 0.8, 0, 1];
        };
        
        if (count ENEMIES_temp_soldiers >= 12) then {
            _ctrlCountSoldiers ctrlSetTextColor [0, 1, 0, 1];
        } else {
            _ctrlCountSoldiers ctrlSetTextColor [0.6, 1, 0.2, 1];
        };
    };
    
    // ============================================================================
    // VALIDATE - Valide la sélection et met à jour la mémoire
    // ============================================================================
    case "VALIDATE": {
        // Vérifie que la sélection est complète
        if (count ENEMIES_temp_officers < 3 || count ENEMIES_temp_soldiers < 12) exitWith {
            hint localize "STR_ERR_SELECTION_INCOMPLETE";
        };
        
        // Met à jour MISSION_var_officers avec les nouveaux types
        private _newOfficers = [];
        {
            _x params ["_className", "_displayName"];
            // Format: [NomVariable, ClassName, Position, Direction, Camp, Loadout]
            private _varName = format ["task_x_officer_%1", _forEachIndex + 1];
            _newOfficers pushBack [_varName, _className, [0,0,0], 0, east, []];
        } forEach ENEMIES_temp_officers;
        
        MISSION_var_officers = _newOfficers;
        
        // Met à jour MISSION_var_enemies avec les nouveaux types
        private _newEnemies = [];
        {
            _x params ["_className", "_displayName"];
            private _numStr = if (_forEachIndex < 10) then { format ["0%1", _forEachIndex] } else { str _forEachIndex };
            private _varName = format ["task_x_enemy_%1", _numStr];
            _newEnemies pushBack [_varName, _className, [0,0,0], 0, east, []];
        } forEach ENEMIES_temp_soldiers;
        
        MISSION_var_enemies = _newEnemies;
        
        // Notification de confirmation
        hint format [
            localize "STR_ENEMIES_UPDATED",
            count ENEMIES_temp_officers,
            count ENEMIES_temp_soldiers
        ];
        
        playSound "3DEN_notificationDefault";
        closeDialog 0;
    };
    
    // ============================================================================
    // RESET - Réinitialise la sélection
    // ============================================================================
    case "RESET": {
        disableSerialization;
        private _display = findDisplay 7777;
        if (isNull _display) exitWith {};
        
        // Vide les listes temporaires
        ENEMIES_temp_officers = [];
        ENEMIES_temp_soldiers = [];
        
        // Vide les ListBox
        private _ctrlOfficers = _display displayCtrl 3003;
        private _ctrlSoldiers = _display displayCtrl 3006;
        
        lbClear _ctrlOfficers;
        lbClear _ctrlSoldiers;
        
        // Met à jour les compteurs
        ["UPDATE_COUNTERS"] call MISSION_fnc_spawn_ennemies;
        
        hint localize "STR_ENEMIES_RESET";
    };
};
