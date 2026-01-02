/*
    =========================================================================
    fn_task_1_launch.sqf - Tâche 1 : Chasse à l'Homme
    =========================================================================
    
    LOGIQUE:
    - 2 fugitifs (random sur 3) tentent de s'échapper en bateau
    - Les fugitifs suivent des chemins (7 chemins de 6 waypoints)
    - Spawn après 5 minutes de délai
    - REDDITION: Si joueur < 15m avant WP6 → mains levées, setCaptive
    - ARMEMENT: Au WP6, le fugitif s'arme et devient OPFOR
    - VICTOIRE: Tous les fugitifs capturés OU morts
    - ÉCHEC: Un fugitif entre dans le trigger d'échappement
    
    =========================================================================
*/

// Sécurité : Code exécuté uniquement sur le serveur
if (!isServer) exitWith {};

// Attend que les templates soient initialisés
waitUntil { !isNil "MISSION_var_fugitives" };
if (count MISSION_var_fugitives == 0) exitWith {
    systemChat "ERREUR: Aucun fugitif en mémoire!";
};

// ============================================================================
// SECTION 1: CONFIGURATION
// ============================================================================

// Définition des 7 chemins (chaque chemin : 6 waypoints)
private _paths = [
    ["task_1_spawn_01", "task_1_spawn_02", "task_1_spawn_03", "task_1_spawn_04", "task_1_spawn_05", "task_1_spawn_06"],
    ["task_1_spawn_07", "task_1_spawn_08", "task_1_spawn_09", "task_1_spawn_10", "task_1_spawn_11", "task_1_spawn_12"],
    ["task_1_spawn_13", "task_1_spawn_14", "task_1_spawn_15", "task_1_spawn_16", "task_1_spawn_17", "task_1_spawn_18"],
    ["task_1_spawn_19", "task_1_spawn_20", "task_1_spawn_21", "task_1_spawn_22", "task_1_spawn_23", "task_1_spawn_24"],
    ["task_1_spawn_25", "task_1_spawn_26", "task_1_spawn_27", "task_1_spawn_28", "task_1_spawn_29", "task_1_spawn_30"],
    ["task_1_spawn_31", "task_1_spawn_32", "task_1_spawn_33", "task_1_spawn_34", "task_1_spawn_35", "task_1_spawn_36"],
    ["task_1_spawn_37", "task_1_spawn_38", "task_1_spawn_39", "task_1_spawn_40", "task_1_spawn_41", "task_1_spawn_42"]
];

// Variables globales pour le suivi
MISSION_var_task1_running = true;
MISSION_var_task1_fugitives = [];
MISSION_var_task1_boats = [];
MISSION_var_task1_escape_trigger = objNull;

// ============================================================================
// SECTION 2: CRÉATION DE LA TÂCHE
// ============================================================================

private _taskID = "task_1";

// Position centrale pour la tâche (premier waypoint du premier chemin)
private _firstSpawn = missionNamespace getVariable ["task_1_spawn_01", objNull];
private _taskPos = if (!isNull _firstSpawn) then { getPos _firstSpawn } else { [0,0,0] };

[
    true,
    [_taskID],
    [localize "STR_TASK_1_DESC", localize "STR_TASK_1_TITLE", ""],
    _taskPos,
    "CREATED",
    1,
    true,
    "search"
] call BIS_fnc_taskCreate;

// Notification de démarrage
hint (localize "STR_NOTIF_TASK1_START");

// ============================================================================
// SECTION 3: SÉLECTION ALÉATOIRE DES FUGITIFS ET CHEMINS
// ============================================================================

// Sélectionner 2 fugitifs parmi 3
private _fugitiveTemplates = MISSION_var_fugitives call BIS_fnc_arrayShuffle;
_fugitiveTemplates = _fugitiveTemplates select [0, 2]; // Prendre les 2 premiers

// Sélectionner 2 chemins différents parmi 7
private _availablePaths = [0, 1, 2, 3, 4, 5, 6] call BIS_fnc_arrayShuffle;
private _selectedPaths = _availablePaths select [0, 2];

