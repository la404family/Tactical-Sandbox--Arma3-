/*
    Description :
    Lance la Tâche 3 : "Destruction de cargaisons"
    Détruire des cargaisons de munitions ennemies dissimulées et protégées par des ennemis.
    Support aérien allié pour survol de reconnaissance.
    Objectif : détruire toutes les cargaisons ennemies
*/

params [["_mode", "INIT"], ["_params", []]];

if (!isServer) exitWith {};

switch (_mode) do {
    case "INIT": {
        
        // Initialisation de la variable globale pour suivi des cargaisons actives
        MISSION_var_task3_activeCargaisons = [];

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

        ["task_3"] remoteExec ["MISSION_fnc_task_briefing", 0, true];

        // 2. Support Aérien Allié (Survol de reconnaissance)
        // DÉLAI : Le support aérien arrive entre 5 et 10 minutes après le lancement de la mission
        [] spawn {
            // Délai aléatoire entre 5 et 10 minutes (300 à 600 secondes)
            private _delai = 300 + floor(random 300);
            sleep _delai;
            
            // Avertissement aux joueurs que le support aérien est en cours
            hint (localize "STR_HINT_AIR_SUPPORT_INCOMING");
            
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
                
                _pilot allowFleeing 0.05;
                
                _plane flyInHeight 300;
                
                // Comportement - Mode COMBAT pour engagement réel
                _planeGrp setBehaviour "COMBAT"; 
                _planeGrp setCombatMode "RED";
                _planeGrp enableAttack true;
                
                // Configuration Waypoint SAD (Search and Destroy) pour attaque agressive
                private _targetObj = missionNamespace getVariable ["task_3_spawn_02", objNull];
                private _targetPos = if (!isNull _targetObj) then { getPos _targetObj } else { _spawnPos };
                
                private _wp = _planeGrp addWaypoint [_targetPos, 500];
                _wp setWaypointType "SAD";
                _wp setWaypointBehaviour "COMBAT";
                _wp setWaypointCombatMode "RED"; 
                _wp setWaypointSpeed "FULL";
                _planeGrp setCurrentWaypoint _wp;

                // Boucle de ciblage sur les cargaisons et ennemis
                [_pilot, _plane] spawn {
                    params ["_unit", "_vehicle"];
                    sleep 10;
                    
                    waitUntil { sleep 1; (!isNil "MISSION_var_task3_activeCargaisons" && {count MISSION_var_task3_activeCargaisons > 0}) || !(["task_3"] call BIS_fnc_taskExists) };
                    
                    while {alive _unit && {!isNil "MISSION_var_task3_activeCargaisons"} && {count MISSION_var_task3_activeCargaisons > 0} && !(_unit getVariable ["RTB", false])} do {
                        private _aliveCargaisons = MISSION_var_task3_activeCargaisons select { alive _x };
                        if (count _aliveCargaisons > 0) then {
                            private _target = selectRandom _aliveCargaisons;
                            
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
                        };
                        
                        sleep 8; 
                    };
                };

                // Timer de patrouille & Logique RTB (Return To Base)
                [_pilot, _plane, _planeGrp] spawn {
                    params ["_unit", "_vehicle", "_group"];
                    
                    // Attente : 4 minutes OU s'il ne reste qu'une seule cargaison (ou moins)
                    private _endTime = time + 280;
                    
                    sleep 15; 
                    
                    waitUntil {
                        sleep 2;
                        
                        private _timeExpired = time > _endTime;
                        
                        private _aliveCargaisonsCount = { alive _x } count MISSION_var_task3_activeCargaisons;
                        private _totalCargaisonsRecorded = count MISSION_var_task3_activeCargaisons;
                        
                        _timeExpired || (_totalCargaisonsRecorded > 0 && _aliveCargaisonsCount <= 1)
                    };
                    
                    if (alive _unit) then {
                        hint (localize "STR_HINT_AIR_SUPPORT_END");
                        _unit setVariable ["RTB", true, true];
                        
                        while {(count (waypoints _group)) > 0} do { deleteWaypoint ((waypoints _group) select 0); };
                        
                        _group setBehaviour "CARELESS";
                        _group setCombatMode "BLUE"; 
                        _group setSpeedMode "FULL";
                        
                        private _wp = _group addWaypoint [[0,0,1000], 0];
                        _wp setWaypointType "MOVE";
                        _group setCurrentWaypoint _wp;
                        
                        sleep 80;
                        if (alive _vehicle) then { deleteVehicle _vehicle; };
                        if (alive _unit) then { deleteVehicle _unit; };
                    };
                };

                // Petit délai entre le décollage du 1er et du 2ème avion
                if (_i < 2) then { sleep 25; };
            };
        };

        // 3. Logique de Spawn des Ennemis
        private _allSpawns = [];
        // Recherche des marqueurs "task_3_spawn_02" à "task_3_spawn_18"
        for "_i" from 2 to 18 do {
            private _markerName = format ["task_3_spawn_%1", if (_i < 10) then {"0" + str _i} else {str _i}];
            private _spawnObj = missionNamespace getVariable [_markerName, objNull];
            
            if (!isNull _spawnObj) then {
                _allSpawns pushBack _spawnObj;
            };
        };
        
        if (count _allSpawns < 1) exitWith {};

        _allSpawns = _allSpawns call BIS_fnc_arrayShuffle;
        
        // Distribution des spawns (Cargaisons vs Infanterie)
        private _cargaisonSpawns = [];
        private _infantrySpawns = [];
        
        // Les 4 premiers spawns aléatoires pour les cargaisons, le reste pour l'infanterie
        if (count _allSpawns >= 4) then {
            _cargaisonSpawns = _allSpawns select [0, 4];
            _infantrySpawns = _allSpawns select [4, 999];
        } else {
            _cargaisonSpawns = _allSpawns;
        };

        // Vérification Variables
        if (isNil "MISSION_var_cargaisons") then { MISSION_var_cargaisons = []; };
        if (isNil "MISSION_var_enemies") then { MISSION_var_enemies = []; };
        if (isNil "MISSION_var_officers") then { MISSION_var_officers = []; };

        private _fnc_getRandomType = {
            params ["_varArray"];
            if (isNil "_varArray" || {count _varArray == 0}) exitWith {""};
            private _entry = selectRandom _varArray;
            _entry select 1 
        };

        // Type de cargaison depuis la mémoire
        private _cargaisonType = [MISSION_var_cargaisons] call _fnc_getRandomType;
        if (_cargaisonType == "") then { _cargaisonType = "O_Truck_03_ammo_F"; }; // Camion de munitions par défaut
 
        private _infType = [MISSION_var_enemies] call _fnc_getRandomType;
        if (_infType == "") then { _infType = "O_Soldier_F"; }; 
        
        private _offType = [MISSION_var_officers] call _fnc_getRandomType;
        if (_offType == "") then { _offType = "O_officer_F"; }; 

        // Type de cible aérienne depuis la mémoire
        private _airTargetType = "";
        if (!isNil "MISSION_var_airtargets" && {count MISSION_var_airtargets > 0}) then {
            _airTargetType = (MISSION_var_airtargets select 0) select 1;
        };
        if (_airTargetType == "") then { _airTargetType = "TargetP_Inf_F"; };
        
        // -- Spawn des Cargaisons (VIDES et VERROUILLEES) --
        {
            private _spawnObj = _x;
            private _pos = getPos _spawnObj;
            private _dir = getDir _spawnObj;
            
            // Création du véhicule de cargaison
            private _cargaison = createVehicle [_cargaisonType, _pos, [], 0, "NONE"];
            _cargaison setDir _dir;
            _cargaison setPos _pos;
            
            // IMPORTANT : Pas d'équipage - Véhicule vide
            // Le véhicule est verrouillé
            _cargaison lock 2; // 2 = Verrouillé pour tous
            _cargaison setFuel 0; // Immobilise le véhicule
            
            // Création Marqueur Carte
            private _markerName = format ["m_cargaison_%1", _pos]; 
            createMarker [_markerName, _pos];
            _markerName setMarkerType "o_support";
            _markerName setMarkerColor "ColorRed";
            _markerName setMarkerText (localize "STR_MARKER_CARGAISON");
            _cargaison setVariable ["assignedMarker", _markerName];
            
            // Attache une cible aérienne invisible (aide à la visée IA avion)
            private _target = createVehicle [_airTargetType, _pos, [], 0, "NONE"];
            _target attachTo [_cargaison, [0, 0, 2]];
            _target setVectorUp [0, 0, 1];
            
            MISSION_var_task3_activeCargaisons pushBack _cargaison;
            
            // Spawn de gardes autour de la cargaison (8 soldats par cargaison)
            private _guardGrp = createGroup [east, true];
            for "_g" from 1 to 8 do {
                private _guard = _guardGrp createUnit [_infType, _pos, [], 8, "NONE"];
                if (!isNil "MISSION_var_enemies" && {count MISSION_var_enemies > 0}) then {
                    _guard setUnitLoadout ((selectRandom MISSION_var_enemies) select 5);
                };
            };
            _guardGrp setBehaviour "AWARE";
            _guardGrp setCombatMode "RED";
            
        } forEach _cargaisonSpawns;

        // Les gardes des cargaisons sont les seuls ennemis (8 x 4 = 32 ennemis)

        // 5. Moniteur de condition de victoire
        [] spawn {
            sleep 5;
            
            waitUntil {
                sleep 2;
                
                // Nettoyage des marqueurs pour les cargaisons détruites
                {
                    if (!alive _x) then {
                        private _m = _x getVariable ["assignedMarker", ""];
                        if (_m != "") then { deleteMarker _m; };
                    };
                } forEach MISSION_var_task3_activeCargaisons;

                // Compte les cargaisons encore en état
                private _aliveCargaisons = MISSION_var_task3_activeCargaisons select { alive _x };
                count _aliveCargaisons == 0 // Condition succès : 0 cargaison restante
            };
            
            ["task_3", "SUCCEEDED"] call BIS_fnc_taskSetState;
            [] spawn MISSION_fnc_task_x_finish;
            hint format ["%1 - %2", localize "STR_TASK_3_TITLE", localize "STR_TASK_COMPLETED"];
            
            // Nettoyage global
            MISSION_var_task3_activeCargaisons = nil;
        };
    };
};
