/*
    Fonction: MISSION_fnc_task_1_launch
    Description: Fait apparaître des ennemis attaquant l'officier.
    - Toutes les 3 secondes : spawn 1 fantassin
    - Après avoir atteint le max d'infanterie, spawn 1-2 véhicules (PAS de chars)
    - S'arrête après 10 spawns au total
*/

// Sécurité : Code exécuté uniquement sur le serveur
if (!isServer) exitWith {};

// Attend que la variable liste des ennemis soit initialisée
waitUntil { !isNil "MISSION_var_enemies" };
if (count MISSION_var_enemies == 0) exitWith {}; // Arrête si pas d'ennemis configurés

// Liste des marqueurs possibles pour l'apparition des ennemis
private _spawnMarkers = [
    "task_1_spawn_01", "task_1_spawn_02", "task_1_spawn_03", 
    "task_1_spawn_04", "task_1_spawn_05", "task_1_spawn_06"
];

// ============================================================================
// Créer la tâche Arma 3
// ============================================================================
private _taskID = "task_1_hq_defense";

[
    true,                                           // Exécuter globalement (tous les clients)
    [_taskID],                                      // ID de la tâche
    [
        localize "STR_TASK_1_DESC",                 // Description
        localize "STR_TASK_1_TITLE",                // Titre
        ""                                          // Marqueur (optionnel)
    ],
    getPosWorld officier_task_giver,                // Position de la tâche (sur l'officier)
    "CREATED",                                      // État initial
    1,                                              // Priorité
    true,                                           // Afficher notification
    "defend"                                        // Type d'icône de tâche
] call BIS_fnc_taskCreate;

// Variable globale pour suivre les unités ennemies spawnées spécifiquement pour cette tâche
MISSION_var_task1_spawned_enemies = [];

