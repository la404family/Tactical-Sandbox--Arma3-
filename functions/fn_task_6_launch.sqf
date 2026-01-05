/*
    Description:
    Tâche 6 : Sauvetage des alliés.
    - Sélection d'un lieu de crash aléatoire.
    - Spawn d'un hélicoptère crashé (fumé).
    - Spawn de 8 survivants en état "Revive".
    - Gestion de la réussite (1 sauvé) ou échec (tous morts).
*/

// 1. Sélection du lieu de spawn aléatoire
// task_1_spawn_03 à task_1_spawn_06 est un chemin 
// task_1_spawn_07 à task_1_spawn_12 est un chemin 
// task_1_spawn_13 à task_1_spawn_18 est un chemin 
// task_1_spawn_19 à task_1_spawn_24 est un chemin 
// task_1_spawn_25 à task_1_spawn_30 est un chemin 
// task_1_spawn_31 à task_1_spawn_36 est un chemin 
// task_1_spawn_37 à task_1_spawn_42 est un chemin 
// task_1_spawn_43 à task_1_spawn_48 est un chemin 

private _validSpawnObjects = [];

for "_i" from 3 to 48 do {
    private _varName = format ["task_1_spawn_%1", if (_i < 10) then {"0" + str _i} else {str _i}];
    private _obj = missionNamespace getVariable [_varName, objNull];
    
    // On vérifie que l'objet existe avant de l'ajouter
    if (!isNull _obj) then {
        _validSpawnObjects pushBack _obj;
    };
};

if (count _validSpawnObjects == 0) exitWith {
    hint (localize "STR_ERR_NO_SPAWN_FOUND");
};

private _selectedObj = selectRandom _validSpawnObjects;
private _spawnPos = getPos _selectedObj;
private _selectedMarker = str _selectedObj; // Pour le debug

// systemChat format ["DEBUG: Task 6 selected object: %1", _selectedObj];
// systemChat format ["DEBUG: Task 6 spawn pos: %1", _spawnPos];

// Création de la tâche BIS
[
    true,
    ["task_6"],
    [
        localize "STR_TASK_6_DESC",
        localize "STR_TASK_6_TITLE",
        ""
    ],
    _spawnPos,
    "CREATED",
    1,
    true,
    "Heal",
    true
] call BIS_fnc_taskCreate;

["task_6"] remoteExec ["MISSION_fnc_task_briefing", 0, true];

// 2. Spawn de l'hélicoptère
private _heliClass = "B_Heli_Transport_03_F"; // Default Huron
if (!isNil "MISSION_var_helicopters") then {
    if (count MISSION_var_helicopters > 0) then {
        _heliClass = (MISSION_var_helicopters select 0) select 1;
    };
};

private _heli = createVehicle [_heliClass, _spawnPos, [], 0, "NONE"];
_heli setDir (random 360);
_heli setDamage 0.8;
_heli setFuel 0;

// Effet de fumée sur l'hélico
private _smoke = "#particlesource" createVehicle getPos _heli;
_smoke setParticleClass "WreckSmokeSmall";
_smoke attachTo [_heli, [0, 0, 0]];

// Marqueur sur la carte (Accident)
private _markerAccident = createMarker ["task_6_marker_accident", _spawnPos];
_markerAccident setMarkerType "mil_warning";
_markerAccident setMarkerColor "ColorRed";
_markerAccident setMarkerText localize "STR_TASK_6_TITLE";

// 3. Spawn des survivants
private _survivors = [];
private _grpSurvivors = createGroup west;
private _playerLoadout = getUnitLoadout player;

// Animation "Blessé au sol"
private _animInjured = "AinjPpneMstpSnonWrflDnon"; 

