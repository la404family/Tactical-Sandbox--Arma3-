/*
    Description :
    Lance la Tâche 8 : "La bataille de KAVALA"
    Objectif : Exécuter un officier ennemi.
    Renforts alliés, chars ennemis immobilisés, support aérien, patrouilles.
*/

if (!isServer) exitWith {};

// Initialisation de la tâche
private _taskID = "task_8";
private _taskDest = missionNamespace getVariable ["task_8_spawn_11", objNull]; // Lieu de l'officier

[
    true,
    _taskID,
    [
        localize "STR_TASK_8_DESC",
        localize "STR_TASK_8_TITLE",
        ""
    ],
    _taskDest,
    "CREATED",
    1,
    true,
    "KILL",
    true
] call BIS_fnc_taskCreate;

["task_8"] remoteExec ["MISSION_fnc_task_briefing", 0, true];
[8] call MISSION_fnc_task_x_tableau;

// Trigger de zone ( < 1000m de task_8_spawn_1 )
[] spawn {
    private _startTriggerPos = missionNamespace getVariable ["task_8_spawn_1", objNull];
    
    // Attente que le joueur soit proche
    waitUntil {
        sleep 2;
        private _isClose = false;
        {
            if (isPlayer _x && (_x distance _startTriggerPos < 2000)) exitWith { _isClose = true; };
        } forEach allPlayers;
        _isClose
    };

    // ========================================================================
    // 1. SPAWN UNITÉS ALLIÉES (Identiques aux joueurs)
    // ========================================================================
    private _spawnAllies = {
        params ["_spawnPointName"];
        private _spawnObj = missionNamespace getVariable [_spawnPointName, objNull];
        if (isNull _spawnObj) exitWith {};

        private _grp = createGroup [west, true];
        
        for "_i" from 1 to 3 do {
            // Modèle joueur aléatoire
            private _playerTemplate = selectRandom allPlayers; 
            if (isNil "_playerTemplate") then { _playerTemplate = player; };
            
            private _unit = _grp createUnit [typeOf _playerTemplate, getPos _spawnObj, [], 0, "NONE"];
            
            // Clonage apparence
            _unit setUnitLoadout (getUnitLoadout _playerTemplate);
            _unit setFace (face _playerTemplate);
            _unit setSpeaker (speaker _playerTemplate);
            private _insignia = [_playerTemplate] call BIS_fnc_getUnitInsignia;
            if (_insignia != "") then { [_unit, _insignia] call BIS_fnc_setUnitInsignia; };
            
            _unit setSkill 0.7; // Compétence moyenne
            
            sleep 0.5;
        };
        
        // Ajout au système de mouvement aléatoire
        _grp setVariable ["MISSION_task8_randomMove", true];
    };

    // 3 vagues sur spawn 1, 2, 3
    ["task_8_spawn_1"] call _spawnAllies;
    ["task_8_spawn_2"] call _spawnAllies;
    ["task_8_spawn_3"] call _spawnAllies;

    // ========================================================================
    // 2. SPAWN 45 ENNEMIS - Spawn 4
    // ========================================================================
    [] spawn {
        private _spawnObj = missionNamespace getVariable ["task_8_spawn_4", objNull];
        if (isNull _spawnObj) exitWith {};
        
        private _grp = createGroup [east, true];
        _grp setVariable ["MISSION_task8_randomMove", true];

        for "_i" from 1 to 45 do {
            private _type = "O_Soldier_F"; // Défaut
            if (!isNil "MISSION_var_enemies" && {count MISSION_var_enemies > 0}) then {
                _type = (selectRandom MISSION_var_enemies) select 1;
            };
            
            private _unit = _grp createUnit [_type, getPos _spawnObj, [], 5, "NONE"];
            
            if (!isNil "MISSION_var_enemies" && {count MISSION_var_enemies > 0}) then {
                _unit setUnitLoadout ((selectRandom MISSION_var_enemies) select 5);
            };
            
            sleep 0.5;
        };
    };

    // ========================================================================
    // 3. SYSTÈME DE DÉPLACEMENT ALÉATOIRE (Distance < 10m OU Délai > 55s)
    // ========================================================================
    // ========================================================================
    // 3. SYSTÈME DE DÉPLACEMENT ALÉATOIRE (Distance < 10m OU Délai > 55s)
    // ========================================================================
    [] spawn {
        // Collecte des points de passage (14 à 43)
        private _movePoints = [];
        for "_i" from 14 to 43 do {
            private _pName = format ["task_8_spawn_%1", _i];
            private _pObj = missionNamespace getVariable [_pName, objNull];
            if (!isNull _pObj) then { _movePoints pushBack (getPos _pObj); };
        };

        if (count _movePoints == 0) exitWith {};

        while {["task_8"] call BIS_fnc_taskExists} do {
            // Sélection des groupes concernés
            {
                private _grp = _x;
                if ((_grp getVariable ["MISSION_task8_randomMove", false]) && {side _grp in [west, east]}) then {
                    
                    // Traitement INDIVIDUEL de chaque unité du groupe
                    {
                        private _unit = _x;
                        
                        if (alive _unit) then {
                            // Récupération variables d'état de l'UNITÉ (et non plus du groupe)
                            private _lastMoveTime = _unit getVariable ["MISSION_task8_lastMoveTime", -999];
                            private _targetPos = _unit getVariable ["MISSION_task8_targetPos", [0,0,0]];
                            
                            // Conditions de changement : Temps écoulé OU Destination atteinte
                            private _timeElapsed = (time - _lastMoveTime) > 55;
                            private _reachedDest = (_unit distance _targetPos) < 10;
                            
                            // Si pas encore de cible (initial), ou temps écoulé, ou destination atteinte
                            if (_lastMoveTime == -999 || _timeElapsed || _reachedDest) then {
                                private _newPos = selectRandom _movePoints;
                                
                                // Commande de mouvement INDIVIDUELLE (casse la formation)
                                _unit doMove _newPos;
                                _unit setUnitPos "AUTO"; 
                                
                                // Mise à jour état UNITÉ
                                _unit setVariable ["MISSION_task8_targetPos", _newPos];
                                _unit setVariable ["MISSION_task8_lastMoveTime", time];
                            };
                        };
                    } forEach units _grp;

                    // Configuration globale du groupe pour encourager le mouvement/combat
                    _grp setSpeedMode "FULL";
                    _grp setBehaviour "COMBAT";
                };
            } forEach allGroups;
            
            sleep 5; // Vérification fréquente
        };
    };

    // ========================================================================
    // 4. SPAWN TANKS ENNEMIS (Délai 5s)
    // ========================================================================
    sleep 5;
    
    // Lieux possibles : 5 à 10
    private _tankSpawns = [];
    for "_i" from 5 to 10 do {
        private _n = format ["task_8_spawn_%1", _i];
        private _o = missionNamespace getVariable [_n, objNull];
        if (!isNull _o) then { _tankSpawns pushBack _o; };
    };
    
    if (count _tankSpawns > 0) then {
        _tankSpawns = _tankSpawns call BIS_fnc_arrayShuffle;
        
        // Initialisation variable globale pour ciblage (Parité Task 3)
        MISSION_var_task8_tanks = [];
        
        for "_i" from 0 to 2 do { // 3 tanks
            if (_i < count _tankSpawns) then {
                private _sp = _tankSpawns select _i;
                private _type = if (!isNil "task_x_tank_2") then { task_x_tank_2 } else { "O_T_MBT_04_command_F" };
                
                private _tank = createVehicle [_type, getPos _sp, [], 0, "NONE"];
                _tank setDir (getDir _sp);
                _tank setFuel 0.1; // Peu de carburant
                createVehicleCrew _tank; 
                _tank lock 3; // Verrouillé
                
                MISSION_var_task8_tanks pushBack _tank;
                
                // Marqueur pour debug/visibilité ? Optionnel.
            };
        };
    };

    // ========================================================================
    // 5. AVIONS ALLIÉS (Délai 5s après tanks)
    // ========================================================================
    // "Faire apparaitre 2 avions alliés... objectif détruire les tanks"
    
    sleep 5; // Attente que les tanks soient bien présents
    
    [] spawn {
        // --- LOGIQUE CLONÉE DE TASK 3 ---
        
        // Fonction auxiliaire pour récupérer un type d'avion aléatoire en mémoire
        private _fnc_getPlaneType = {
            if (!isNil "MISSION_var_planes" && {count MISSION_var_planes > 0}) then {
                (selectRandom MISSION_var_planes) select 1
            } else {
                "" 
            };
        };

        // Utiliser task_3_spawn_01 pour spawn avion comme ref (A149 Gryphon / EMP_A149_Gryphon mentionné)
        // Note: Le user a dit "L'avion ne nécessite aucun mod... L'avion est déjà dans : fn_task_x_memory"
        // Donc on priorise MISSION_var_planes s'il existe, sinon fallback sur ce qu'il a demandé ou vanilla.
        
        private _spawnRef = missionNamespace getVariable ["task_3_spawn_01", player];
        // Calcul position spawn loin derrière (comme task 3 logic un peu adaptée pour pas spawn sur task 3)
        private _spawnPosBase = if (!isNull _spawnRef) then { getPos _spawnRef } else { player getRelPos [3000, 180] };
        
        // Spawn de 2 avions
        for "_i" from 1 to 2 do {
            // Position décalée
            private _spawnPos = _spawnPosBase vectorAdd [0, _i * 100, 0];
            private _spawnDir = if (!isNull _spawnRef) then { getDir _spawnRef } else { 0 };

            // Détermine le type d'avion
            private _planeType = call _fnc_getPlaneType;
            if (_planeType == "") then { _planeType = "I_Plane_Fighter_04_F"; }; // Par défaut (Task 3 logic)


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
            
            // Boucle de ciblage SPÉCIFIQUE aux Tanks de Task 8 (Logique clonée de Task 3)
            [_pilot, _plane] spawn {
                params ["_unit", "_vehicle"];
                sleep 10;
                
                waitUntil { sleep 1; (!isNil "MISSION_var_task8_tanks" && {count MISSION_var_task8_tanks > 0}) || !(["task_8"] call BIS_fnc_taskExists) };
                
                while {alive _unit && {!isNil "MISSION_var_task8_tanks"} && {count MISSION_var_task8_tanks > 0} && !(_unit getVariable ["RTB", false])} do {
                    
                    private _aliveTanks = MISSION_var_task8_tanks select { alive _x };
                    
                    if (count _aliveTanks > 0) then {
                        private _target = selectRandom _aliveTanks;
                        
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
                
                // Attente : 4 minutes (240s) comme demandé pour Task 8
                sleep 240;
                
                if (alive _unit) then {
                    // hint (localize "STR_HINT_AIR_SUPPORT_END"); // Optionnel pour Task 8
                    _unit setVariable ["RTB", true, true];
                    
                    while {(count (waypoints _group)) > 0} do { deleteWaypoint ((waypoints _group) select 0); };
                    
                    _group setBehaviour "CARELESS";
                    _group setCombatMode "BLUE"; 
                    _group setSpeedMode "FULL";
                    
                    // S'éloigner
                    private _posExit = (getPos _vehicle) vectorAdd [0, 10000, 1000];
                    private _wp = _group addWaypoint [_posExit, 0];
                    _wp setWaypointType "MOVE";
                    _group setCurrentWaypoint _wp;
                    
                    sleep 60;
                    if (alive _vehicle) then { deleteVehicle _vehicle; };
                    if (alive _unit) then { deleteVehicle _unit; };
                };
            };

            // Petit délai entre le décollage du 1er et du 2ème avion
            if (_i < 2) then { sleep 25; };
        };
    };

    // ========================================================================
    // 6. SPAWN PATROUILLES (T+15s)
    // ========================================================================
    sleep 15; // 15s après le trigger (donc 10s après tanks)
    
    // 6 unités : 3 sur spawn 12, 3 sur spawn 13
    private _fnc_spawnPatrol = {
        params ["_spawnName"];
        private _sp = missionNamespace getVariable [_spawnName, objNull];
        if (isNull _sp) exitWith {};
        
        private _grp = createGroup [east, true];
        
        for "_i" from 1 to 3 do {
             private _type = "O_Soldier_F";
            if (!isNil "MISSION_var_enemies" && {count MISSION_var_enemies > 0}) then {
                _type = (selectRandom MISSION_var_enemies) select 1;
            };
            _grp createUnit [_type, getPos _sp, [], 2, "NONE"];
        };
        
        // Patrouille aléatoire 5-10m
        [_grp, getPos _sp, 10] call BIS_fnc_taskPatrol; 
    };
    
    ["task_8_spawn_12"] call _fnc_spawnPatrol;
    ["task_8_spawn_13"] call _fnc_spawnPatrol;

    // ========================================================================
    // 7. SPAWN OFFICIER (T+20s) - CIBLE PRINCIPALE
    // ========================================================================
    sleep 5; // 15 + 5 = 20s
    
    private _officerSpawn = missionNamespace getVariable ["task_8_spawn_11", objNull];
    if (!isNull _officerSpawn) then {
        private _grpOff = createGroup [east, true];
        private _typeOff = "O_officer_F";
         if (!isNil "MISSION_var_officers" && {count MISSION_var_officers > 0}) then {
            _typeOff = (selectRandom MISSION_var_officers) select 1;
        };
        
        private _officer = _grpOff createUnit [_typeOff, getPos _officerSpawn, [], 0, "NONE"];
        _officer setUnitRank "COLONEL";

        // Deplacement aleatoire 15m
        [_grpOff, getPos _officerSpawn, 15] call BIS_fnc_taskPatrol;

        // Marqueur sur l'officier (Mise a jour toutes les 3s)
        [_officer] spawn {
            params ["_target"];
            private _markerName = "task_8_officer_marker";
            createMarker [_markerName, getPos _target];
            _markerName setMarkerType "mil_objective";
            _markerName setMarkerColor "ColorRed";
            
            while {alive _target} do {
                _markerName setMarkerPos (getPos _target);
                sleep 3;
            };
            
            deleteMarker _markerName;
        };
        
        // Logic de victoire : Mort de l'officier
        [_officer] spawn {
            params ["_target"];
            waitUntil { sleep 1; !alive _target };
            
            // Succès
            ["task_8", "SUCCEEDED"] call BIS_fnc_taskSetState;
            [] spawn MISSION_fnc_task_x_finish;
        };
        
        // Marqueur sur l'officier pour aider les joueurs ? (Pas demandé explicitement, mais utile pour "Executer un officier")
        // La tâche est déjà sur sa position.
    };

};