// ============================================================================
// SECTION 4: SPAWN DIFFÉRÉ (5 MINUTES)
// ============================================================================

[_fugitiveTemplates, _selectedPaths, _paths, _taskID] spawn {
    params ["_fugitiveTemplates", "_selectedPaths", "_paths", "_taskID"];
    
    // Attendre 5 minutes (300 secondes)
    sleep 3;
    
    // Vérifier si la tâche est toujours active
    if (!MISSION_var_task1_running) exitWith {};
    
    // Notification
    hint (localize "STR_HINT_FUGITIVES_SPOTTED");
    
    // ========================================================================
    // SPAWN DES BATEAUX
    // ========================================================================
    {
        _x params ["_name", "_type", "_pos", "_dir", "_side", "_extra"];
        
        // Position du bateau (utiliser task_1_boat_place_X)
        private _idx = _forEachIndex + 1;
        private _placeMarker = format ["task_1_boat_place_%1", _idx];
        private _placeObj = missionNamespace getVariable [_placeMarker, objNull];
        
        if (!isNull _placeObj) then {
            private _boatPos = getPos _placeObj;
            private _boat = createVehicle [_type, _boatPos, [], 0, "NONE"];
            _boat setDir (getDir _placeObj);
            _boat setFuel 1;
            
            // Direction marker pour la fuite
            private _dirMarker = format ["task_1_boat_direction_%1", _idx];
            private _dirObj = missionNamespace getVariable [_dirMarker, objNull];
            if (!isNull _dirObj) then {
                _boat setVariable ["escapeDirection", getPos _dirObj, true];
            };
            
            MISSION_var_task1_boats pushBack _boat;
        };
    } forEach MISSION_var_boats;
    
    // ========================================================================
    // RECRÉATION DU TRIGGER D'ÉCHAPPEMENT
    // ========================================================================
    if (count MISSION_var_escape_trigger > 0) then {
        MISSION_var_escape_trigger params ["_trigPos", "_trigDir", "_trigArea"];
        
        private _trigger = createTrigger ["EmptyDetector", _trigPos, false];
        _trigger setTriggerArea _trigArea;
        _trigger setDir _trigDir;
        _trigger setTriggerActivation ["EAST", "PRESENT", false];
        _trigger setTriggerStatements [
            "this && {_x getVariable ['isFugitive', false]} count thisList > 0",
            "MISSION_var_task1_escaped = true;",
            ""
        ];
        
        MISSION_var_task1_escape_trigger = _trigger;
    };
    
    // ========================================================================
    // SPAWN DES FUGITIFS
    // ========================================================================
    private _grpFugitives = createGroup [east, true];
    
    {
        private _template = _x;
        private _pathIndex = _selectedPaths select _forEachIndex;
        private _path = _paths select _pathIndex;
        private _boatIndex = _pathIndex; // Chemin X → Bateau X
        
        _template params ["_name", "_type", "_pos", "_dir", "_side", "_loadout"];
        
        // Position de départ (WP1 du chemin)
        private _startMarker = _path select 0;
        private _startObj = missionNamespace getVariable [_startMarker, objNull];
        
        if (!isNull _startObj) then {
            private _spawnPos = getPos _startObj;
            
            // Créer le fugitif
            private _fugitive = _grpFugitives createUnit [_type, _spawnPos, [], 0, "NONE"];
            _fugitive setUnitLoadout _loadout;
            _fugitive setDir (getDir _startObj);
            
            // Variables de contrôle
            _fugitive setVariable ["isFugitive", true, true];
            _fugitive setVariable ["isCaptured", false, true];
            _fugitive setVariable ["isArmed", false, true];
            _fugitive setVariable ["currentWP", 0, true];
            _fugitive setVariable ["assignedPath", _path, true];
            _fugitive setVariable ["assignedBoatIndex", _boatIndex, true];
            
            // Comportement initial (civil en fuite)
            _fugitive setCaptive true;
            _fugitive setBehaviour "CARELESS";
            _fugitive setSpeedMode "FULL";       
            _fugitive forceSpeed 6;
            
            // Désarmer le fugitif
            removeAllWeapons _fugitive;
            
            MISSION_var_task1_fugitives pushBack _fugitive;
            
            // Thread individuel pour chaque fugitif
            [_fugitive, _path, _boatIndex] spawn {
                params ["_fugitive", "_path", "_boatIndex"];
                
                private _wpIndex = 0;
                
                // Constantes d'animation pour la cohérence
                private _animSurrenderStand = "AmovPercMstpSsurWnonDnon";  // Debout, mains sur la tête
                private _animSurrenderKneel = "AmovPknlMstpSsurWnonDnon";  // À genoux, mains sur la tête
                
                while {alive _fugitive && !(_fugitive getVariable ["isCaptured", false]) && MISSION_var_task1_running} do {
                    
                    // LOGIQUE DE REDDITION (avant WP6)
                    if (_wpIndex < 5 && alive _fugitive && !(_fugitive getVariable ["isCaptured", false])) then {
                        
                        private _nearestPlayer = objNull;
                        private _nearestDist = 9999;
                        
                        // Trouver le joueur le plus proche
                        {
                            private _d = _x distance _fugitive;
                            if (alive _x && _d < _nearestDist) then {
                                _nearestDist = _d;
                                _nearestPlayer = _x;
                            };
                        } forEach allPlayers;
                        
                        // DEBUG: Afficher la distance
                        hint format ["DEBUG: Distance = %1m | Surrendered = %2 | HasAction = %3", 
                            round _nearestDist, 
                            _fugitive getVariable ["isSurrendered", false],
                            _fugitive getVariable ["hasSubmitAction", false]];
                        
                        // ETAPE 1: REDDITION (15m)
                        if (!(_fugitive getVariable ["isSurrendered", false])) then {
                            if (_nearestDist < 15) then {
                                systemChat "DEBUG: Etape 1 - REDDITION";
                                _fugitive setVariable ["isSurrendered", true, true];
                                _fugitive setCaptive true;
                                doStop _fugitive;
                                _fugitive disableAI "PATH";
                                _fugitive disableAI "MOVE";
                                _fugitive setVelocity [0,0,0];
                                _fugitive playMoveNow _animSurrenderStand;
                                _fugitive setCombatMode "BLUE";
                                _fugitive setBehaviour "CARELESS";
                                [_fugitive] spawn {
                                    params ["_unit"];
                                    sleep 2;
                                    if (alive _unit) then {
                                        _unit disableAI "ANIM";
                                    };
                                };
                                hint "ETAPE 1: Le suspect se rend! Approchez a 5m.";
                            };
                        } else {
                            // ---------------------------------------------------------
                            // ETAPE 2 : INTERCEPTION (5 metres) - Le fugitif s'agenouille
                            // ---------------------------------------------------------
                            if (_nearestDist < 5 && !(_fugitive getVariable ["hasSubmitAction", false])) then {
                                systemChat "DEBUG: Etape 2 - INTERCEPTION";
                                
                                // 1. Marquer comme action prete et afficher marqueur IMMEDIATEMENT
                                _fugitive setVariable ["hasSubmitAction", true, true];
                                
                                // 2. Créer un marqueur
                                private _markerName = format ["captive_marker_%1", floor(random 99999)];
                                private _marker = createMarker [_markerName, getPos _fugitive];
                                _marker setMarkerType "hd_dot";
                                _marker setMarkerColor "ColorBlue";
                                _marker setMarkerText (localize "STR_MARKER_CAPTIVE");
                                _fugitive setVariable ["captiveMarker", _markerName, true];
                                
                                // 3. Ajouter l'action via remoteExec pour MP
                                private _actionText = localize "STR_ACTION_SUBMIT";
                                [
                                    _fugitive,
                                    [
                                        _actionText,
                                        {
                                            params ["_target", "_caller", "_actionId"];
                                            _target setVariable ["isCaptured", true, true];
                                            _target removeAction _actionId;
                                            
                                            private _m = _target getVariable ["captiveMarker", ""];
                                            if (_m != "") then { deleteMarker _m; };
                                            
                                            // Forcer a rester a genoux (capture)
                                            _target disableAI "MOVE";
                                            _target disableAI "PATH";
                                            _target disableAI "FSM";
                                            _target enableAI "ANIM";
                                            
                                            // Animation: A genoux mains sur la tete (capture)
                                            _target playMoveNow "AmovPknlMstpSsurWnonDnon";
                                            
                                            // Verrouiller apres transition
                                            [_target] spawn {
                                                params ["_unit"];
                                                sleep 1;
                                                if (alive _unit) then {
                                                    _unit disableAI "ANIM";
                                                };
                                            };
                                            
                                            hint "CAPTURE REUSSIE!";
                                            playSound "3DEN_notificationDefault";
                                        },
                                        nil, 6, true, true, "",
                                        "alive _target && _this distance _target < 5"
                                    ]
                                ] remoteExec ["addAction", 0, _fugitive];
                                
                                systemChat "DEBUG: Action ajoutee!";
                                hint "ETAPE 2: Utilisez l'action 'Soumettre' (molette)";
                                
                                // 4. GESTION DE L'ANIMATION (SPAWN pour ne pas bloquer la boucle)
                                [_fugitive] spawn {
                                    params ["_fugitive"];
                                    
                                    // REACTIVER COMPLETEMENT L'IA POUR UNE TRANSITION NATURELLE
                                    _fugitive enableAI "ANIM";
                                    _fugitive enableAI "MOVE";
                                    _fugitive enableAI "PATH";
                                    
                                    // Forcer le fugitif a s'asseoir naturellement (position a genoux)
                                    _fugitive action ["SitDown", _fugitive];
                                    
                                    // Attendre que l'animation soit terminee (2 secondes)
                                    sleep 2;
                                    
                                    // Une fois assis, jouer l'animation de reddition a genoux
                                    _fugitive playMoveNow "AmovPknlMstpSsurWnonDnon";
                                    
                                    // Figer a nouveau l'IA apres la transition
                                    sleep 0.5; // Petit delai pour laisser l'animation se stabiliser
                                    if (alive _fugitive) then {
                                        _fugitive disableAI "ANIM";
                                        _fugitive disableAI "MOVE";
                                        _fugitive disableAI "PATH";
                                        _fugitive disableAI "FSM";
                                        _fugitive setVelocity [0,0,0];
                                    };
                                };
                            };
                        };
                    };
                    
                    // Ré-appliquer l'animation si l'IA l'a overridée
                    if (_fugitive getVariable ["isSurrendered", false]) then {
                        private _currentAnim = animationState _fugitive;
                        // Utiliser animation a genoux si action deja ajoutee, sinon debout
                        private _targetAnim = if (_fugitive getVariable ["hasSubmitAction", false]) then { _animSurrenderKneel } else { _animSurrenderStand };
                        
                        if (_currentAnim != _targetAnim) then {
                            _fugitive enableAI "ANIM";
                            _fugitive playMoveNow _targetAnim;
                            [_fugitive] spawn {
                                params ["_unit"];
                                sleep 1;
                                if (alive _unit) then { _unit disableAI "ANIM"; };
                            };
                        };
                        sleep 1;
                    } else {
                        // Mouvement uniquement si PAS rendu
                        // Déplacement vers le waypoint actuel
                        if (_wpIndex < count _path) then {
                            private _wpMarker = _path select _wpIndex;
                            private _wpObj = missionNamespace getVariable [_wpMarker, objNull];
                            
                            if (!isNull _wpObj) then {
                                private _wpPos = getPos _wpObj;
                                _fugitive doMove _wpPos;
                                
                                // Attendre d'arriver au waypoint (avec check de reddition)
                                waitUntil {
                                    sleep 0.5;
                                    !alive _fugitive || 
                                    (_fugitive getVariable ["isCaptured", false]) ||
                                    (_fugitive getVariable ["isSurrendered", false]) ||
                                    (_fugitive distance2D _wpPos < 3) ||
                                    !MISSION_var_task1_running
                                };
                            
                            if (!alive _fugitive || _fugitive getVariable ["isCaptured", false] || !MISSION_var_task1_running) exitWith {};
                            
                            _fugitive setVariable ["currentWP", _wpIndex, true];
                            
                            // ARMEMENT au WP6 (index 5)
                            if (_wpIndex == 5 && !(_fugitive getVariable ["isArmed", false])) then {
                                _fugitive setVariable ["isArmed", true, true];
                                
                                // Donner une arme
                                _fugitive addMagazine "16Rnd_9x21_Mag";
                                _fugitive addMagazine "16Rnd_9x21_Mag";
                                _fugitive addWeapon "hgun_P07_F";
                                
                                // Devenir OPFOR hostile
                                _fugitive setCaptive false;
                                
                                // Notification globale
                                [localize "STR_HINT_FUGITIVE_ARMED"] remoteExec ["hint", 0];
                            };
                            
                            _wpIndex = _wpIndex + 1;
                        };
                        } else {
                            // Tous les WP parcourus, entrer dans le bateau
                            private _boat = MISSION_var_task1_boats select _boatIndex;
                            
                            if (!isNull _boat && alive _boat) then {
                                _fugitive doMove (getPos _boat);
                                
                                waitUntil {
                                    sleep 0.5;
                                    !alive _fugitive || 
                                    (_fugitive getVariable ["isCaptured", false]) ||
                                    (_fugitive getVariable ["isSurrendered", false]) ||
                                    (_fugitive distance _boat < 5) ||
                                    !MISSION_var_task1_running
                                };
                                
                                if (alive _fugitive && !(_fugitive getVariable ["isCaptured", false]) && !(_fugitive getVariable ["isSurrendered", false])) then {
                                    _fugitive moveInDriver _boat;
                                    
                                    // Fuir vers la direction d'échappement
                                    private _escapeDir = _boat getVariable ["escapeDirection", []];
                                    if (count _escapeDir > 0) then {
                                        _boat doMove _escapeDir;
                                        _boat setSpeedMode "FULL";
                                    };
                                };
                            };
                            
                            break;
                        };
                    };  // Fin du else (mouvement uniquement si PAS rendu)
                };
            };
        };
    } forEach _fugitiveTemplates;
};

