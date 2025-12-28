/*
    Description :
    Cette fonction gère le système de sélection et de lancement de missions.
    Elle comprend l'interface utilisateur, la sélection multiple de tâches et leur exécution.
    Modes : INIT, OPEN, SELECT, TOGGLE, LAUNCH.
*/

params [["_mode", ""], ["_args", []]];

// Variable globale pour stocker les tâches sélectionnées par le joueur (liste des ID de tâches)
if (isNil "MISSION_var_selected_tasks") then { MISSION_var_selected_tasks = []; };
// Variable globale pour garder en mémoire l'index de la tâche actuellement affichée dans l'interface
if (isNil "MISSION_var_current_task_index") then { MISSION_var_current_task_index = 0; };

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
    createDialog "Refour_Missions_Dialog";
    
    private _listCtrl = (findDisplay 7777) displayCtrl 2200; // Liste des missions
    
    // Remplir la liste avec 20 emplacements de tâches
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
        if (_i > 3) then {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_X_TITLE"];
        };
        
        private _index = _listCtrl lbAdd _taskName;
        _listCtrl lbSetData [_index, str _i]; // Stocke l'ID de la mission (1 à 20)
        
        // Si la tâche est déjà dans la liste de sélection, l'afficher en vert
        if (_i in MISSION_var_selected_tasks) then {
            _listCtrl lbSetColor [_index, [0.2, 0.8, 0.2, 1]];
        };
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
    private _checkCtrl = (findDisplay 7777) displayCtrl 2201; // Bouton de sélection (Toggle)
    
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
    if (_taskNum > 3) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_X_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_X_DESC");
    };
    
    // Met à jour l'apparence du bouton "Sélectionner/Désélectionner"
    if (_taskNum in MISSION_var_selected_tasks) then {
        // Déjà sélectionné : Bouton en vert, texte "Désélectionner"
        _checkCtrl ctrlSetBackgroundColor [0.2, 0.6, 0.2, 1];
        _checkCtrl ctrlSetText (localize "STR_BTN_DESELECT");
    } else {
        // Non sélectionné : Bouton gris, texte "Sélectionner"
        _checkCtrl ctrlSetBackgroundColor [0.3, 0.3, 0.3, 1];
        _checkCtrl ctrlSetText (localize "STR_BTN_SELECT");
    };
};

// ============================================================================
// TOGGLE - Action du bouton "Sélectionner/Désélectionner"
// ============================================================================
if (_mode == "TOGGLE") exitWith {
    private _taskNum = MISSION_var_current_task_index;
    if (_taskNum == 0) exitWith {}; // Sécurité
    
    private _checkCtrl = (findDisplay 7777) displayCtrl 2201;
    private _listCtrl = (findDisplay 7777) displayCtrl 2200;
    
    if (_taskNum in MISSION_var_selected_tasks) then {
        // Action : Désélectionner
        MISSION_var_selected_tasks = MISSION_var_selected_tasks - [_taskNum];
        // Interface : Bouton gris, texte en "Sélectionner", liste en blanc
        _checkCtrl ctrlSetBackgroundColor [0.3, 0.3, 0.3, 1];
        _checkCtrl ctrlSetText (localize "STR_BTN_SELECT");
        _listCtrl lbSetColor [_taskNum - 1, [1, 1, 1, 1]];
    } else {
        // Action : Sélectionner
        MISSION_var_selected_tasks pushBack _taskNum;
        // Interface : Bouton vert, texte en "Désélectionner", liste en vert
        _checkCtrl ctrlSetBackgroundColor [0.2, 0.6, 0.2, 1];
        _checkCtrl ctrlSetText (localize "STR_BTN_DESELECT");
        _listCtrl lbSetColor [_taskNum - 1, [0.2, 0.8, 0.2, 1]];
    };
};

// ============================================================================
// LAUNCH - Lancement effectif des missions
// ============================================================================
if (_mode == "LAUNCH") exitWith {
    closeDialog 0; // Ferme l'interface
    
    if (count MISSION_var_selected_tasks == 0) exitWith {}; // Rien à faire si aucune tâche sélectionnée
    
    // Itère sur toutes les tâches sélectionnées
    {
        private _taskID = format ["task_%1", _x];
        
        // Vérifie si la tâche est déjà active via le système de tâches de BIS
        if ([_taskID] call BIS_fnc_taskExists) then {
            systemChat format [localize "STR_TASK_ALREADY_ACTIVE", _x];
            hint format [localize "STR_TASK_ALREADY_ACTIVE", _x];
        } else {
            // Lance la fonction correspondante à la tâche
            switch (_x) do {
                case 1: {
                    // Tâche 1 - Défense du QG
                    [] call MISSION_fnc_task_1_launch;
                };
                case 2: {
                    // Tâche 2 - Assassinat et récupération
                    [] call MISSION_fnc_task_2_launch;
                };
                case 3: {
                    // Tâche 3 - Guerre totale
                    ["INIT"] call MISSION_fnc_task_3_launch;
                };
                // Tâches 3-20 : à implémenter plus tard
                default {};
            };
        };
    } forEach MISSION_var_selected_tasks;
    
    // Réinitialise la liste des sélections après le lancement
    MISSION_var_selected_tasks = [];
};
