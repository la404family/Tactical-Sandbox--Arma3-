/*
    Fonction: MISSION_fnc_task_4_launch
    Description: Lance la Tâche 4 - Exfiltration d'otages.
    - 3 Zones de recherche (choisies parmi 01-12).
    - 1 Otage caché dans l'une de ces 3 zones.
    - 8 Ennemis patrouillant dans CHAQUE zone (Total 24).
    - Phase 1: Localisation et Libération.
    - Phase 2: Suivre joueur + Extraction Hélico (13-18).
    - Phase 3: Départ et validation.
      - Hélicoptère verrouillé pour les joueurs.
*/

if (!isServer) exitWith {};

// Variables globales pour stocker les entités de cette tâche
MISSION_var_task4_hostages = [];
MISSION_var_task4_guards = [];
MISSION_var_task4_heli = objNull;
MISSION_var_task4_crew = [];

// 1. Définition des Spawns
// Spawns Otages/Gardes: 01 à 12
private _unitSpawns = [];
for "_i" from 1 to 12 do {
    private _markerName = format ["task_4_spawn_0%1", _i];
    private _spawnObj = missionNamespace getVariable [_markerName, objNull];
    if (!isNull _spawnObj) then {
        _unitSpawns pushBack _spawnObj;
    };
};

// Spawns LZ Hélico: 13 à 18
private _lzSpawns = [];
for "_i" from 13 to 18 do {
    private _numStr = if (_i < 10) then { format ["0%1", _i] } else { str _i };
    private _markerName = format ["task_4_spawn_%1", _numStr];
    private _spawnObj = missionNamespace getVariable [_markerName, objNull];
    if (!isNull _spawnObj) then {
        _lzSpawns pushBack _spawnObj;
    };
};

if (count _unitSpawns < 3) exitWith { systemChat "Erreur: Pas assez de points d'apparition pour la Tâche 4 (Unités)"; };
if (count _lzSpawns == 0) exitWith { systemChat "Erreur: Pas assez de points d'apparition pour la Tâche 4 (LZ)"; };

// Mélange pour l'aléatoire
_unitSpawns = _unitSpawns call BIS_fnc_arrayShuffle;

// Sélection des 3 Zones de Recherche
private _searchZones = _unitSpawns select [0, 3];

// Sélection de la zone de l'otage (parmi les 3)
private _hostageZone = selectRandom _searchZones;

// 2. Création de la Tâche Arma 3
[
    true,
    "task_4",
    [
        localize "STR_TASK_4_DESC",
        localize "STR_TASK_4_TITLE",
        ""
    ],
    objNull,
    "CREATED",
    1,
    true,
    "SEARCH",
    true
] call BIS_fnc_taskCreate;

// 3. Spawn de l'Otage (Unique)
if (isNil "MISSION_var_civilians") then { MISSION_var_civilians = []; };

private _posHostage = getPos _hostageZone;

// Type civil par défaut
private _civType = "C_man_polo_1_F";
private _civLoadout = [];

if (count MISSION_var_civilians > 0) then {
    private _data = selectRandom MISSION_var_civilians;
    _civType = _data select 1;
    _civLoadout = _data select 5;
};

private _grpCiv = createGroup [civilian, true];
private _hostage = _grpCiv createUnit [_civType, _posHostage, [], 0, "NONE"];

if (count _civLoadout > 0) then { _hostage setUnitLoadout _civLoadout; };

// Configuration OTAGE
_hostage setCaptive true;
removeAllWeapons _hostage;
removeBackpack _hostage;

_hostage disableAI "ANIM";
_hostage disableAI "MOVE";
_hostage disableAI "AUTOTARGET";
_hostage disableAI "TARGET";

_hostage switchMove "Acts_ExecutionVictim_Loop";

// Compétences & Moral
_hostage setSkill ["aimingAccuracy", 0.90];
_hostage setSkill ["courage", 1.0];
_hostage allowFleeing 0; // Pas de fuite

// Action Libération
[_hostage, 
    localize "STR_ACTION_FREE_HOSTAGE", 
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa", 
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa", 
    "alive _target && _target distance _this < 2 && _target getVariable ['isCaptive', true]", 
    "true", 
    { params ["_target", "_caller", "_actionId", "_arguments"]; }, 
    { params ["_target", "_caller", "_actionId", "_arguments"]; }, 
    { 
        params ["_target", "_caller", "_actionId", "_arguments"];
        
        [_target] spawn {
            params ["_captive"];
            
            _captive setVariable ["isCaptive", false, true];
            removeAllActions _captive;
            
            [_captive, "Acts_ExecutionVictim_Unbow"] remoteExec ["switchMove", 0];
            sleep 8.5; 
            
            _captive setCaptive false;
            { [_captive, _x] remoteExec ["enableAI", 0]; } forEach ["ANIM", "MOVE", "AUTOTARGET", "TARGET"];
            
            // --- Logique Suivre le joueur le plus proche ---
            _captive setBehaviour "SAFE";
            _captive setUnitPos "AUTO";
            
            // Boucle de suivi
            while { ["task_4"] call BIS_fnc_taskExists && alive _captive && !(_captive getVariable ["inHeli", false]) } do {
                
                // Trouver le joueur le plus proche
                private _nearestPlayer = objNull;
                private _minDist = 99999;
                
                {
                    if (alive _x) then {
                        private _d = _captive distance _x;
                        if (_d < _minDist) then {
                            _minDist = _d;
                            _nearestPlayer = _x;
                        };
                    };
                } forEach allPlayers;
                
                if (!isNull _nearestPlayer) then {
                    _captive doMove (getPos _nearestPlayer);
                };
                
                sleep 5;
            };
        };
    }, 
    { params ["_target", "_caller", "_actionId", "_arguments"]; }, 
    [], 1.5, 0, false, false
] call BIS_fnc_holdActionAdd;

