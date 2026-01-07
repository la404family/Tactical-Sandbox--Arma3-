/*
    Description :
    Cette fonction gère le système de sélection et de lancement de missions.
    Elle comprend l'interface utilisateur et l'exécution d'UNE SEULE mission.
    Les missions ne sont PAS cumulables.
    Modes : INIT, OPEN, SELECT, LAUNCH.
*/

params [["_mode", ""], ["_args", []]];

// Variable globale pour garder en mémoire l'index de la tâche actuellement affichée dans l'interface
if (isNil "MISSION_var_current_task_index") then { MISSION_var_current_task_index = 0; };

// Variable globale pour savoir si une mission est déjà en cours
if (isNil "MISSION_var_mission_active") then { MISSION_var_mission_active = false; };

// ============================================================================
// INIT - Initialisation de l'interaction
// ============================================================================
if (_mode == "INIT") exitWith {
    [] spawn {
        waitUntil {time > 0};
        
        // Ajoute l'action au joueur pour ouvrir le menu des missions
        player addAction [
            localize "STR_ACTION_MISSIONS",
            { ["OPEN"] call MISSION_fnc_spawn_missions; },
            [],
            1.5,
            true,
            true,
            "",
            "player inArea missions_request" // Visible uniquement dans la zone dédiée
        ];
    };
};

// ============================================================================
// OPEN - Ouverture du dialogue et initialisation de la liste
// ============================================================================
if (_mode == "OPEN") exitWith {
    // Vérifie si une mission est déjà en cours
    if (MISSION_var_mission_active) exitWith {
        hint (localize "STR_MISSION_ALREADY_ACTIVE");
    };
    
    createDialog "Refour_Missions_Dialog";
    
    private _listCtrl = (findDisplay 7777) displayCtrl 2200; // Liste des missions
    
    // Remplir la liste avec les tâches disponibles
    for "_i" from 1 to 20 do {
        private _taskName = "";
        
        // Définition conditionnelle des noms de tâches (localisés)
        if (_i == 1) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_1_TITLE"];
        };
        if (_i == 2) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_2_TITLE"];
        };
        if (_i == 3) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_3_TITLE"];
        };
        if (_i == 4) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_4_TITLE"];
        };
        if (_i == 5) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_5_TITLE"];
        };
        if (_i == 6) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_6_TITLE"];
        };
        if (_i == 7) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_7_TITLE"];
        };
        if (_i > 7) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_X_TITLE"];
        };
        
        private _index = _listCtrl lbAdd _taskName;
        _listCtrl lbSetData [_index, str _i]; // Stocke l'ID de la mission (1 à 20)
    };
    
    // Sélectionne la première tâche par défaut
    _listCtrl lbSetCurSel 0;
};

// ============================================================================
// SELECT - Gestion du clic sur un élément de la liste
// ============================================================================
if (_mode == "SELECT") exitWith {
    _args params ["_ctrl", "_selIndex"];
    
    // Récupère l'ID de la tâche sélectionnée
    private _taskNum = parseNumber (_ctrl lbData _selIndex);
    MISSION_var_current_task_index = _taskNum;
    
    private _titleCtrl = (findDisplay 7777) displayCtrl 2202; // Titre
    private _descCtrl = (findDisplay 7777) displayCtrl 2203;  // Description
    
    // Mise à jour de l'affichage (Titre et Description) selon la tâche
    if (_taskNum == 1) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_1_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_1_DESC");
    };
    if (_taskNum == 2) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_2_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_2_DESC");
    };
    if (_taskNum == 3) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_3_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_3_DESC");
    };
    if (_taskNum == 4) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_4_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_4_DESC");
    };
    if (_taskNum == 5) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_5_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_5_DESC");
    };
    if (_taskNum == 6) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_6_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_6_DESC");
    };
    if (_taskNum == 7) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_7_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_7_DESC");
    };
    if (_taskNum > 7) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_X_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_X_DESC");
    };
};

// ============================================================================
// LAUNCH - Lancement de la mission sélectionnée (UNE SEULE)
// ============================================================================
if (_mode == "LAUNCH") exitWith {
    // Vérifie si le joueur est le leader du groupe
    if (player != leader group player) exitWith {
        hint (localize "STR_ONLY_GROUP_LEADER");
    };
    private _taskNum = MISSION_var_current_task_index;
    
    closeDialog 0; // Ferme l'interface
    
    if (_taskNum == 0) exitWith {}; // Sécurité : aucune tâche sélectionnée
    
    private _taskID = format ["task_%1", _taskNum];
    
    // Vérifie si la tâche est déjà active via le système de tâches de BIS
    if ([_taskID] call BIS_fnc_taskExists) exitWith {
        hint format [localize "STR_TASK_ALREADY_ACTIVE", _taskNum];
    };
    
    // Marque qu'une mission est maintenant active
    MISSION_var_mission_active = true;
    publicVariable "MISSION_var_mission_active";
    
    // Lance la fonction correspondante à la tâche
    switch (_taskNum) do {
        case 1: {
            // Tâche 1 - Défense du QG
            [] call MISSION_fnc_task_1_launch;
        };
        case 2: {
            // Tâche 2 - Assassinat et récupération
            [] call MISSION_fnc_task_2_launch;
        };
        case 3: {
            // Tâche 3 - Destruction de cargaisons
            ["INIT"] call MISSION_fnc_task_3_launch;
        };
        case 4: {
            // Tâche 4 - Exfiltration otages
            [] spawn MISSION_fnc_task_4_launch;
        };
        case 5: {
            // Tâche 5 - Présence Civile & Désamorçage
            [] spawn MISSION_fnc_task_5_launch;
        };
        case 6: {
            // Tâche 6 - Sauvetage des alliés
            // Utilisation de execVM pour forcer le rechargement du fichier à chaque lancement (Debug)
            [] execVM "functions\fn_task_6_launch.sqf";
        };
        case 7: {
            // Tâche 7 - Destruction de Radar
            [] spawn MISSION_fnc_task_7_launch;
        };
        // Tâches 8-20 : à implémenter plus tard
        default {};
    };
};