// Thread de gestion du spawn des vagues d'ennemis
[_spawnMarkers] spawn {
    params ["_spawnMarkers"];
    
    // Configuration de la vague
    private _maxInfantry = 5 + floor (random 6);  // Entre 5 et 10 fantassins
    private _spawnedInfantry = 0;                 // Compteur infanterie
    private _vehiclesSpawned = false;             // Flag spawn véhicules
    private _totalSpawns = 0;                     // Total unités
    private _maxTotalSpawns = 10;                 // Limite absolue
    
    // Création du groupe d'infanterie
    private _grpInf = createGroup [east, true];
    _grpInf setBehaviour "AWARE";  // Comportement : Conscient / Alerte
    _grpInf setCombatMode "RED";   // Feu à volonté
    _grpInf enableAttack true;     // Autoriser l'attaque
    
    // Boucle de spawn
    while {_totalSpawns < _maxTotalSpawns} do {
        sleep 3; // Délai entre chaque spawn
        
        // Sélection pseudo-aléatoire du point de spawn
        private _spawnMarker = selectRandom _spawnMarkers;
        private _spawnObj = missionNamespace getVariable [_spawnMarker, objNull];
        // Calcul position (sécurité si objet null)
        private _spawnPos = if (!isNull _spawnObj) then { getPos _spawnObj } else { [0,0,0] };
        
        if (_spawnPos isEqualTo [0,0,0]) then { continue; }; // Skip si position invalide
        
        // Spawn 1 Infanterie par itération
        if (_spawnedInfantry < _maxInfantry && _totalSpawns < _maxTotalSpawns) then {
            if (count MISSION_var_enemies > 0) then {
                // Sélection d'un template d'ennemi aléatoire
                private _template = selectRandom MISSION_var_enemies;
                _template params ["_tVar", "_tType", "_tPos", "_tDir", "_tSide", "_tLoadout"];
                
                // Création unité
                private _unit = _grpInf createUnit [_tType, _spawnPos, [], 5, "NONE"];
                _unit setUnitLoadout _tLoadout;
                
                // Révéler la cible (Officier) à l'unité pour qu'elle la traque
                _unit reveal [officier_task_giver, 4];
                
                // Donner l'ordre d'attaquer directement la cible
                _unit doTarget officier_task_giver;
                _unit doFire officier_task_giver;
                
                _spawnedInfantry = _spawnedInfantry + 1;
                _totalSpawns = _totalSpawns + 1;
                
                // Donner un nom unique à l'unité pour le suivi interne Arma
                private _unitName = format ["task1_enemy_%1", _totalSpawns];
                _unit setVehicleVarName _unitName;
                missionNamespace setVariable [_unitName, _unit, true];
                
                // Ajouter à la liste de suivi du script
                MISSION_var_task1_spawned_enemies pushBack _unit;
                
                // Configuration initiale du groupe au premier spawn
                if (_spawnedInfantry == 1) then {
                    _grpInf setBehaviour "AWARE";   // Important pour le pathfinding en bâtiment
                    _grpInf setCombatMode "RED";
                    _grpInf setSpeedMode "FULL";    // Courir
                    
                    // Création waypoint SAD (Search and Destroy) sur l'officier
                    private _wp = _grpInf addWaypoint [getPosWorld officier_task_giver, 5];
                    _wp setWaypointType "SAD";
                    _wp setWaypointBehaviour "AWARE";
                    _wp setWaypointCombatMode "RED";
                    _wp setWaypointCompletionRadius 3;
                };
                
                // Thread individuel (micro-skill) pour la gestion du combat en intérieur (CQB)
                [_unit] spawn {
                    params ["_unit"];
                    
                    // Attendre que l'unité soit proche du bâtiment cible (30m)
                    waitUntil { sleep 1; (!alive _unit) || (_unit distance batiment_officer < 30) };
                    if (!alive _unit) exitWith {};
                    
                    // Récupérer les positions tactiques intérieures du bâtiment
                    private _positions = batiment_officer buildingPos -1;
                    if (count _positions == 0) exitWith {};
                    
                    // Forcer le mode debout ("UP") pour éviter que l'IA rampe et se bloque
                    _unit setUnitPos "UP";
                    (group _unit) setBehaviour "AWARE";
                    
                    // Faire parcourir les positions du bâtiment (nettoyage pièce par pièce)
                    {
                        if (!alive _unit) exitWith {};
                        if (!alive officier_task_giver) exitWith {};
                        
                        _unit doMove _x;
                        
                        // Attendre max 10s pour atteindre la position (évite blocage infini)
                        private _timeout = time + 10;
                        waitUntil { sleep 0.5; (!alive _unit) || (_unit distance _x < 2) || (time > _timeout) };
                        
                        // Si contact visuel avec l'officier, engager immédiatement
                        if (alive _unit && alive officier_task_giver) then {
                            _unit reveal [officier_task_giver, 4];
                            _unit doTarget officier_task_giver;
                            _unit doFire officier_task_giver;
                        };
                        
                        sleep 0.5;
                    } forEach _positions;
                    
                    // Revenir au mode de posture automatique après la fouille
                    _unit setUnitPos "AUTO";
                };
            };
        };
        
        // Spawn Véhicules une fois l'infanterie au complet
        if (_spawnedInfantry >= _maxInfantry && !_vehiclesSpawned && _totalSpawns < _maxTotalSpawns) then {
            _vehiclesSpawned = true;
            
            private _nbVeh = 1 + floor (random 2); // 1 ou 2 véhicules
            
            for "_v" from 1 to _nbVeh do {
                if (count MISSION_var_vehicles > 0 && _totalSpawns < _maxTotalSpawns) then {
                    // Sélection template véhicule
                    private _vTemplate = selectRandom MISSION_var_vehicles;
                    _vTemplate params ["_vVar", "_vType", "_vPos", "_vDir", "_vSide", "_vLoadout"];
                    
                    // Création véhicule
                    private _veh = createVehicle [_vType, _spawnPos, [], 15, "NONE"];
                    _veh setDir (getDir _spawnObj);
                    
                    private _grpVeh = createGroup [east, true];
                    _grpVeh setBehaviour "CARELESS"; // "CARELESS" pour éviter que le véhicule s'arrête au premier coup de feu
                    _grpVeh setCombatMode "RED";
                    
                    // Création Pilote
                    if (count MISSION_var_enemies > 0) then {
                        private _dTemplate = selectRandom MISSION_var_enemies;
                        _dTemplate params ["_dVar", "_dType", "", "", "", "_dLoadout"];
                        private _driver = _grpVeh createUnit [_dType, [0,0,0], [], 0, "NONE"];
                        _driver moveInDriver _veh;
                        _driver setUnitLoadout _dLoadout;
                    };
                    
                    // Création Tireur/Passager
                    if (count MISSION_var_enemies > 0) then {
                        private _cTemplate = selectRandom MISSION_var_enemies;
                        _cTemplate params ["_cVar", "_cType", "", "", "", "_cLoadout"];
                        private _crew = _grpVeh createUnit [_cType, [0,0,0], [], 0, "NONE"];
                        // Priorité : Gunner > Commander > Cargo
                        if (_veh emptyPositions "Gunner" > 0) then { _crew moveInGunner _veh; }
                        else { if (_veh emptyPositions "Commander" > 0) then { _crew moveInCommander _veh; }
                        else { _crew moveInCargo _veh; };};
                        _crew setUnitLoadout _cLoadout;
                    };
                    
                    // Ordre de mouvement vers le QG
                    _grpVeh move (getPosWorld officier_task_giver);
                    
                    // Script IA véhicule : Combattre une fois arrivé
                    [_veh, _grpVeh] spawn {
                        params ["_veh", "_grp"];
                        // Attendre arrivée
                        waitUntil { sleep 1; (!alive _veh) || (_veh distance officier_task_giver < 20) };
                        
                        if (alive _veh) then {
                            // Débarquer
                            { unassignVehicle _x; } forEach (units _grp);
                            units _grp allowGetIn false;
                            _grp leaveVehicle _veh;
                            _veh lock false;
                            
                            // Passer en mode combat
                            _grp setBehaviour "COMBAT";
                            // Révéler et attaquer la cible
                            { _x reveal [officier_task_giver, 4]; _x doTarget officier_task_giver; } forEach (units _grp);
                            private _wp = _grp addWaypoint [getPosWorld officier_task_giver, 5];
                            _wp setWaypointType "SAD";
                            _wp setWaypointBehaviour "COMBAT";
                        };
                    };
                    
                    _totalSpawns = _totalSpawns + 1;
                };
            };
        };
    };
};