_hostage setVariable ["isCaptive", true, true];
MISSION_var_task4_hostages pushBack _hostage;

// 4. Spawn Gardes (8 par zone, sur les 3 zones)
if (isNil "MISSION_var_enemies") then { MISSION_var_enemies = []; };

{
    private _zoneObj = _x;
    private _posZone = getPos _zoneObj;
    
    // Marqueur Zone de Recherche
    private _markerName = format ["m_hostage_area_%1", _forEachIndex];
    createMarker [_markerName, _posZone getPos [random 50, random 360]];
    _markerName setMarkerType "hd_unknown";
    _markerName setMarkerColor "ColorOrange";
    _markerName setMarkerText (localize "STR_MARKER_SEARCH_ZONE");

    // Création des 8 ennemis
    for "_k" from 1 to 8 do {
        private _grp = createGroup [east, true];
        private _infType = "O_Soldier_F";
        if (count MISSION_var_enemies > 0) then { _infType = (selectRandom MISSION_var_enemies) select 1; };
        
        private _spawnPosUnit = _posZone getPos [random 30, random 360];
        
        private _unit = _grp createUnit [_infType, _spawnPosUnit, [], 0, "NONE"];
        if (count MISSION_var_enemies > 0) then {
            _unit setUnitLoadout ((selectRandom MISSION_var_enemies) select 5);
        };
        MISSION_var_task4_guards pushBack _unit;
        
        // Logique de patrouille simple autour du centre de la zone
        [_unit, _posZone] spawn {
            params ["_u", "_center"];
            _u setBehaviour "SAFE";
            _u setSpeedMode "LIMITED";
            while {alive _u} do {
                private _movePos = _center getPos [10 + random 40, random 360];
                _u doMove _movePos;
                sleep (30 + random 30);
            };
        };
        
        sleep 0.2;
    };
    
} forEach _searchZones;

