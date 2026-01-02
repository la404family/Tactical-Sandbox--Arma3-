// ============================================================================
// SCRIPT COMPLET POUR LA TÂCHE "CHASSE À L'HOMME" - ARMA 3 SQF
// Optimisé avec FSM par fugitif, boucles efficaces, et variables globales minimales.
// ============================================================================

// ============================================================================
// SECTION 1: INITIALISATION ET CONFIGURATION
// ============================================================================

MISSION_var_task1_running = true;
MISSION_var_task1_fugitives = [];
MISSION_var_task1_boats = [];
MISSION_var_task1_escaped = false;

// Définition des 7 chemins (chaque chemin : array de 6 marqueurs string)
private _paths = [
    ["task_1_spawn_01", "task_1_spawn_02", "task_1_spawn_03", "task_1_spawn_04", "task_1_spawn_05", "task_1_spawn_06"],
    ["task_1_spawn_07", "task_1_spawn_08", "task_1_spawn_09", "task_1_spawn_10", "task_1_spawn_11", "task_1_spawn_12"],
    ["task_1_spawn_13", "task_1_spawn_14", "task_1_spawn_15", "task_1_spawn_16", "task_1_spawn_17", "task_1_spawn_18"],
    ["task_1_spawn_19", "task_1_spawn_20", "task_1_spawn_21", "task_1_spawn_22", "task_1_spawn_23", "task_1_spawn_24"],
    ["task_1_spawn_25", "task_1_spawn_26", "task_1_spawn_27", "task_1_spawn_28", "task_1_spawn_29", "task_1_spawn_30"],
    ["task_1_spawn_31", "task_1_spawn_32", "task_1_spawn_33", "task_1_spawn_34", "task_1_spawn_35", "task_1_spawn_36"],
    ["task_1_spawn_37", "task_1_spawn_38", "task_1_spawn_39", "task_1_spawn_40", "task_1_spawn_41", "task_1_spawn_42"]
];

// ============================================================================
// SECTION 2: CRÉATION DE LA TÂCHE
// ============================================================================

private _taskID = "task_1";

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

hint (localize "STR_NOTIF_TASK1_START");

// ============================================================================
// SECTION 3: SÉLECTION ALÉATOIRE DES FUGITIFS ET CHEMINS
// ============================================================================

private _fugitiveTemplates = MISSION_var_fugitives call BIS_fnc_arrayShuffle;
_fugitiveTemplates = _fugitiveTemplates select [0, 2];

private _availablePaths = [0,1,2,3,4,5,6] call BIS_fnc_arrayShuffle;
private _selectedPaths = _availablePaths select [0, 2];

// ============================================================================
// SECTION 4: SPAWN DIFFÉRÉ (5 MINUTES)
// ============================================================================