// ============================================================================
// Thread de surveillance des conditions de victoire/défaite
// ============================================================================
[] spawn {
    private _taskID = "task_1_hq_defense";
    private _spawnComplete = false;
    
    // Attendre que le spawn commence (au moins 1 ennemi présent)
    waitUntil { sleep 3; count MISSION_var_task1_spawned_enemies > 0 };
    
    // Attendre que le spawn soit terminé (10 spawns max) ou timeout de 60s
    private _startTime = time;
    waitUntil { 
        sleep 3; 
        _spawnComplete = (count MISSION_var_task1_spawned_enemies >= 10) || (time - _startTime > 60);
        _spawnComplete || !alive officier_task_giver || !alive player 
    };
    
    // Boucle de vérification principale (toutes les 5 secondes)
    while {true} do {
        sleep 5;
        
        // Condition d'échec : officier (VIP) ou joueur mort
        if (!alive officier_task_giver || !alive player) exitWith {
            [_taskID, "FAILED"] call BIS_fnc_taskSetState;
        };
        
        // Compter les ennemis vivants (uniquement infanterie "Man", on ignore les véhicules vides)
        private _aliveEnemies = 0;
        {
            if (alive _x) then {
                if (_x isKindOf "Man") then {
                    _aliveEnemies = _aliveEnemies + 1;
                };
            };
        } forEach MISSION_var_task1_spawned_enemies;
        
        // Condition de succès : tous les ennemis sont éliminés ET la phase de spawn est finie
        if (_aliveEnemies == 0 && _spawnComplete) exitWith {
            [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
        };
    };
};