for "_i" from 1 to 8 do {
    private _unitPos = _spawnPos getPos [10 + random 10, random 360];
    private _unit = _grpSurvivors createUnit [typeOf player, _unitPos, [], 0, "NONE"];
    
    _unit setUnitLoadout _playerLoadout;
    _unit setDir (random 360);
    
    // Setup initial
    _unit setCaptive true; 
    _unit setVariable ["task_6_is_stabilized", false, true];
    
    // Force l'animation de blessé et désactive l'IA pour qu'ils ne bougent pas
    _unit disableAI "ANIM";
    _unit disableAI "MOVE";
    _unit disableAI "AUTOTARGET";
    _unit disableAI "TARGET";
    
    // On doit attendre un peu que l'unité soit init pour l'anim
    [_unit, _animInjured] spawn {
        params ["_unit", "_anim"];
        sleep 0.5;
        _unit switchMove _anim;
    };
    
    _survivors pushBack _unit;
    
    // Marqueur
    private _mkr = createMarker [format ["task_6_survivor_%1", _i], getPos _unit];
    _mkr setMarkerType "mil_dot";
    _mkr setMarkerColor "ColorBlue";
    _mkr setMarkerText format ["%1 %2", localize "STR_SURVIVOR", _i];
    
    _unit setVariable ["task_6_my_marker", _mkr];
    
    // --- ACTION PERSONNALISÉE : SOIGNER / REVIVE (MP COMPATIBLE via remoteExec) ---
    // On exécute l'ajout de l'action sur TOUS les clients (0) et les JIP (true)
    private _actionTitle = format ["<t color='#00FF00'>%1</t>", localize "STR_ACTION_REVIVE"];
    
    [_unit, [
        _actionTitle,
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            
            // Animation du soigneur (Kneel, Treat Patient)
            _caller playMove "AinvPknlMstpSnonWnonDnon_medic_1";
            
            // Délai de soin simulé (6 secondes)
            [_target, _caller, _actionId] spawn {
                params ["_target", "_caller", "_actionId"];
                sleep 6;
                
                if (!alive _target) exitWith { hint (localize "STR_NOTIF_TOO_LATE"); };
                if (!alive _caller) exitWith {};
                
                // Réussite - Variables globales propagées automatiquement par le dernier argument 'true'
                _target setVariable ["task_6_is_stabilized", true, true];
                _target setVariable ["task_6_stabilized_time", serverTime, true]; // Enregistrement de l'heure de stabilisation
                
                // Effets locaux (mais répliqués si setCaptive/setDamage/SwitchMove sont globaux)
                // setDamage est Global. setCaptive est Global. switchMove est Global. enableAI est Global.
                // joinSilent est Global.
                
                _target setDamage 0;
                _target setCaptive false;
                
                _target enableAI "ANIM";
                _target enableAI "MOVE";
                _target enableAI "AUTOTARGET";
                _target enableAI "TARGET";
                
                _target switchMove "AmovPpneMstpSrasWrflDnon"; 
                _target doFollow _caller; 
                [_target] joinSilent (group _caller); 
                
                // Notification locale pour le soigneur
                hint (localize "STR_NOTIF_SURVIVOR_SAVED");
                
                // Suppression de l'action via remoteExec pour que tout le monde voit l'action disparaitre
                [_target, _actionId] remoteExec ["removeAction", 0, true];
            };
        },
        nil,
        10,
        true,
        true,
        "",
        "alive _target && !(_target getVariable ['task_6_is_stabilized', false]) && _this distance _target < 5"
    ]] remoteExec ["addAction", 0, true]; // Target 0 (All clients), JIP true
};

// systemChat "DEBUG: Tâche 6 - Script V4 (MP RemoteExec) Chargé !";

// 5. Spawn des ennemis (5 à 10)
private _enemies = [];
private _grpEnemies = createGroup east;

// Gestion de la classe ennemie (Custom ou Default)
private _enemyClass = "O_Soldier_F";
if (!isNil "MISSION_var_enemies") then {
    if (count MISSION_var_enemies > 0) then {
        // MISSION_var_enemies format: [VarName, ClassName, Pos, Dir, Side, Loadout]
        _enemyClass = (selectRandom MISSION_var_enemies) select 1;
    };
};

private _enemyCount = 5 + round(random 5); // 5 à 10 ennemis

