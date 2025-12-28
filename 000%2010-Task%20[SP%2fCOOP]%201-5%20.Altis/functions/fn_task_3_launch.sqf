/*
    Description :
    Lance la Tâche 3 : "Guerre totale !"
    Enclenche un affrontement majeur avec support aérien allié contre des défenses blindées.
*/

params [["_mode", "INIT"], ["_params", []]];

if (!isServer) exitWith {};

switch (_mode) do {
    case "INIT": {
        
        // Initialisation de la variable globale pour communication inter-threads (suivi des chars actifs)
        MISSION_var_task3_activeTanks = [];

        // 1. Création de la Tâche
        [
            true,
            "task_3",
            [
                localize "STR_TASK_3_DESC",
                localize "STR_TASK_3_TITLE",
                ""
            ],
            objNull,
            "CREATED",
            1,
            true,
            "ATTACK",
            true
        ] call BIS_fnc_taskCreate;

        // 2. Support Aérien Allié
        [] spawn {
            // Fonction auxiliaire pour récupérer un type d'avion aléatoire en mémoire
            private _fnc_getPlaneType = {
                if (!isNil "MISSION_var_planes" && {count MISSION_var_planes > 0}) then {
                    (selectRandom MISSION_var_planes) select 1
                } else {
                    "" 
                };
            };

            // Spawn de 2 avions
            for "_i" from 1 to 2 do {
                // Détermine position de spawn depuis l'objet "task_3_spawn_01"
                private _spawnPos = [0,0,0];
                private _spawnDir = 0;
                private _spawnObj = missionNamespace getVariable ["task_3_spawn_01", objNull];
                
                if (!isNull _spawnObj) then {
                    _spawnPos = getPos _spawnObj;
                    _spawnDir = getDir _spawnObj;
                } else {
                     _spawnPos = player getRelPos [2000, 0]; // Sécurité
                };

                // Détermine le type d'avion
                private _planeType = call _fnc_getPlaneType;
                if (_planeType == "") then { _planeType = "I_Plane_Fighter_04_F"; }; // Par défaut

                // Spawn Avion - FORCE le camp WEST (alliés)
                private _planeGrp = createGroup [west, true];
                private _plane = createVehicle [_planeType, _spawnPos, [], 0, "FLY"];
                
                _plane setDir _spawnDir;
                _plane setPosATL [_spawnPos select 0, _spawnPos select 1, 0.7]; 
                _plane setVelocityModelSpace [0, 150, 0]; // Vitesse initiale
                
                // Applique le loadout (pylônes) sauvegardé si disponible
                if (!isNil "MISSION_var_planes" && {count MISSION_var_planes > 0}) then {
                    private _planeData = MISSION_var_planes select 0;
                    private _savedPylons = _planeData select 5;
                    if (count _savedPylons > 0) then {
                        {
                            _plane setPylonLoadout [_forEachIndex + 1, _x, true];
                        } forEach _savedPylons;
                    };
                }; 
                
                // Création du Pilote avec l'équipement du Joueur
                private _pilot = _planeGrp createUnit [typeOf player, [0,0,0], [], 0, "NONE"];
                _pilot moveInDriver _plane;
                _pilot setUnitLoadout (getUnitLoadout player);
                _pilot setCaptive false; 
                
                // Compétences & Moral (Réglés haut pour l'efficacité)
                _pilot setSkill ["aimingAccuracy", 0.90];
                _pilot setSkill ["aimingShake", 0.90];
                _pilot setSkill ["aimingSpeed", 0.90];
                _pilot setSkill ["spotDistance", 0.90];
                _pilot setSkill ["spotTime", 0.90];
                _pilot setSkill ["courage", 1.0];
                _pilot setSkill ["reloadSpeed", 0.90];
                _pilot setSkill ["commanding", 0.90];
                _pilot setSkill ["general", 0.90];
                
                _pilot allowFleeing 0.05; // Très peu de chance de fuite
                
                _plane flyInHeight 300; // Altitude basse pour attaques au sol
                
                // Comportement - Mode COMBAT pour engagement réel
                _planeGrp setBehaviour "COMBAT"; 
                _planeGrp setCombatMode "RED";
                _planeGrp enableAttack true;
                
                // Configuration Waypoint SAD (Search and Destroy) pour attaque agressive
                private _targetObj = missionNamespace getVariable ["task_3_spawn_02", objNull];
                // Cible par défaut : le deuxième point de spawn ennemi ou le premier
                private _targetPos = if (!isNull _targetObj) then { getPos _targetObj } else { _spawnPos };
                
                private _wp = _planeGrp addWaypoint [_targetPos, 500];
                _wp setWaypointType "SAD"; // Chercher et Détruire
                _wp setWaypointBehaviour "COMBAT";
                _wp setWaypointCombatMode "RED"; 
                _wp setWaypointSpeed "FULL";
                _planeGrp setCurrentWaypoint _wp;

                // Boucle de ciblage agressif (Bidirectionnel : Avion <-> Char)
                [_pilot, _plane] spawn {
                    params ["_unit", "_vehicle"];
                    sleep 10;
                    
                    // Attend qu'il y ait des chars actifs
                    waitUntil { sleep 1; (!isNil "MISSION_var_task3_activeTanks" && {count MISSION_var_task3_activeTanks > 0}) || !(["task_3"] call BIS_fnc_taskExists) };
                    
                    while {alive _unit && {!isNil "MISSION_var_task3_activeTanks"} && {count MISSION_var_task3_activeTanks > 0} && !(_unit getVariable ["RTB", false])} do {
                        private _aliveTanks = MISSION_var_task3_activeTanks select { alive _x };
                        if (count _aliveTanks > 0) then {
                            private _target = selectRandom _aliveTanks;
                            
                            // --- LOGIQUE ATTAQUE AVION ---
                            // Révéler la cible
                            _unit reveal [_target, 4];
                            (group _unit) reveal [_target, 4];
                            
                            // Laser (Backup pour guidage)
                            if (isNull (nearestObject [_target, "LaserTargetW"])) then {
                                private _laser = createVehicle ["LaserTargetW", getPos _target, [], 0, "NONE"];
                                _laser attachTo [_target, [0,0,1.5]];
                            };
                            
                            // Engager
                            _unit doTarget _target;
                            _unit doFire _target; 
                            
                            // --- LOGIQUE ATTAQUE CHAR (Force réaction AA) ---
                            {
                                private _tank = _x;
                                private _tankGrp = group (driver _tank);
                                
                                // Révéler l'avion au char
                                _tankGrp reveal [_vehicle, 4];
                                (gunner _tank) doTarget _vehicle;
                                (commander _tank) doTarget _vehicle;
                                
                                _tankGrp setCombatMode "RED";
                                _tankGrp setBehaviour "COMBAT";
                                
                            } forEach _aliveTanks;
                        };
                        
                        // Attendre plus longtemps pour permettre les passes d'attaque sans reset l'IA
                        sleep 8; 
                    };
                };

                // Timer de patrouille & Logique RTB (Return To Base)
                [_pilot, _plane, _planeGrp] spawn {
                    params ["_unit", "_vehicle", "_group"];
                    
                    sleep 360; // 6 minutes sur zone
                    
                    if (alive _unit) then {
                        hint (localize "STR_HINT_AIR_SUPPORT_END");
                        _unit setVariable ["RTB", true, true]; // Marqueur Return To Base
                        
                        // Efface les waypoints existants
                        while {(count (waypoints _group)) > 0} do { deleteWaypoint ((waypoints _group) select 0); };
                        
                        // Ordre de déplacement vers un point distant
                        _group setBehaviour "CARELESS";
                        _group setCombatMode "BLUE"; 
                        _group setSpeedMode "FULL";
                        
                        private _wp = _group addWaypoint [[0,0,1000], 0]; // Point "loin" en [0,0] altitude 1000
                        _wp setWaypointType "MOVE";
                        _group setCurrentWaypoint _wp;
                        
                        // Attend le départ puis supprime
                        sleep 60;
                        if (alive _vehicle) then { deleteVehicle _vehicle; };
                        if (alive _unit) then { deleteVehicle _unit; }; // supprime le pilote
                    };
                };

                // Petit délai entre le décollage du 1er et du 2ème avion
                if (_i < 2) then { sleep 25; };
            };
        };

        // 3. Logique de Spawn des Ennemis
        private _allSpawns = [];
        // Recherche des marqueurs "task_3_spawn_02" à "task_3_spawn_12"
        for "_i" from 2 to 12 do {
            private _markerName = format ["task_3_spawn_%1", if (_i < 10) then {"0" + str _i} else {str _i}];
            private _spawnObj = missionNamespace getVariable [_markerName, objNull];
            
            if (!isNull _spawnObj) then {
                _allSpawns pushBack _spawnObj;
            };
        };
        
        if (count _allSpawns < 1) exitWith {};

        _allSpawns = _allSpawns call BIS_fnc_arrayShuffle;
        
        // Distribution des spawns (Chars vs Infanterie)
        private _tankSpawns = [];
        private _infantrySpawns = [];
        
        // Les 3 premiers spawns aléatoires pour les chars, le reste pour l'infanterie
        if (count _allSpawns >= 3) then {
            _tankSpawns = _allSpawns select [0, 3];
            _infantrySpawns = _allSpawns select [3, 999];
        } else {
            _tankSpawns = _allSpawns;
        };

        // Vérification Variables
        if (isNil "MISSION_var_tanks") then { MISSION_var_tanks = []; };
        if (isNil "MISSION_var_enemies") then { MISSION_var_enemies = []; };
        if (isNil "MISSION_var_officers") then { MISSION_var_officers = []; };

        private _fnc_getRandomType = {
            params ["_varArray"];
            if (isNil "_varArray" || {count _varArray == 0}) exitWith {""};
            private _entry = selectRandom _varArray;
            _entry select 1 
        };

        private _tankType = [MISSION_var_tanks] call _fnc_getRandomType;
        if (_tankType == "") then { _tankType = "O_MBT_02_cannon_F"; }; // Tank par défaut
 
        private _infType = [MISSION_var_enemies] call _fnc_getRandomType;
        if (_infType == "") then { _infType = "O_Soldier_F"; }; 
        
        private _offType = [MISSION_var_officers] call _fnc_getRandomType;
        if (_offType == "") then { _offType = "O_officer_F"; }; 

        // -- Spawn des Chars (Utilisation Variable Globale) --
        // Type de cible aérienne depuis la mémoire (pour que les avions visent mieux)
        private _airTargetType = "";
        if (!isNil "MISSION_var_airtargets" && {count MISSION_var_airtargets > 0}) then {
            _airTargetType = (MISSION_var_airtargets select 0) select 1;
        };
        if (_airTargetType == "") then { _airTargetType = "TargetP_Inf_F"; }; // Repli sur cible visible si pas de mémoire
        
        {
            private _spawnObj = _x;
            private _pos = getPos _spawnObj;
            private _dir = getDir _spawnObj;
            
            private _tank = createVehicle [_tankType, _pos, [], 0, "NONE"];
            _tank setDir _dir;
            _tank setPos _pos;
            
            // Assure la création de l'équipage complet
            createVehicleCrew _tank; 
            
            // debug
            // systemChat format ["DEBUG: Tank Created (%1) at %2. Crew Count: %3", typeOf _tank, _pos, count crew _tank];
            
            // Applique un loadout aléatoire ennemi à l'équipage
            if (!isNil "MISSION_var_enemies" && {count MISSION_var_enemies > 0}) then {
                private _randomEnemyData = selectRandom MISSION_var_enemies;
                private _loadout = _randomEnemyData select 5; // Index 5 est le loadout
                
                {
                    _x setUnitLoadout _loadout;
                } forEach (crew _tank);
            };
            
            private _group = group (driver _tank);
            _group enableAttack true;
            _group setCombatMode "RED";
            _group setBehaviour "COMBAT";
            
            _tank setFuel 0; // Immobilise le tank (pour le rendre tourelle statique défense) mais garde l'IA active
            
            // Création Marqueur Carte
            private _markerName = format ["m_tank_%1", _pos]; 
            createMarker [_markerName, _pos];
            _markerName setMarkerType "o_armor";
            _markerName setMarkerColor "ColorRed";
            _markerName setMarkerText (localize "STR_MARKER_TANK");
            _tank setVariable ["assignedMarker", _markerName];
            
            // Attache une cible aérienne invisible au tank (aide à la visée IA avion)
            private _target = createVehicle [_airTargetType, _pos, [], 0, "NONE"];
            _target attachTo [_tank, [0, 0, 2]]; // Attache 2m au-dessus
            _target setVectorUp [0, 0, 1];
            
            MISSION_var_task3_activeTanks pushBack _tank;
            
        } forEach _tankSpawns;

        // -- Spawn des Patrouilles d'Infanterie --
        private _activeGroups = [];
        
        {
            private _spawnObj = _x;
            private _pos = getPos _spawnObj;
            
            private _group = createGroup east;
            _group createUnit [_offType, _pos, [], 0, "NONE"]; // 1 Officier
            for "_k" from 1 to 5 do {
                _group createUnit [_infType, _pos, [], 5, "NONE"]; // 5 Soldats
            };
            _activeGroups pushBack _group;
            
        } forEach _infantrySpawns;
        
        // 4. Logique de Patrouille
        [_activeGroups, _allSpawns] spawn {
            params ["_groups", "_spawnObjects"];
            while { ["task_3"] call BIS_fnc_taskExists && { !(["task_3"] call BIS_fnc_taskCompleted) } } do {
                {
                    private _grp = _x;
                    if (!isNull _grp && { {alive _x} count (units _grp) > 0 }) then {
                         // Choisit un point de spawn au hasard comme prochain waypoint
                        private _targetObj = selectRandom _spawnObjects;
                        private _wp = _grp addWaypoint [getPos _targetObj, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "FULL";
                        _wp setWaypointBehaviour "AWARE";
                        _grp setCurrentWaypoint _wp;
                    };
                } forEach _groups;
                sleep 40; // Mise à jour des ordres toutes les 40s
            };
        };

        // 5. Moniteur de condition de victoire (Utilise Variable Globale)
        [] spawn {
            sleep 5;
            
            waitUntil {
                sleep 2;
                
                // Nettoyage des marqueurs pour les chars détruits
                {
                    if (!alive _x) then {
                        private _m = _x getVariable ["assignedMarker", ""];
                        if (_m != "") then { deleteMarker _m; };
                    };
                } forEach MISSION_var_task3_activeTanks;

                // Compte les tanks vivants
                private _aliveTanks = MISSION_var_task3_activeTanks select { alive _x };
                count _aliveTanks == 0 // Condition succès : 0 tank vivant
            };
            
            ["task_3", "SUCCEEDED"] call BIS_fnc_taskSetState;
            hint format [localize "STR_TASK_3_TITLE" + " - COMPLETED"];
            
            // Nettoyage global
            MISSION_var_task3_activeTanks = nil;
        };
    };
};