// 6. Gestionnaire de Mission (Extraction)
[_lzSpawns] spawn {
    params ["_lzSpawns"];
    
    // Attente Libération Otage
    waitUntil {
        sleep 2;
        private _hostage = MISSION_var_task4_hostages select 0; // Unique otage
        (alive _hostage) && !(_hostage getVariable ["isCaptive", true])
    };
    
    ["task_4", "ASSIGNED"] call BIS_fnc_taskSetState;
    hint (localize "STR_HINT_EXTRACTION_INCOMING");
    
    sleep 5;
    
    // --- Spawn Hélico d'Extraction ---
    if (isNil "MISSION_var_helicopters") then { MISSION_var_helicopters = []; };
    
    private _heliData = [];
    {
        if ((_x select 0) == "task_x_helicoptere") exitWith { _heliData = _x; };
    } forEach MISSION_var_helicopters;
    
    private _heliClass = "O_Heli_Light_02_unarmed_F"; 
    if (count _heliData > 0) then { _heliClass = _heliData select 1; };
    
    private _spawnPos = (getPos (MISSION_var_task4_hostages select 0)) vectorAdd [-2000, -2000, 300];
    private _grpHeli = createGroup [west, true]; 
    
    MISSION_var_task4_heli = createVehicle [_heliClass, _spawnPos, [], 0, "FLY"];
    
    // VERROUILLAGE HELICO
    MISSION_var_task4_heli lock 2; // Locked for player
    
    for "_i" from 1 to 6 do {
        private _unit = _grpHeli createUnit ["B_Helipilot_F", _spawnPos, [], 0, "NONE"];
        _unit moveInAny MISSION_var_task4_heli;
        MISSION_var_task4_crew pushBack _unit;
        if (count allPlayers > 0) then {
            private _randomPlayer = selectRandom allPlayers;
            _unit setUnitLoadout (getUnitLoadout _randomPlayer);
        };
    };
    
    // Trouver LZ la plus proche de l'otage
    private _hostage = MISSION_var_task4_hostages select 0;
    private _closestLZ = objNull;
    private _minDist = 99999;
    
    {
        private _d = _hostage distance (getPos _x);
        if (_d < _minDist) then {
            _minDist = _d;
            _closestLZ = _x;
        };
    } forEach _lzSpawns;
    
    private _lzPos = getPos _closestLZ;
    private _helipad = createVehicle ["Land_HelipadEmpty_F", _lzPos, [], 0, "CAN_COLLIDE"];
    
    _grpHeli setBehaviour "CARELESS"; 
    _grpHeli move _lzPos;
    MISSION_var_task4_heli doMove _lzPos;
    MISSION_var_task4_heli flyInHeight 50;
    
    private _lzMarker = createMarker ["m_task4_lz", _lzPos];
    _lzMarker setMarkerType "hd_pickup";
    _lzMarker setMarkerColor "ColorGreen";
    _lzMarker setMarkerText (localize "STR_MARKER_EXTRACTION");
    
    waitUntil {
        sleep 1;
        (unitReady MISSION_var_task4_heli || (MISSION_var_task4_heli distance2D _lzPos < 150))
    };
    
    MISSION_var_task4_heli land "LAND"; 
    
    // Sécurité Atterrissage
    waitUntil {
        sleep 0.5;
        (getPos MISSION_var_task4_heli select 2) < 5
    };
    
    private _hostageInside = vehicle _hostage == MISSION_var_task4_heli;
    
    if (!_hostageInside) then {
        MISSION_var_task4_heli engineOn false;
        MISSION_var_task4_heli setFuel 0;
    };
    
    private _groundCheckTime = time + 60; 
    waitUntil { 
        sleep 1; 
        isTouchingGround MISSION_var_task4_heli || time > _groundCheckTime
    };
    
    if (!isTouchingGround MISSION_var_task4_heli) then {
        MISSION_var_task4_heli setVelocity [0,0,-5];
    };
    
    // Attente embarquement otage
    waitUntil {
        sleep 5;
        
        if (alive _hostage) then {
            if (vehicle _hostage == MISSION_var_task4_heli) then {
                // Dedans -> OK
            } else {
                // Pas dedans
                if (_hostage distance MISSION_var_task4_heli < 20) then {
                    if !(_hostage getVariable ["inHeli", false]) then {
                        _hostage setVariable ["inHeli", true, true];
                        _hostage assignAsCargo MISSION_var_task4_heli;
                        [_hostage] orderGetIn true;
                    };
                };
            };
        };
        
        // Condition sortie : Otage dedans OU Otage mort
        (vehicle _hostage == MISSION_var_task4_heli) || (!alive _hostage)
    };
    
    // Protection OTAGE MORT
    if (!alive _hostage) exitWith {
         // Sera géré par le thread d'échec global, mais on peut couper ici.
    };
    
    // Départ
    MISSION_var_task4_heli setFuel 1;
    MISSION_var_task4_heli engineOn true;

    sleep 1;
    
    hint (localize "STR_HINT_EXTRACTION_TAKEOFF");
    deleteMarker "m_task4_lz";
    deleteVehicle _helipad;
    
    MISSION_var_task4_heli land "NONE";
    
    _grpHeli setBehaviour "CARELESS"; 
    _grpHeli setCombatMode "BLUE";
    
    private _pilot = driver MISSION_var_task4_heli;
    
    MISSION_var_task4_heli doMove [0,0,1000];
    _pilot doMove [0,0,1000];
    
    MISSION_var_task4_heli flyInHeight 150;
    
    sleep 65;
    
    // Victoire si otage vivant
    if (alive _hostage) then {
        ["task_4", "SUCCEEDED"] call BIS_fnc_taskSetState;
        [] spawn MISSION_fnc_task_x_finish;
        
        deleteVehicle _hostage;
        { deleteVehicle _x } forEach MISSION_var_task4_crew;
        deleteVehicle MISSION_var_task4_heli;
    } else {
         ["task_4", "FAILED"] call BIS_fnc_taskSetState;
         [] spawn MISSION_fnc_task_x_failure;
    };
    
    for "_i" from 0 to 2 do {
        deleteMarker format ["m_hostage_area_%1", _i];
    };
};

// 7. Surveillance Conditions Echec (Global)
[] spawn {
    waitUntil {
        sleep 2;
        
        if (["task_4"] call BIS_fnc_taskCompleted) exitWith { true };
        
        private _hostage = MISSION_var_task4_hostages select 0;
        private _crewDead = { !alive _x } count MISSION_var_task4_crew; 
        private _crewWiped = (count MISSION_var_task4_crew > 0) && (_crewDead == count MISSION_var_task4_crew);
        
        if (!alive _hostage || _crewWiped) exitWith {
            if !(["task_4"] call BIS_fnc_taskCompleted) then {
                ["task_4", "FAILED"] call BIS_fnc_taskSetState;
                [] spawn MISSION_fnc_task_x_failure;
            };
            true
        };
        
        false
    };
};