for "_i" from 1 to _enemyCount do {
    // Spawn entre 30m et 60m du crash
    private _spawnPosEnemy = _spawnPos getPos [30 + random 30, random 360];
    private _enemy = _grpEnemies createUnit [_enemyClass, _spawnPosEnemy, [], 0, "NONE"];
    
    _enemy setDir (_enemy getDir _spawnPos); // Regarde vers le crash
    _enemies pushBack _enemy;
};

// Ordre de garder la zone
_grpEnemies setBehaviour "AWARE";
_grpEnemies setCombatMode "RED";
private _wp = _grpEnemies addWaypoint [_spawnPos, 0];
_wp setWaypointType "GUARD";

// 6. Boucle de gestion (Thread séparé)
[_survivors, _heli, _markerAccident, _smoke, _enemies, _grpEnemies] spawn {
    params ["_survivors", "_heli", "_markerAccident", "_smoke", "_enemies", "_grpEnemies"];
    
    // Attente joueurs proches (< 200m) pour démarrer le saignement simulé
    waitUntil {
        sleep 5;
        (allPlayers findIf { _x distance _heli < 200 }) > -1
    };
    
    // Notification Globale
    (localize "STR_TASK_6_BLEEDOUT_START") remoteExec ["hint", 0]; 
    
    // Boucle de surveillance
    private _missionEnded = false;
    private _bleedoutTimer = 0;
    private _maxTime = 600; // 10 minutes avant qu'ils ne meurent tous un par un
    private _survivorsSaved = []; // Liste des survivants sauvés avec succès (plus de 2 minutes)

    while {!_missionEnded} do {
        sleep 5;
        _bleedoutTimer = _bleedoutTimer + 5;
        
        // Gestion du saignement (mort au bout de 10 min si non soigné)
        if (_bleedoutTimer >= _maxTime) then {
            {
                if (!(_x getVariable ["task_6_is_stabilized", false])) then {
                    _x setDamage 1;
                };
            } forEach _survivors;
        };
        
        // Analyse de l'état des survivants
        private _aliveSurvivors = _survivors select { alive _x };
        private _stabilizedSurvivors = _aliveSurvivors select { _x getVariable ["task_6_is_stabilized", false] };
        
        // Vérification des conditions de SUCCÈS pour chaque survivant stabilisé
        {
            private _stabilizedTime = _x getVariable ["task_6_stabilized_time", -1];
            
            // Si stabilisé, en vie, et temps > 2 minutes (120 secondes)
            if (_stabilizedTime != -1 && { (serverTime - _stabilizedTime) >= 120 } && { !(_x in _survivorsSaved) }) then {
                _survivorsSaved pushBack _x;
            };
        } forEach _stabilizedSurvivors;

        // Mise à jour des marqueurs (supprimer si mort ou sauvé confirmé)
        {
            private _mkr = _x getVariable ["task_6_my_marker", ""];
            // On supprime le marqueur si mort ou si sauvé (stabilisé) pour ne pas encombrer la carte
            private _isStabilized = _x getVariable ["task_6_is_stabilized", false];
            
            if ((!alive _x || _isStabilized) && _mkr != "") then {
                deleteMarker _mkr;
                _x setVariable ["task_6_my_marker", ""];
            };
        } forEach _survivors;
        
        // --- CONDITION D'ÉCHEC : TOUS MORTS ---
        if (count _aliveSurvivors == 0) exitWith {
            _missionEnded = true;
             
             // Appel de la fonction d'échec
             [] spawn MISSION_fnc_task_x_failure;
        };
        
        // --- CONDITION DE SUCCÈS : AU MOINS 1 SURVIVANT SAUVÉ APRÈS 2 MINUTES ---
        // Si au moins un survivant a tenu 2 minutes
        if (count _survivorsSaved > 0) exitWith {
            _missionEnded = true;

            // Appel de la fonction de succès
            [] spawn MISSION_fnc_task_x_finish;
        };
    };
};