// ============================================================================
// SECTION 5: BOUCLE DE SURVEILLANCE (Victoire/Défaite)
// ============================================================================

MISSION_var_task1_escaped = false;

[] spawn {
    private _taskID = "task_1";
    
    // Attendre le spawn des fugitifs
    waitUntil { sleep 1; count MISSION_var_task1_fugitives > 0 || !MISSION_var_task1_running };
    
    while {MISSION_var_task1_running} do {
        sleep 2;
        
        // Condition d'échec : Un fugitif s'est échappé
        if (MISSION_var_task1_escaped) exitWith {
            [_taskID, "FAILED"] call BIS_fnc_taskSetState;
            hint (localize "STR_NOTIF_TASK1_FAILED");
            MISSION_var_task1_running = false;
        };
        
        // Compter les fugitifs neutralisés (morts ou capturés)
        private _neutralized = 0;
        private _total = count MISSION_var_task1_fugitives;
        
        {
            if (!alive _x || (_x getVariable ["isCaptured", false])) then {
                _neutralized = _neutralized + 1;
            };
        } forEach MISSION_var_task1_fugitives;
        
        // Condition de victoire : Tous neutralisés
        if (_neutralized >= _total && _total > 0) exitWith {
            [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
            [] spawn MISSION_fnc_task_x_finish;
            MISSION_var_task1_running = false;
        };
    };
};
