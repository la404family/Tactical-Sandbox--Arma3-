// ============================================================================
// SCRIPT COMPLET POUR LA TÂCHE "CHASSE À L'HOMME" - ARMA 3 SQF
// VERSION OPTIMISÉE POUR ANIMATIONS FLUIDES
// ============================================================================

// ============================================================================
// SECTION 1: INITIALISATION ET CONFIGURATION
// ============================================================================

MISSION_var_task1_running = true;
MISSION_var_task1_fugitives = [];
MISSION_var_task1_boats = [];
MISSION_var_task1_escaped = false;

// Définition des 7 chemins
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
    
    sleep 3; // Délai initial
    
    if (!MISSION_var_task1_running) exitWith {};
    
    hint (localize "STR_HINT_FUGITIVES_SPOTTED");
    
    // ... (Gardez le code de SPAWN DES BATEAUX et du TRIGGER ici) ... 
    // ... (Je me concentre sur la boucle IA ci-dessous) ...

    // ========================================================================
    // SPAWN DES FUGITIFS ET IA
    // ========================================================================
    private _grpFugitives = createGroup [east, true];
    
    {
        private _template = _x;
        private _pathIndex = _selectedPaths select _forEachIndex;
        private _path = _paths select _pathIndex;
        private _boatIndex = _forEachIndex;
        
        _template params ["_name", "_type", "_pos", "_dir", "_side", "_loadout"];
        
        private _startMarker = _path select 0;
        private _startObj = missionNamespace getVariable [_startMarker, objNull];
        
        if (!isNull _startObj) then {
            private _spawnPos = getPos _startObj;
            private _fugitive = _grpFugitives createUnit [_type, _spawnPos, [], 0, "NONE"];
            _fugitive setUnitLoadout _loadout;
            _fugitive setDir (getDir _startObj);
            
            // Setup Variables
            _fugitive setVariable ["isFugitive", true, true];
            _fugitive setVariable ["isCaptured", false, true];
            _fugitive setVariable ["isArmed", false, true];
            _fugitive setVariable ["boarded", false, true];
            _fugitive setVariable ["captureActionID", -1]; 
            
            _fugitive setCaptive true;
            _fugitive setBehaviour "CARELESS";
            _fugitive setUnitPos "UP"; // Force debout pour éviter qu'il rampe
            _fugitive forceSpeed 6;
            removeAllWeapons _fugitive;
            
            MISSION_var_task1_fugitives pushBack _fugitive;
            
            // --- CŒUR DU SCRIPT : IA FSM PRO - ANIMATIONS FLUIDES GARANTIES ---
            [_fugitive, _path, _boatIndex] spawn {
                params ["_fugitive", "_path", "_boatIndex"];
                
                // ============================================================
                // CONSTANTES D'ÉTAT
                // ============================================================
                private _ST_FLEEING = 0;
                private _ST_SURRENDER_STAND = 1;
                private _ST_SURRENDER_KNEEL = 2;
                private _ST_CAPTURED = 3;
                
                // ============================================================
                // ANIMATIONS ARMA 3 VALIDÉES
                // ============================================================
                // Reddition debout (mains en l'air)
                private _animSurrenderStand = "AmovPercMstpSsurWnonDnon";
                // Reddition à genoux (mains sur la tête)  
                private _animSurrenderKneel = "AmovPknlMstpSsurWnonDnon";
                // Position couchée (neutralisé)
                private _animProne = "AmovPpneMstpSnonWnonDnon";
                // Idle debout normal (pour transition)
                private _animStandIdle = "AmovPercMstpSnonWnonDnon";
                // Idle à genoux (transition)
                private _animKneelIdle = "AmovPknlMstpSnonWnonDnon";
                
                // ============================================================
                // FONCTION D'APPLICATION D'ANIMATION FLUIDE
                // ============================================================
                private _fnc_setAnim = {
                    params ["_unit", "_anim", ["_lock", true]];
                    
                    // Désactiver l'IA d'animation pour contrôle total
                    if (_lock) then {
                        _unit disableAI "ANIM";
                        _unit disableAI "AUTOTARGET";
                        _unit disableAI "FSM";
                    };
                    
                    // Appliquer l'animation avec blend naturel
                    _unit playMoveNow _anim;
                    
                    // Verrouiller l'animation en boucle pour éviter les resets
                    [_unit, _anim, 1] call BIS_fnc_ambientAnim__terminate;
                };
                
                // Fonction pour libérer les animations
                private _fnc_releaseAnim = {
                    params ["_unit"];
                    _unit enableAI "ANIM";
                    _unit enableAI "AUTOTARGET";
                    _unit enableAI "FSM";
                    _unit playMoveNow "";
                };
                
                // ============================================================
                // VARIABLES DE CONTRÔLE FSM
                // ============================================================
                private _currentState = _ST_FLEEING;
                private _lastState = -1;
                private _stateChangeTime = 0;
                private _transitionLock = false;
                private _wpIndex = 1;
                
                // Initialiser le mouvement
                private _firstDest = missionNamespace getVariable [_path select _wpIndex, objNull];
                if (!isNull _firstDest) then { _fugitive doMove (getPos _firstDest); };
                
                // ============================================================
                // BOUCLE PRINCIPALE FSM
                // ============================================================
                while {alive _fugitive && MISSION_var_task1_running} do {
                    
                    // Anti-spam: bloquer les changements d'état pendant les transitions
                    private _timeSinceChange = time - _stateChangeTime;
                    
                    // ==========================================================
                    // GESTION DES TRANSITIONS D'ÉTAT
                    // ==========================================================
                    if (_currentState != _lastState && !_transitionLock) then {
                        _transitionLock = true;
                        _stateChangeTime = time;
                        
                        switch (_currentState) do {
                            
                            // ----------------------------------------------
                            // ÉTAT: FUITE
                            // ----------------------------------------------
                            case _ST_FLEEING: {
                                // Libérer le contrôle des animations
                                _fugitive enableAI "ANIM";
                                _fugitive enableAI "MOVE";
                                _fugitive enableAI "AUTOTARGET";
                                _fugitive enableAI "FSM";
                                
                                // Reset animation naturel
                                _fugitive playMoveNow "";
                                
                                // Paramètres de course
                                _fugitive setUnitPos "UP";
                                _fugitive forceSpeed 6;
                                _fugitive setBehaviour "CARELESS";
                                
                                // Nettoyer l'action de capture si présente
                                private _actID = _fugitive getVariable ["captureActionID", -1];
                                if (_actID != -1) then {
                                    _fugitive removeAction _actID;
                                    _fugitive setVariable ["captureActionID", -1];
                                };
                                
                                // Relancer la navigation
                                sleep 0.1;
                                if (_wpIndex < count _path) then {
                                    private _destObj = missionNamespace getVariable [_path select _wpIndex, objNull];
                                    if (!isNull _destObj) then { _fugitive doMove (getPos _destObj); };
                                };
                            };
                            
                            // ----------------------------------------------
                            // ÉTAT: REDDITION DEBOUT (MAINS EN L'AIR)
                            // ----------------------------------------------
                            case _ST_SURRENDER_STAND: {
                                // Arrêt du mouvement
                                _fugitive forceSpeed 0;
                                doStop _fugitive;
                                _fugitive disableAI "MOVE";
                                _fugitive disableAI "AUTOTARGET";
                                _fugitive disableAI "FSM";
                                
                                // ANIMATION FLUIDE: D'abord idle, puis surrender
                                _fugitive disableAI "ANIM";
                                sleep 0.1;
                                
                                // Transition douce vers mains en l'air
                                _fugitive playMove _animSurrenderStand;
                                
                                // Attendre que l'animation soit bien lancée
                                sleep 0.5;
                                
                                // Verrouiller sur cette animation
                                _fugitive switchMove _animSurrenderStand;
                            };
                            
                            // ----------------------------------------------
                            // ÉTAT: REDDITION À GENOUX (MAINS SUR LA TÊTE)
                            // ----------------------------------------------
                            case _ST_SURRENDER_KNEEL: {
                                _fugitive disableAI "ANIM";
                                _fugitive disableAI "MOVE";
                                
                                // TRANSITION FLUIDE: Debout -> Genoux
                                // Étape 1: Aller vers position à genoux normale
                                _fugitive playMove _animKneelIdle;
                                sleep 0.8;
                                
                                // Étape 2: Lever les mains sur la tête
                                _fugitive playMove _animSurrenderKneel;
                                sleep 0.5;
                                
                                // Verrouiller l'animation
                                _fugitive switchMove _animSurrenderKneel;
                                
                                // Ajouter l'action de neutralisation
                                private _actID = _fugitive addAction [
                                    "<t color='#FF0000' size='1.2'>⊛ Neutraliser la cible</t>",
                                    {
                                        params ["_target", "_caller", "_id"];
                                        _target setVariable ["request_capture", true, true];
                                        _target removeAction _id;
                                    },
                                    nil, 100, true, true, "", 
                                    "_this distance _target < 3", 3
                                ];
                                _fugitive setVariable ["captureActionID", _actID];
                            };
                            
                            // ----------------------------------------------
                            // ÉTAT: CAPTURÉ (AU SOL)
                            // ----------------------------------------------
                            case _ST_CAPTURED: {
                                // Marquer comme capturé
                                _fugitive setVariable ["isCaptured", true, true];
                                _fugitive setVariable ["isFugitive", false, true];
                                _fugitive setCaptive true;
                                
                                _fugitive disableAI "ANIM";
                                _fugitive disableAI "MOVE";
                                _fugitive disableAI "ALL";
                                
                                // TRANSITION FLUIDE: Genoux -> Couché
                                // Étape 1: Position à genoux normale (transition)
                                _fugitive playMove _animKneelIdle;
                                sleep 0.4;
                                
                                // Étape 2: Se coucher
                                _fugitive playMove _animProne;
                                sleep 1.0;
                                
                                // Verrouiller au sol
                                _fugitive switchMove _animProne;
                                _fugitive setUnitPos "DOWN";
                                
                                // Nettoyer l'action
                                private _actID = _fugitive getVariable ["captureActionID", -1];
                                if (_actID != -1) then {
                                    _fugitive removeAction _actID;
                                    _fugitive setVariable ["captureActionID", -1];
                                };
                            };
                        };
                        
                        _lastState = _currentState;
                        _transitionLock = false;
                    };
                    
                    // ==========================================================
                    // LOGIQUE COMPORTEMENTALE (vérifications continues)
                    // ==========================================================
                    sleep 0.3;
                    
                    // Skip si en transition ou capturé
                    if (_transitionLock || _currentState == _ST_CAPTURED) then { continue; };
                    
                    // Calcul distance joueur le plus proche
                    private _nearestDist = 9999;
                    {
                        if (alive _x && isPlayer _x) then {
                            private _d = _x distance2D _fugitive;
                            if (_d < _nearestDist) then { _nearestDist = _d; };
                        };
                    } forEach allPlayers;
                    
                    // Logique selon l'état actuel
                    switch (_currentState) do {
                        
                        // --- LOGIQUE DE FUITE ---
                        case _ST_FLEEING: {
                            // Progression waypoints
                            if (_wpIndex < count _path) then {
                                private _currentObj = missionNamespace getVariable [_path select _wpIndex, objNull];
                                
                                if (!isNull _currentObj && {_fugitive distance2D _currentObj < 6}) then {
                                    _wpIndex = _wpIndex + 1;
                                    
                                    if (_wpIndex < count _path) then {
                                        private _nextObj = missionNamespace getVariable [_path select _wpIndex, objNull];
                                        if (!isNull _nextObj) then { _fugitive doMove (getPos _nextObj); };
                                    } else {
                                        // Embarquement bateau
                                        if (_boatIndex < count MISSION_var_task1_boats) then {
                                            private _boat = MISSION_var_task1_boats select _boatIndex;
                                            if (!isNull _boat && !(_fugitive getVariable ["boarded", false])) then {
                                                _fugitive doMove (getPos _boat);
                                                if (_fugitive distance2D _boat < 5) then {
                                                    _fugitive moveInDriver _boat;
                                                    _boat engineOn true;
                                                    _boat doMove (_boat getVariable ["escapeDirection", [0,0,0]]);
                                                    _fugitive setVariable ["boarded", true, true];
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                            
                            // Armement après WP5
                            if (_wpIndex > 4 && !(_fugitive getVariable ["isArmed", false])) then {
                                _fugitive addMagazine "16Rnd_9x21_Mag";
                                _fugitive addWeapon "hgun_P07_F";
                                _fugitive setVariable ["isArmed", true, true];
                                _fugitive setCaptive false;
                                _fugitive setBehaviour "COMBAT";
                            };
                            
                            // Transition: Reddition si joueur proche et non armé
                            if (_nearestDist < 15 && _wpIndex <= 4 && _timeSinceChange > 1) then {
                                _currentState = _ST_SURRENDER_STAND;
                            };
                        };
                        
                        // --- LOGIQUE REDDITION DEBOUT ---
                        case _ST_SURRENDER_STAND: {
                            // Maintien de l'animation
                            if (animationState _fugitive != _animSurrenderStand) then {
                                _fugitive switchMove _animSurrenderStand;
                            };
                            
                            // Transition vers genoux si très proche
                            if (_nearestDist < 5 && _timeSinceChange > 1.5) then {
                                _currentState = _ST_SURRENDER_KNEEL;
                            };
                            
                            // Retour fuite si joueur s'éloigne
                            if (_nearestDist > 25 && _timeSinceChange > 2) then {
                                _currentState = _ST_FLEEING;
                            };
                        };
                        
                        // --- LOGIQUE REDDITION À GENOUX ---
                        case _ST_SURRENDER_KNEEL: {
                            // Maintien de l'animation
                            if (animationState _fugitive != _animSurrenderKneel) then {
                                _fugitive switchMove _animSurrenderKneel;
                            };
                            
                            // Capture demandée
                            if (_fugitive getVariable ["request_capture", false]) then {
                                _currentState = _ST_CAPTURED;
                            };
                            
                            // Retour fuite si joueur s'éloigne trop
                            if (_nearestDist > 20 && _timeSinceChange > 2) then {
                                _currentState = _ST_FLEEING;
                            };
                        };
                    };
                };
            };
        };
    } forEach _fugitiveTemplates;
    
    // ========================================================================
    // BOUCLE DE SURVEILLANCE DES CONDITIONS DE FIN
    // ========================================================================
    [_taskID] spawn {
        params ["_taskID"];
        while {MISSION_var_task1_running} do {
            sleep 2;
            
            // Défaite
            if (MISSION_var_task1_escaped) exitWith {
                [_taskID, "FAILED"] call BIS_fnc_taskSetState;
                MISSION_var_task1_running = false;
            };
            
            // Victoire
            private _remaining = {alive _x && !(_x getVariable ["isCaptured", false])} count MISSION_var_task1_fugitives;
            if (_remaining == 0 && count MISSION_var_task1_fugitives > 0) exitWith {
                [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
                MISSION_var_task1_running = false;
            };
        };
    };
};