[_fugitiveTemplates, _selectedPaths, _paths, _taskID] spawn {
    params ["_fugitiveTemplates", "_selectedPaths", "_paths", "_taskID"];
    
    // Attendre 5 minutes (300 secondes)
    sleep 3;
    
    if (!MISSION_var_task1_running) exitWith {};
    
    hint (localize "STR_HINT_FUGITIVES_SPOTTED");
    
    // ========================================================================
    // SPAWN DES BATEAUX (AUX POSITIONS DES PATHS SÉLECTIONNÉS)
    // ========================================================================
    MISSION_var_task1_boats = [];
    {
        private _pathIdx = _selectedPaths select _forEachIndex;
        private _idx = _pathIdx + 1;
        private _boatCfg = MISSION_var_boats select _forEachIndex;
        _boatCfg params ["_name", "_type", "_pos", "_dir", "_side", "_extra"];
        
        private _placeMarker = format ["task_1_boat_place_%1", _idx];
        private _placeObj = missionNamespace getVariable [_placeMarker, objNull];
        
        if (!isNull _placeObj) then {
            private _boatPos = getPos _placeObj;
            private _boat = createVehicle [_type, _boatPos, [], 0, "NONE"];
            _boat setDir (getDir _placeObj);
            _boat setFuel 1;
            
            // Direction d'échappement
            private _dirMarker = format ["task_1_boat_direction_%1", _idx];
            private _dirObj = missionNamespace getVariable [_dirMarker, objNull];
            if (!isNull _dirObj) then {
                _boat setVariable ["escapeDirection", getPos _dirObj, true];
            };
            
            MISSION_var_task1_boats pushBack _boat;
        };
    } forEach [0,1];
    
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
        private _boatIndex = _forEachIndex; // 0 ou 1 (ordre spawn)
        
        _template params ["_name", "_type", "_pos", "_dir", "_side", "_loadout"];
        
        private _startMarker = _path select 0;
        private _startObj = missionNamespace getVariable [_startMarker, objNull];
        
        if (!isNull _startObj) then {
            private _spawnPos = getPos _startObj;
            
            private _fugitive = _grpFugitives createUnit [_type, _spawnPos, [], 0, "NONE"];
            _fugitive setUnitLoadout _loadout;
            _fugitive setDir (getDir _startObj);
            
            // Variables de contrôle
            _fugitive setVariable ["isFugitive", true, true];
            _fugitive setVariable ["isCaptured", false, true];
            _fugitive setVariable ["isArmed", false, true];
            _fugitive setVariable ["isSurrendered", false, true];
            _fugitive setVariable ["isKneeling", false, true];
            _fugitive setVariable ["request_capture", false, true];
            _fugitive setVariable ["currentWP", 0, true];
            _fugitive setVariable ["assignedPath", _path, true];
            _fugitive setVariable ["assignedBoatIndex", _boatIndex, true];
            _fugitive setVariable ["boarded", false, true];
            
            // Comportement initial
            _fugitive setCaptive true;
            _fugitive setBehaviour "CARELESS";
            _fugitive setSpeedMode "FULL";
            _fugitive forceSpeed 6;
            removeAllWeapons _fugitive;
            
            MISSION_var_task1_fugitives pushBack _fugitive;
            
            // THREAD FSM INDIVIDUEL
            [_fugitive, _path, _boatIndex] spawn {
                params ["_fugitive", "_path", "_boatIndex"];
                
                private _wpIndex = 0;
                
                // États FSM
                private _ST_FLEEING = 0;
                private _ST_SURRENDER_STAND = 1;
                private _ST_SURRENDER_KNEEL = 2;
                private _ST_CAPTURED = 3;
                
                // Animations vérifiées (CfgMovesMaleSdr)
                private _animStand = "AmovPercMstpSsurWnonDnon";    // Debout mains en l'air
                private _animKneel = "AmovPknlMstpSsurWnonDnon";    // À genoux mains sur la tête
                private _animProne = "AmovPpneMstpSnonWnonDnon";    // Couché capturé
                
                private _currentState = _ST_FLEEING;
                _fugitive setVariable ["fsm_state", "FLEEING", true];
                
                // Initialisation du mouvement : spawn à wp0, move vers wp1
                _wpIndex = 1;
                _fugitive setVariable ["currentWP", _wpIndex, true];
                if (_wpIndex < count _path) then {
                    private _nextMarker = _path select _wpIndex;
                    private _nextObj = missionNamespace getVariable [_nextMarker, objNull];
                    if (!isNull _nextObj) then {
                        _fugitive doMove (getPos _nextObj);
                    };
                };
                
                while {alive _fugitive && MISSION_var_task1_running} do {
                    sleep 0.5;
                    
                    // Distance joueur le plus proche (optimisé)
                    private _nearestDist = 9999;
                    if (_currentState != _ST_CAPTURED) then {
                        {
                            if (alive _x) then {
                                private _d = _x distance2D _fugitive;
                                if (_d < _nearestDist) then { _nearestDist = _d; };
                            };
                        } forEach allPlayers;
                    };
                    
                    switch (_currentState) do {
                        case _ST_FLEEING: {
                            // Vérifier si wp actuel atteint
                            private _currentMarker = _path select _wpIndex;
                            private _currentObj = missionNamespace getVariable [_currentMarker, objNull];
                            if (isNull _currentObj) then { continue; };
                            private _wpPos = getPos _currentObj;
                            
                            if (_fugitive distance2D _wpPos < 5) then {
                                _wpIndex = _wpIndex + 1;
                                _fugitive setVariable ["currentWP", _wpIndex, true];
                                
                                if (_wpIndex < count _path) then {
                                    private _nextMarker = _path select _wpIndex;
                                    private _nextObj = missionNamespace getVariable [_nextMarker, objNull];
                                    if (!isNull _nextObj) then {
                                        _fugitive doMove (getPos _nextObj);
                                    };
                                } else {
                                    // Atteint la fin : embarquer dans le bateau
                                    private _boat = MISSION_var_task1_boats select _boatIndex;
                                    if (!isNull _boat && !(_fugitive getVariable "boarded")) then {
                                        private _boatPos = getPos _boat;
                                        _fugitive doMove _boatPos;
                                        
                                        if (_fugitive distance2D _boatPos < 3) then {
                                            _fugitive assignAsDriver _boat;
                                            _fugitive moveInDriver _boat;
                                            _boat engineOn true;
                                            private _escDir = _boat getVariable ["escapeDirection", [0,0,0]];
                                            _boat doMove _escDir;
                                            _fugitive setVariable ["boarded", true, true];
                                        };
                                    };
                                };
                            };
                            
                            // Armement après WP5 (_wpIndex > 4 signifie dépasse WP5)
                            if (_wpIndex > 4 && !(_fugitive getVariable "isArmed")) then {
                                _fugitive addMagazine "16Rnd_9x21_Mag";
                                _fugitive addMagazine "16Rnd_9x21_Mag";
                                _fugitive addWeapon "hgun_P07_F";
                                _fugitive setVariable ["isArmed", true, true];
                                _fugitive setCaptive false;
                                _fugitive setBehaviour "AWARE";
                            };
                            
                            // Transition vers SURRENDER_STAND si joueur proche et pas encore dépassé WP5
                            if (_nearestDist < 15 && _wpIndex <= 4) then {
                                _currentState = _ST_SURRENDER_STAND;
                                _fugitive switchMove _animStand;
                                doStop _fugitive;
                                _fugitive forceSpeed 0;
                                _fugitive setVariable ["fsm_state", "SURRENDER_STAND", true];
                                _fugitive setVariable ["isSurrendered", true, true];
                                _fugitive setCaptive true;
                            };
                        };
                        
                        case _ST_SURRENDER_STAND: {
                            // Transition vers SURRENDER_KNEEL si plus proche
                            if (_nearestDist < 5) then {
                                _currentState = _ST_SURRENDER_KNEEL;
                                _fugitive switchMove _animKneel;
                                _fugitive setVariable ["fsm_state", "SURRENDER_KNEEL", true];
                                _fugitive setVariable ["isKneeling", true, true];
                                
                                // Ajouter l'action de neutralisation (radius 3m)
                                private _actID = _fugitive addAction [
                                    "Neutraliser la cible",
                                    {
                                        params ["_target"];
                                        _target setVariable ["request_capture", true, true];
                                    },
                                    nil,
                                    6,
                                    true,
                                    true,
                                    "",
                                    "true",
                                    3
                                ];
                                _fugitive setVariable ["captureActionID", _actID, true];
                            };
                            
                            // Revert vers FLEEING si éloigné
                            if (_nearestDist > 25) then {
                                _currentState = _ST_FLEEING;
                                _fugitive switchMove "";
                                _fugitive forceSpeed 6;
                                private _currentMarker = _path select _wpIndex;
                                private _currentObj = missionNamespace getVariable [_currentMarker, objNull];
                                if (!isNull _currentObj) then {
                                    _fugitive doMove (getPos _currentObj);
                                };
                                _fugitive setVariable ["fsm_state", "FLEEING", true];
                                _fugitive setVariable ["isSurrendered", false, true];
                            };
                        };
                        
                        case _ST_SURRENDER_KNEEL: {
                            // Transition vers CAPTURED si action activée
                            if (_fugitive getVariable "request_capture") then {
                                _currentState = _ST_CAPTURED;
                                _fugitive switchMove _animProne;
                                _fugitive setVariable ["fsm_state", "CAPTURED", true];
                                _fugitive setVariable ["isCaptured", true, true];
                                _fugitive setVariable ["isFugitive", false, true];
                                private _actID = _fugitive getVariable ["captureActionID", -1];
                                if (_actID != -1) then {
                                    _fugitive removeAction _actID;
                                };
                            };
                            
                            // Revert vers FLEEING si éloigné (sans capture)
                            if (_nearestDist > 20) then {
                                _currentState = _ST_FLEEING;
                                _fugitive switchMove "";
                                _fugitive forceSpeed 6;
                                private _currentMarker = _path select _wpIndex;
                                private _currentObj = missionNamespace getVariable [_currentMarker, objNull];
                                if (!isNull _currentObj) then {
                                    _fugitive doMove (getPos _currentObj);
                                };
                                _fugitive setVariable ["fsm_state", "FLEEING", true];
                                _fugitive setVariable ["isKneeling", false, true];
                                _fugitive setVariable ["isSurrendered", false, true];
                                private _actID = _fugitive getVariable ["captureActionID", -1];
                                if (_actID != -1) then {
                                    _fugitive removeAction _actID;
                                };
                            };
                        };
                        
                        case _ST_CAPTURED: {
                            // État final : rien à faire
                        };
                    };
                };
            };
        };
    } forEach _fugitiveTemplates;
    
    // ========================================================================
    // BOUCLE DE SURVEILLANCE DES CONDITIONS DE FIN
    // ========================================================================
    [] spawn {
        while {MISSION_var_task1_running} do {
            sleep 2;
            
            if (MISSION_var_task1_escaped) exitWith {
                // Défaite
                [_taskID, "FAILED"] call BIS_fnc_taskSetState;
                MISSION_var_task1_running = false;
            };
            
            private _remaining = {alive _x && !(_x getVariable ["isCaptured", false])} count MISSION_var_task1_fugitives;
            if (_remaining == 0) exitWith {
                // Victoire
                [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
                MISSION_var_task1_running = false;
            };
        };
    };
};