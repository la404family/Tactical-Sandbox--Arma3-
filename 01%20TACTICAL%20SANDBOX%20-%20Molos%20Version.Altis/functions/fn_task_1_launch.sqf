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

// Définition des 7 chemins (correspondant aux chemins vers les 7 bateaux)
private _paths = [
    ["task_1_spawn_01", "task_1_spawn_02", "task_1_spawn_03", "task_1_spawn_04", "task_1_spawn_05", "task_1_spawn_06"],
    ["task_1_spawn_07", "task_1_spawn_08", "task_1_spawn_09", "task_1_spawn_10", "task_1_spawn_11", "task_1_spawn_12"],
    ["task_1_spawn_13", "task_1_spawn_14", "task_1_spawn_15", "task_1_spawn_16", "task_1_spawn_17", "task_1_spawn_18"],
    ["task_1_spawn_19", "task_1_spawn_20", "task_1_spawn_21", "task_1_spawn_22", "task_1_spawn_23", "task_1_spawn_24"],
    ["task_1_spawn_25", "task_1_spawn_26", "task_1_spawn_27", "task_1_spawn_28", "task_1_spawn_29", "task_1_spawn_30"],
    ["task_1_spawn_31", "task_1_spawn_32", "task_1_spawn_33", "task_1_spawn_34", "task_1_spawn_35", "task_1_spawn_36"],
    ["task_1_spawn_37", "task_1_spawn_38", "task_1_spawn_39", "task_1_spawn_40", "task_1_spawn_41", "task_1_spawn_42"],
    ["task_1_spawn_43", "task_1_spawn_44", "task_1_spawn_45", "task_1_spawn_46", "task_1_spawn_47", "task_1_spawn_48"]
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

// Sélection aléatoire de 2 fugitifs sur 3
private _fugitiveTemplates = MISSION_var_fugitives call BIS_fnc_arrayShuffle;
_fugitiveTemplates = _fugitiveTemplates select [0, 2];

// Sélection aléatoire de 2 chemins sur 8 (index 0-7)
private _availablePaths = [0,1,2,3,4,5,6,7] call BIS_fnc_arrayShuffle;
private _selectedPaths = _availablePaths select [0, 2];

// ============================================================================
// SECTION 4: SPAWN DIFFÉRÉ (5 MINUTES = 300 SECONDES)
// ============================================================================

[_fugitiveTemplates, _selectedPaths, _paths, _taskID] spawn {
    params ["_fugitiveTemplates", "_selectedPaths", "_paths", "_taskID"];
    
    // ========================================================================
    // ATTENTE DE 5 MINUTES
    // ========================================================================
    sleep 300; // 5 minutes
    
    if (!MISSION_var_task1_running) exitWith {};
    
    hint (localize "STR_HINT_FUGITIVES_SPOTTED");
    
    // ========================================================================
    // SPAWN DES BATEAUX
    // ========================================================================
    // On utilise les données sauvegardées dans MISSION_var_boats (créé par fn_task_x_memory)
    // MISSION_var_boats contient: [NomVariable, ClassName, Position, Direction, Camp, Loadout]
    
    for "_i" from 1 to 8 do {
        private _boatIndex = _i - 1;
        private _boatData = MISSION_var_boats param [_boatIndex, []];
        
        // Récupérer la position du bateau (héliport placé en éditeur, non supprimé)
        private _boatPlaceVarName = format ["task_1_boat_place_%1", _i];
        private _boatPlace = missionNamespace getVariable [_boatPlaceVarName, objNull];
        
        // Récupérer la direction d'évasion (objet placé en éditeur)
        private _boatDirVarName = format ["task_1_boat_direction_%1", _i];
        private _boatDirectionObj = missionNamespace getVariable [_boatDirVarName, objNull];
        
        if (count _boatData > 0 && !isNull _boatPlace) then {
            _boatData params ["_varName", "_type", "_oldPos", "_oldDir", "_side", "_stuff"];
            
            private _spawnPos = getPos _boatPlace;
            private _spawnDir = getDir _boatPlace;
            
            private _boat = createVehicle [_type, _spawnPos, [], 0, "NONE"];
            _boat setDir _spawnDir;
            _boat setPos _spawnPos;
            
            // Calcul destination fuite
            private _escapePos = if (!isNull _boatDirectionObj) then { 
                getPos _boatDirectionObj 
            } else { 
                _spawnPos vectorAdd [sin(_spawnDir) * 2000, cos(_spawnDir) * 2000, 0] 
            };
            
            _boat setVariable ["escapeDestination", _escapePos, true];
            _boat setVariable ["pathIndex", _boatIndex, true];
            
            MISSION_var_task1_boats pushBack _boat;
        } else {
            // Si pas de donnée valide, on met objNull pour garder l'alignement des index
            MISSION_var_task1_boats pushBack objNull;
        };
    };

    // ========================================================================
    // SPAWN DES FUGITIFS ET IA
    // ========================================================================
    private _grpFugitives = createGroup [east, true];
    private _chosenArmedIndex = floor (random (count _fugitiveTemplates));
    
    {
        private _template = _x;
        private _pathIndex = _selectedPaths select _forEachIndex;
        private _path = _paths select _pathIndex;
        private _boatIndex = _pathIndex; // Le chemin N correspond au bateau N
        
        _template params ["_name", "_type", "_pos", "_dir", "_side", "_loadout"];
        
        // Point de départ du chemin
        private _startMarker = _path select 0;
        private _startObj = missionNamespace getVariable [_startMarker, objNull];
        
        if (!isNull _startObj) then {
            private _spawnPos = getPos _startObj;
            private _fugitive = _grpFugitives createUnit [_type, _spawnPos, [], 0, "NONE"];
            _fugitive setUnitLoadout _loadout;
            _fugitive setDir (getDir _startObj);
            
            _fugitive setVariable ["isFugitive", true, true];
            _fugitive setVariable ["isCaptured", false, true];
            _fugitive setVariable ["isArmed", false, true];
            _fugitive setVariable ["willBeArmed", (_forEachIndex == _chosenArmedIndex), true];
            _fugitive setVariable ["boarded", false, true];
            _fugitive setVariable ["captureActionID", -1];
            _fugitive setVariable ["pathIndex", _pathIndex, true];
            _fugitive setVariable ["boatIndex", _boatIndex, true];
            
            _fugitive setCaptive true;
            _fugitive setBehaviour "CARELESS";
            _fugitive setUnitPos "UP";
            _fugitive forceSpeed 6;
            removeAllWeapons _fugitive;
            
            MISSION_var_task1_fugitives pushBack _fugitive;

            // --- SUIVI DU FUGITIF (MARQUEUR CROIX ROUGE ALÉATOIRE) ---
            // --- SUIVI DU FUGITIF (MARQUEUR CROIX ROUGE & JAUNE) ---
            [_fugitive, _pathIndex] spawn {
                params ["_fugitive", "_pathIndex"];
                private _markerName = format ["task1_track_%1", _pathIndex];
                
                // Variables de timing pour le marqueur rouge
                private _initialDelay = 120 + random 60; // 2 à 3 minutes
                private _spawnTime = time;
                private _nextUpdate = _spawnTime + _initialDelay; 
                
                // Boucle de surveillance rapide (2s)
                while {MISSION_var_task1_running} do {
                    
                    // 1. CAS: MORT (Priorité absolue)
                    if (!alive _fugitive) exitWith {
                        // Supprimer marqueur rouge
                        if (getMarkerColor _markerName != "") then { deleteMarker _markerName; };
                        
                        // Supprimer marqueur captif (bleu) si existant
                        private _capM = _fugitive getVariable ["captiveMarkerName", ""];
                        if (_capM != "") then { deleteMarker _capM; };
                        
                        // Créer marqueur JAUNE "EXÉCUTÉ"
                        private _deadMarkerName = format ["task1_dead_%1", _pathIndex];
                        createMarker [_deadMarkerName, getPos _fugitive];
                        _deadMarkerName setMarkerType "hd_destroy";
                        _deadMarkerName setMarkerColor "ColorYellow";
                        _deadMarkerName setMarkerText (localize "STR_MARKER_EXECUTED");
                    };
                    
                    // 2. CAS: CAPTURÉ
                    if (_fugitive getVariable ["isCaptured", false]) then {
                        // Si capturé, on supprime le marqueur rouge de poursuite (le bleu est géré par le FSM)
                        if (getMarkerColor _markerName != "") then { deleteMarker _markerName; };
                    } else {
                        // 3. CAS: FUGITIF LIBRE (Marqueur Rouge)
                        
                        // On vérifie si c'est le moment de la mise à jour (Délai initial + Intervalles)
                        if (time >= _nextUpdate) then {
                            // Création ou Mise à jour
                            if (getMarkerColor _markerName == "") then {
                                createMarker [_markerName, getPos _fugitive];
                                _markerName setMarkerType "hd_destroy";
                                _markerName setMarkerColor "ColorRed";
                                _markerName setMarkerText (localize "STR_MARKER_FUGITIVE");
                            } else {
                                _markerName setMarkerPos (getPos _fugitive);
                            };
                            
                            // Prochaine mise à jour aléatoire (15 à 120 secondes)
                            _nextUpdate = time + (15 + random 105);
                        };
                    };
                    
                    sleep 2;
                };
                
                // Nettoyage final si mission terminée proprement mais fugitif en vie
                if (!MISSION_var_task1_running) then {
                    deleteMarker _markerName;
                };
            };
            
            // --- CŒUR DU SCRIPT : IA FSM PRO AVEC ANTI-BLOCAGE ---
            [_fugitive, _path, _boatIndex] spawn {
                params ["_fugitive", "_path", "_boatIndex"];
                
                // CONSTANTES
                private _ST_FLEEING = 0;
                private _ST_SURRENDER_STAND = 1;
                private _ST_SURRENDER_KNEEL = 2;
                private _ST_CAPTURED = 3;
                
                private _animSurrenderStand = "AmovPercMstpSsurWnonDnon";
                private _animSurrenderKneel = "AmovPknlMstpSsurWnonDnon";
                private _animProne = "AmovPpneMstpSnonWnonDnon";
                private _animKneelIdle = "AmovPknlMstpSnonWnonDnon";
                
                // PARAMÈTRES ANTI-BLOCAGE
                private _wpCompletionRadius = 10; // Rayon de complétion waypoint (mètres)
                private _stuckSpeedThreshold = 1; // Vitesse en dessous de laquelle on considère le fugitif bloqué
                private _stuckTimeThreshold = 5; // Temps (secondes) avant de considérer un blocage
                private _lastPos = getPos _fugitive;
                private _stuckTimer = 0;
                
                private _currentState = _ST_FLEEING;
                private _lastState = -1;
                private _stateChangeTime = 0;
                private _transitionLock = false;
                private _wpIndex = 1;
                
                // Configuration IA optimale pour la fuite
                _fugitive setBehaviour "CARELESS";
                _fugitive setSpeedMode "FULL";
                _fugitive disableAI "AUTOCOMBAT";
                _fugitive disableAI "SUPPRESSION";
                _fugitive disableAI "COVER";
                _fugitive forceSpeed 6;
                
                // Init Mouvement avec premier waypoint
                private _firstDest = missionNamespace getVariable [_path select _wpIndex, objNull];
                if (!isNull _firstDest) then { _fugitive doMove (getPos _firstDest); };
                
                while {alive _fugitive && MISSION_var_task1_running && !(_fugitive getVariable ["boarded", false])} do {
                    
                    private _timeSinceChange = time - _stateChangeTime;
                    
                    // GESTION DES TRANSITIONS
                    if (_currentState != _lastState && !_transitionLock) then {
                        _transitionLock = true;
                        _stateChangeTime = time;
                        
                        switch (_currentState) do {
                            case _ST_FLEEING: {
                                _fugitive enableAI "ANIM"; _fugitive enableAI "MOVE"; _fugitive enableAI "AUTOTARGET"; _fugitive enableAI "FSM";
                                _fugitive playMoveNow "";
                                _fugitive setUnitPos "UP";
                                _fugitive forceSpeed 6;
                                _fugitive setBehaviour "CARELESS";
                             
                               

                                private _actID = _fugitive getVariable ["captureActionID", -1];
                                if (_actID != -1) then { _fugitive removeAction _actID; _fugitive setVariable ["captureActionID", -1]; };
                                
                                sleep 0.1;
                                if (_wpIndex < count _path) then {
                                    private _destObj = missionNamespace getVariable [_path select _wpIndex, objNull];
                                    if (!isNull _destObj) then { _fugitive doMove (getPos _destObj); };
                                };
                            };
                            
                            case _ST_SURRENDER_STAND: {
                                _fugitive forceSpeed 0; doStop _fugitive;
                                _fugitive disableAI "MOVE"; _fugitive disableAI "AUTOTARGET"; _fugitive disableAI "FSM"; _fugitive disableAI "ANIM";
                                sleep 1;
                                _fugitive playMove _animSurrenderStand;
                                sleep 1;
                                _fugitive switchMove _animSurrenderStand;
                            };
                            
                            case _ST_SURRENDER_KNEEL: {
                                _fugitive disableAI "ANIM"; _fugitive disableAI "MOVE";
                                _fugitive playMove _animKneelIdle;
                                sleep 1;
                                _fugitive playMove _animSurrenderKneel;
                                sleep 1;
                                _fugitive switchMove _animSurrenderKneel;
                                
                                private _actID = _fugitive addAction [
                                    "<t color='#FF0000' size='1.2'>Neutraliser la cible</t>",
                                    { params ["_target", "_caller", "_id"]; _target setVariable ["request_capture", true, true]; _target removeAction _id; },
                                    nil, 100, true, true, "", "_this distance _target < 3", 3
                                ];
                                _fugitive setVariable ["captureActionID", _actID];
                            };
                            
                            case _ST_CAPTURED: {
                                _fugitive setVariable ["isCaptured", true, true];
                                _fugitive setVariable ["isFugitive", false, true];
                                _fugitive setCaptive true;
                                _fugitive disableAI "ALL";
                                
                                _fugitive playMove _animKneelIdle; sleep 1;
                                _fugitive playMove _animProne; sleep 1;
                                _fugitive switchMove _animProne;
                                _fugitive setUnitPos "DOWN";
                                
                                private _actID = _fugitive getVariable ["captureActionID", -1];
                                if (_actID != -1) then { _fugitive removeAction _actID; _fugitive setVariable ["captureActionID", -1]; };
                                
                                private _markerName = format ["marker_captive_%1", _fugitive];
                                private _marker = createMarker [_markerName, getPos _fugitive];
                                _marker setMarkerType "hd_destroy"; _marker setMarkerColor "ColorBlue";
                                _marker setMarkerText (localize "STR_MARKER_CAPTIVE"); _marker setMarkerSize [0.7, 0.7];
                                _fugitive setVariable ["captiveMarkerName", _markerName, true];
                                
                                hint (localize "STR_HINT_FUGITIVE_CAPTURED");
                            };
                        };
                        _lastState = _currentState;
                        _transitionLock = false;
                    };
                    
                    sleep 0.3;
                    if (_transitionLock || _currentState == _ST_CAPTURED) then { continue; };
                    
                    private _nearestDist = 9999;
                    { if (alive _x && isPlayer _x) then { private _d = _x distance2D _fugitive; if (_d < _nearestDist) then { _nearestDist = _d; }; }; } forEach allPlayers;
                    
                    switch (_currentState) do {
                        case _ST_FLEEING: {
                            // === DÉTECTION DE BLOCAGE ===
                            private _currentSpeed = speed _fugitive;
                            private _distMoved = _fugitive distance2D _lastPos;
                            
                            if (_currentSpeed < _stuckSpeedThreshold && _distMoved < 1) then {
                                _stuckTimer = _stuckTimer + 0.3;
                            } else {
                                _stuckTimer = 0;
                                _lastPos = getPos _fugitive;
                            };
                            
                            // Si bloqué pendant trop longtemps, déblocage forcé
                            if (_stuckTimer >= _stuckTimeThreshold) then {
                                // Calculer une position de contournement
                                private _currentDest = if (_wpIndex < count _path) then {
                                    private _destObj = missionNamespace getVariable [_path select _wpIndex, objNull];
                                    if (!isNull _destObj) then { getPos _destObj } else { getPos _fugitive };
                                } else { getPos _fugitive };
                                
                                // Téléporter légèrement vers la destination
                                private _dir = _fugitive getDir _currentDest;
                                private _newPos = _fugitive getPos [5, _dir];
                                _fugitive setPos _newPos;
                                
                                // Relancer le mouvement
                                if (_wpIndex < count _path) then {
                                    private _destObj = missionNamespace getVariable [_path select _wpIndex, objNull];
                                    if (!isNull _destObj) then { _fugitive doMove (getPos _destObj); };
                                };
                                
                                _stuckTimer = 0;
                                _lastPos = getPos _fugitive;
                            };
                            
                            // === NAVIGATION AVEC RAYON DE COMPLÉTION ===
                            if (_wpIndex < count _path) then {
                                private _currentObj = missionNamespace getVariable [_path select _wpIndex, objNull];
                                // Waypoint atteint (rayon de 10m) ?
                                if (!isNull _currentObj && {_fugitive distance2D _currentObj < _wpCompletionRadius}) then {
                                    _wpIndex = _wpIndex + 1;
                                    if (_wpIndex < count _path) then {
                                        private _nextObj = missionNamespace getVariable [_path select _wpIndex, objNull];
                                        if (!isNull _nextObj) then { _fugitive doMove (getPos _nextObj); };
                                    } else {
                                        // Fin du chemin -> FORCER MONTÉE DANS BATEAU
                                        private _boatIdx = _fugitive getVariable ["boatIndex", 0];
                                        if (_boatIdx < count MISSION_var_task1_boats) then {
                                            private _boat = MISSION_var_task1_boats select _boatIdx;
                                            // Récupérer le point de spawn du bateau (task_1_boat_place_X)
                                            private _boatPlaceVarName = format ["task_1_boat_place_%1", _boatIdx + 1];
                                            private _boatPlace = missionNamespace getVariable [_boatPlaceVarName, objNull];
                                            
                                            if (!isNull _boat && !isNull _boatPlace && !(_fugitive getVariable ["boarded", false])) then {
                                                // Se diriger vers la position du bateau directement
                                                _fugitive doMove (getPos _boat);
                                                
                                                // Assigner le fugitif comme conducteur et ordonner l'embarquement
                                                _fugitive assignAsDriver _boat;
                                                [_fugitive] orderGetIn true;
                                                
                                                // Attendre que le fugitif soit bien dans le bateau
                                                waitUntil { vehicle _fugitive == _boat };
                                                
                                                // === VERROUILLER LE FUGITIF DANS LE BATEAU ===
                                                _fugitive setVariable ["boarded", true, true];
                                                
                                                // 1. "LOBOTOMIE" : Désactiver toute l'IA sauf le mouvement
                                                _fugitive disableAI "TARGET";
                                                _fugitive disableAI "AUTOTARGET";
                                                _fugitive disableAI "SUPPRESSION";
                                                _fugitive disableAI "AUTOCOMBAT";
                                                _fugitive disableAI "FSM";
                                                // On LAISSE "MOVE" activé pour qu'il puisse conduire !
                                                
                                                // 2. PACIFISME : Comportement Careless et Combat Mode Blue (ne jamais tirer)
                                                _fugitive setBehaviour "CARELESS";
                                                _fugitive setCombatMode "BLUE";
                                                
                                                // Verrouiller le bateau pour empêcher la sortie
                                                _boat lock true;
                                                
                                                // Activer le moteur
                                                _boat engineOn true;
                                                
                                                // Récupérer la destination d'évasion
                                                private _escapeDest = _boat getVariable ["escapeDestination", getPos _boat];
                                                
                                                // 3. NETTOYAGE : Supprimer tous les anciens waypoints du groupe
                                                private _grpBoat = group _fugitive;
                                                while {(count (waypoints _grpBoat)) > 0} do {
                                                    deleteWaypoint ((waypoints _grpBoat) select 0);
                                                };
                                                _grpBoat deleteGroupWhenEmpty true;
                                                
                                                // 4. ORDRE UNIQUE : Forcer le mouvement du bateau vers la destination
                                                private _wp = _grpBoat addWaypoint [_escapeDest, 0];
                                                _wp setWaypointType "MOVE";
                                                _wp setWaypointSpeed "FULL";
                                                _wp setWaypointBehaviour "CARELESS";
                                                _wp setWaypointCombatMode "BLUE";
                                                _grpBoat setCurrentWaypoint _wp;
                                                
                                                // La boucle FSM s'arrêtera automatiquement car "boarded" est maintenant true
                                            };
                                        };
                                    };
                                };
                            };
                            
                            // ARMEMENT (WP5 = 6ème point)
                            if (_wpIndex >= 5 && !(_fugitive getVariable ["isArmed", false]) && (_fugitive getVariable ["willBeArmed", false])) then {
                                _fugitive addMagazine "16Rnd_9x21_Mag";
                                _fugitive addMagazine "16Rnd_9x21_Mag";
                                _fugitive addWeapon "hgun_P07_F";
                                _fugitive setVariable ["isArmed", true, true];
                                
                                // Devient hostile mais continue de fuir (CARELESS)
                                _fugitive setCaptive false;
                                [_fugitive] joinSilent (createGroup [east, true]);
                                _fugitive setBehaviour "CARELESS"; 
                                _fugitive forceSpeed 6;
                            
                            };
                            
                            // Reddition possible (SI NON ARMÉ)
                            if (_nearestDist < 15 && _wpIndex <= 4 && _timeSinceChange > 1 && !(_fugitive getVariable ["isArmed", false])) then {
                                _currentState = _ST_SURRENDER_STAND;
                            };
                        };
                        
                        case _ST_SURRENDER_STAND: {
                            if (animationState _fugitive != _animSurrenderStand) then { _fugitive switchMove _animSurrenderStand; };
                            if (_nearestDist < 5 && _timeSinceChange > 1.5) then { _currentState = _ST_SURRENDER_KNEEL; };
                            if (_nearestDist > 25 && _timeSinceChange > 2) then { _currentState = _ST_FLEEING; };
                        };
                        
                        case _ST_SURRENDER_KNEEL: {
                            if (animationState _fugitive != _animSurrenderKneel) then { _fugitive switchMove _animSurrenderKneel; };
                            if (_fugitive getVariable ["request_capture", false]) then { _currentState = _ST_CAPTURED; };
                            if (_nearestDist > 20 && _timeSinceChange > 2) then { _currentState = _ST_FLEEING; };
                        };
                    };
                };
            };
        };
    } forEach _fugitiveTemplates;

    // ========================================================================
    // BOUCLE DE SURVEILLANCE & TRIGGER ECHEC
    // ========================================================================
    [_taskID] spawn {
        params ["_taskID"];
        
        // Setup Trigger d'Echec (Escape)
        private _trgData = MISSION_var_escape_trigger;
        private _failTrigger = objNull;
        
        if (count _trgData > 0) then {
            _trgData params ["_pos", "_dir", "_area"];
            _failTrigger = createTrigger ["EmptyDetector", _pos, false];
            _failTrigger setTriggerArea _area;
            _failTrigger setDir _dir;
            _failTrigger setTriggerActivation ["ANYPLAYER", "PRESENT", false];
        };
        
        while {MISSION_var_task1_running} do {
            sleep 2;
            
            // --- VICTOIRE ---
            private _remaining = { alive _x && !(_x getVariable ["isCaptured", false]) } count MISSION_var_task1_fugitives;
            if (_remaining == 0 && count MISSION_var_task1_fugitives > 0) exitWith {
                [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
                MISSION_var_task1_running = false;
                if (!isNull _failTrigger) then { deleteVehicle _failTrigger; };
                [] spawn MISSION_fnc_task_x_finish;
            };
            
            // --- DÉFAITE ---
            private _fugitiveEscaped = false;
            // Vérification par trigger
            if (!isNull _failTrigger) then {
                {
                    if (alive _x && (_x inArea _failTrigger)) exitWith { _fugitiveEscaped = true; };
                } forEach MISSION_var_task1_fugitives;
            };
            
            if (_fugitiveEscaped) exitWith {
                [_taskID, "FAILED"] call BIS_fnc_taskSetState;
                MISSION_var_task1_running = false;
                if (!isNull _failTrigger) then { deleteVehicle _failTrigger; };
                
                // Nettoyage markers
                {
                    if (!isNull _x) then {
                        private _m = _x getVariable ["captiveMarkerName", ""];
                        if (_m != "") then { deleteMarker _m; };
                    };
                } forEach MISSION_var_task1_fugitives;
                

                [] spawn MISSION_fnc_task_x_failure;
            };
        };
    };
};