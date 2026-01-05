/*
    =========================================================================
    fn_task_5_launch.sqf - Tâche 5 : Présence Civile & Désamorçage
    =========================================================================
    
    LOGIQUE:
    - 50 Civils à Molos avec mouvements aléatoires (45s)
    - 2 Bombes avec timer global de 35 minutes (2100s)
    - TRAÎTRES: Activés si une bombe est découverte (<8m) ou désamorcée
    - Traîtres tirent si joueur à <50m
    - Victoire: 2 bombes désamorcées
    - Défaite: 2 civils morts OU explosion
    
    =========================================================================
*/

if (!isServer) exitWith {};

// ==========================================================================
// SECTION 0: CLEANUP (si relance de mission)
// ==========================================================================

// Fonction de nettoyage globale
MISSION_fnc_task5_cleanup = {
    // Arrêter la boucle principale
    MISSION_var_task5_running = false;
    publicVariable "MISSION_var_task5_running";
    
    // Supprimer le timer UI sur tous les clients
    {
        private _display = findDisplay 46;
        if (!isNull _display) then {
            private _ctrl = _display displayCtrl 99501;
            if (!isNull _ctrl) then { ctrlDelete _ctrl; };
        };
    } remoteExec ["call", 0, false];
    
    // Supprimer tous les objets créés
    {
        if (!isNull _x) then { deleteVehicle _x; };
    } forEach (missionNamespace getVariable ["MISSION_var_task5_objects", []]);
    
    // Supprimer le groupe traître
    private _traitorGrp = missionNamespace getVariable ["MISSION_var_task5_traitorGroup", grpNull];
    if (!isNull _traitorGrp) then { deleteGroup _traitorGrp; };
    
    // Reset variables
    MISSION_var_task5_objects = [];
    MISSION_var_task5_civilians = [];
    MISSION_var_task5_bombs = [];
    MISSION_var_task5_civCasualties = 0;
    MISSION_var_task5_explosivesDefused = 0;
    MISSION_var_task5_traitorsRecruited = false;
    MISSION_var_task5_waypoints = [];
    MISSION_var_task5_traitorGroup = grpNull;
};

// Exécuter cleanup si mission déjà active
if (!isNil "MISSION_var_task5_running" && {MISSION_var_task5_running}) then {
    call MISSION_fnc_task5_cleanup;
    sleep 0.5; // Attendre nettoyage
};

// ==========================================================================
// SECTION 1: CONFIGURATION & VARIABLES
// ==========================================================================

MISSION_var_task5_running = true;
MISSION_var_task5_startTime = time;
publicVariable "MISSION_var_task5_running";

["Tache5_Start", [localize "STR_NOTIF_TASK5_START_DESC"]] call BIS_fnc_showNotification;

MISSION_var_task5_objects = [];
MISSION_var_task5_civilians = [];
MISSION_var_task5_bombs = [];
MISSION_var_task5_civCasualties = 0;
MISSION_var_task5_explosivesDefused = 0;
MISSION_var_task5_traitorsRecruited = false;

private _bombTemplates = missionNamespace getVariable ["MISSION_var_explosives", []];

// Classes de civils disponibles
private _civClasses = [
    // Base Game
    "C_man_polo_1_F", "C_man_polo_2_F", "C_man_polo_3_F", 
    "C_man_polo_4_F", "C_man_polo_5_F", "C_man_polo_6_F",
    "C_man_1_1_F", "C_man_1_2_F", "C_man_1_3_F",
    "C_man_shorts_1_F", "C_man_shorts_2_F", "C_man_shorts_3_F", "C_man_shorts_4_F",
    "C_man_smart_casual_1_F", "C_man_smart_casual_2_F",
    "C_man_hunter_1_F", "C_man_p_fugitive_F", "C_man_p_beggar_F",
    "C_man_w_worker_F", "C_journalist_F", "C_scientist_F",
    "C_Nikos", "C_Nikos_aged", "C_Orestes",
    // Apex
    "C_Man_casual_1_F_tanoan", "C_Man_casual_2_F_tanoan", "C_Man_casual_3_F_tanoan",
    "C_Man_casual_4_F_tanoan", "C_Man_casual_5_F_tanoan", "C_Man_casual_6_F_tanoan",
    "C_Man_sport_1_F_tanoan", "C_Man_sport_2_F_tanoan", "C_Man_sport_3_F_tanoan",
    "C_Man_shorts_1_F_tanoan", "C_Man_shorts_2_F_tanoan", 
    "C_Man_shorts_3_F_tanoan", "C_Man_shorts_4_F_tanoan"
];

// ==========================================================================
// SECTION 2: WAYPOINTS DE NAVIGATION
// ==========================================================================

MISSION_var_task5_waypoints = [];

private _fnc_addWaypoints = {
    params ["_prefix", "_start", "_end"];
    for "_i" from _start to _end do {
        private _name = if (_i < 10) then { format ["%1_0%2", _prefix, _i] } else { format ["%1_%2", _prefix, _i] };
        private _obj = missionNamespace getVariable [_name, objNull];
        if (!isNull _obj) then { 
            MISSION_var_task5_waypoints pushBack (getPos _obj); 
        };
    };
};

["task_5_spawn", 1, 19] call _fnc_addWaypoints;
["task_3_spawn", 2, 12] call _fnc_addWaypoints;
["task_2_spawn", 1, 6] call _fnc_addWaypoints;
["task_1_spawn", 1, 6] call _fnc_addWaypoints;

// Centre de Molos
private _townCenter = missionNamespace getVariable ["task_5_spawn_10", objNull];
if (isNull _townCenter) exitWith { 
    systemChat "ERREUR CRITIQUE: task_5_spawn_10 introuvable!"; 
};

// ==========================================================================
// SECTION 3: SPAWN DES CIVILS (Optimisé)
// ==========================================================================

private _civGroup = createGroup [civilian, true];
private _houses = nearestTerrainObjects [getPos _townCenter, ["House"], 300];
_houses = _houses call BIS_fnc_arrayShuffle;

private _spawnedCivs = 0;
private _maxCivs = 55;

{
    if (_spawnedCivs >= _maxCivs) exitWith {};
    
    private _positions = _x buildingPos -1;
    if (count _positions > 0) then {
        private _pos = selectRandom _positions;
        private _civ = _civGroup createUnit [selectRandom _civClasses, _pos, [], 0, "NONE"];
        
        _civ setPosATL _pos;
        _civ setDir (random 360);
        removeAllWeapons _civ;
        removeAllItems _civ;
        
        // Config IA pacifique
        _civ disableAI "TARGET";
        _civ disableAI "AUTOTARGET";
        _civ disableAI "SUPPRESSION";
        _civ disableAI "WEAPONAIM";
        _civ setBehaviour "CARELESS";
        _civ setCombatMode "BLUE";
        _civ enableAI "PATH";
        _civ enableAI "MOVE";
        
        // Variables de contrôle
        _civ setVariable ["BIS_noCoreConversations", true];
        _civ setVariable ["next_move_time", time + (random 15)];
        _civ setVariable ["isTraitor", false, true];
        _civ setVariable ["traitorArmed", false, true];
        
        // Event Handler pour comptage des morts civils
        _civ addEventHandler ["Killed", {
            params ["_unit"];
            // Ne compter que si c'est encore un civil (pas un traître armé)
            if (!(_unit getVariable ["traitorArmed", false])) then {
                MISSION_var_task5_civCasualties = MISSION_var_task5_civCasualties + 1;
                // Affichage format X/2
                private _msg = format ["%1/2", MISSION_var_task5_civCasualties];
                hint format [localize "STR_NOTIF_CIVIL_KILLED", _msg];
            };
        }];
        
        MISSION_var_task5_civilians pushBack _civ;
        MISSION_var_task5_objects pushBack _civ;
        _spawnedCivs = _spawnedCivs + 1;
    };
} forEach _houses;

// ==========================================================================
// SECTION 4: SPAWN DES BOMBES
// ==========================================================================

// Groupe 1: Spawns 01-09
private _spawns1 = [];
for "_i" from 1 to 9 do {
    private _obj = missionNamespace getVariable [format ["task_5_spawn_0%1", _i], objNull];
    if (!isNull _obj) then { _spawns1 pushBack _obj; };
};

// Groupe 2: Spawns 11-19
private _spawns2 = [];
for "_i" from 11 to 19 do {
    private _obj = missionNamespace getVariable [format ["task_5_spawn_%1", _i], objNull];
    if (!isNull _obj) then { _spawns2 pushBack _obj; };
};

if (count _spawns1 == 0 || count _spawns2 == 0) exitWith {
    systemChat "ERREUR: Spawns bombes manquants!";
};

private _selectedSpawns = [selectRandom _spawns1, selectRandom _spawns2];

{
    private _pos = getPos _x;
    private _bombData = createHashMap;
    _bombData set ["discovered", false];
    _bombData set ["defused", false];
    _bombData set ["exploded", false];
    _bombData set ["position", _pos];
    
    // Caisse
    private _crateClass = "Box_Syndicate_Ammo_F";
    { if ((_x select 0) == "task_x_explosif_01") exitWith { _crateClass = _x select 1; }; } forEach _bombTemplates;
    private _crate = createVehicle [_crateClass, _pos, [], 0, "CAN_COLLIDE"];
    MISSION_var_task5_objects pushBack _crate;
    
    // Charge explosive
    private _chargeClass = "DemoCharge_F";
    { if ((_x select 0) == "task_x_explosif_00") exitWith { _chargeClass = _x select 1; }; } forEach _bombTemplates;
    private _charge = createVehicle [_chargeClass, _pos vectorAdd [0.2, 0, 0.82], [], 0, "CAN_COLLIDE"];
    _charge attachTo [_crate, [0, 0, 0.4]];
    _charge setVectorUp [0, 0, 1];
    MISSION_var_task5_objects pushBack _charge;
    
    // Lumières (task_x_explosif_02 et task_x_explosif_03 depuis la mémoire)
    private _lightClass02 = "Land_PortableLight_single_F";
    private _lightClass03 = "Land_PortableLight_single_F";
    { if ((_x select 0) == "task_x_explosif_02") exitWith { _lightClass02 = _x select 1; }; } forEach _bombTemplates;
    { if ((_x select 0) == "task_x_explosif_03") exitWith { _lightClass03 = _x select 1; }; } forEach _bombTemplates;
    
    private _lightClasses = [_lightClass02, _lightClass03];
    private _lightOffsets = [[1.5, 1.5, 0], [-1.5, -1.5, 0]];
    
    {
        private _idx = _forEachIndex;
        private _offset = _x;
        private _lightClass = _lightClasses select _idx;
        
        private _light = createVehicle [_lightClass, _pos vectorAdd _offset, [], 0, "CAN_COLLIDE"];
        MISSION_var_task5_objects pushBack _light;
        
        // Ajouter lumière rouge visible jour/nuit
        private _redLight = "#lightpoint" createVehicle (getPos _light);
        _redLight setLightBrightness 1.0;
        _redLight setLightColor [1, 0, 0];
        _redLight setLightAmbient [1, 0, 0];
        _redLight setLightDayLight true;
        _redLight lightAttachObject [_light, [0, 0, 2]];
        MISSION_var_task5_objects pushBack _redLight;
    } forEach _lightOffsets;
    
    _bombData set ["core_object", _crate];
    _bombData set ["charge_object", _charge];
    
    // Action de désamorçage
    [
        _crate, localize "STR_ACTION_DEFUSE_EXPLOSIVE",
        "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_hack_ca.paa",
        "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_hack_ca.paa",
        "_this distance _target < 3", "_caller distance _target < 3",
        {}, {},
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            _arguments params ["_bData"];
            _bData set ["defused", true];
            MISSION_var_task5_explosivesDefused = MISSION_var_task5_explosivesDefused + 1;
            hint (localize "STR_HINT_EXPLOSIVE_DEFUSED");
            deleteVehicle (_bData get "charge_object");
            [_target, _actionId] call BIS_fnc_holdActionRemove;
        },
        {}, [_bombData], 10, 10, true, false
    ] call BIS_fnc_holdActionAdd;
    
    MISSION_var_task5_bombs pushBack _bombData;
} forEach _selectedSpawns;

// ==========================================================================
// SECTION 5: CRÉATION DE LA TÂCHE
// ==========================================================================

[true, "task_5", [localize "STR_TASK_5_DESC", localize "STR_TASK_5_TITLE", ""], getPos _townCenter, "CREATED", 1, true, "search", true] call BIS_fnc_taskCreate;

["task_5"] remoteExec ["MISSION_fnc_task_briefing", 0, true];

// ==========================================================================
// SECTION 6: TIMER UI (35 à 45 minutes aléatoire)
// ==========================================================================

// Timer aléatoire entre 35 et 45 minutes (2100 à 2700 secondes)
MISSION_var_task5_timerDuration = 2100 + floor(random 600);
MISSION_var_task5_timerEndTime = time + MISSION_var_task5_timerDuration;
publicVariable "MISSION_var_task5_timerDuration";
publicVariable "MISSION_var_task5_timerEndTime";

MISSION_fnc_task5_showTimer = {
    [] spawn {
        disableSerialization;
        waitUntil { !isNull (findDisplay 46) };
        sleep 0.3;
        
        private _display = findDisplay 46;
        
        // Supprimer ancien timer
        private _oldCtrl = _display displayCtrl 99501;
        if (!isNull _oldCtrl) then { ctrlDelete _oldCtrl; };
        
        // Créer nouveau timer
        private _ctrl = _display ctrlCreate ["RscStructuredText", 99501];
        _ctrl ctrlSetPosition [
            safezoneX + safezoneW - 0.16 * safezoneW,
            safezoneY + safezoneH - 0.08 * safezoneH,
            0.15 * safezoneW,
            0.06 * safezoneH
        ];
        _ctrl ctrlSetBackgroundColor [0, 0, 0, 0.6];
        _ctrl ctrlCommit 0;
        
        // Boucle de mise à jour
        while { 
            !isNil "MISSION_var_task5_running" && 
            { MISSION_var_task5_running } && 
            { !isNull _ctrl } 
        } do {
            private _remaining = (missionNamespace getVariable ["MISSION_var_task5_timerEndTime", 0]) - time;
            if (_remaining < 0) then { _remaining = 0; };
            
            private _min = floor (_remaining / 60);
            private _sec = floor (_remaining mod 60);
            private _cs = floor ((_remaining - floor _remaining) * 100);
            
            private _minStr = if (_min < 10) then { format ["0%1", _min] } else { str _min };
            private _secStr = if (_sec < 10) then { format ["0%1", _sec] } else { str _sec };
            private _csStr = if (_cs < 10) then { format ["0%1", _cs] } else { str _cs };
            
            private _color = if (_remaining < 120) then { "#FF3333" } else { "#FFFFFF" };
            
            _ctrl ctrlSetStructuredText parseText format [
                "<t size='1.5' color='%4' font='PuristaBold' shadow='2' align='center'>%1:%2.%3</t>",
                _minStr, _secStr, _csStr, _color
            ];
            
            sleep 0.05;
        };
        
        // Cleanup
        if (!isNull _ctrl) then { ctrlDelete _ctrl; };
    };
};

publicVariable "MISSION_fnc_task5_showTimer";
[] remoteExecCall ["MISSION_fnc_task5_showTimer", 0, true];

// ==========================================================================
// SECTION 7: BOUCLE PRINCIPALE
// ==========================================================================

// Créer groupe traître (OPFOR) à l'avance
MISSION_var_task5_traitorGroup = createGroup [east, true];

[] spawn {
    private _civs = MISSION_var_task5_civilians;
    private _traitorGroup = MISSION_var_task5_traitorGroup;
    
    while { MISSION_var_task5_running } do {
        
        // === A. DÉTECTION DES JOUEURS ===
        private _players = allPlayers - entities "HeadlessClient_F";
        if (count _players == 0) then { _players = playableUnits; };
        if (count _players == 0) then { _players = switchableUnits; };
        if (count _players == 0) then { _players = [player]; };
        
        // === B. MOUVEMENT CIVILS (toutes les 45s, sauf si armé) ===
        _civs = _civs select { alive _x };
        {
            if (!(_x getVariable ["traitorArmed", false]) && time > (_x getVariable ["next_move_time", 0])) then {
                _x enableAI "ANIM";
                _x enableAI "MOVE";
                _x setUnitPos "UP";
                
                if (count MISSION_var_task5_waypoints > 0) then {
                    private _dest = selectRandom MISSION_var_task5_waypoints;
                    _x doMove (_dest vectorAdd [random 10 - 5, random 10 - 5, 0]);
                    _x setSpeedMode "LIMITED";
                    _x forceSpeed 1.5;
                };
                
                _x setVariable ["next_move_time", time + 45];
            };
        } forEach _civs;
        
        // === C. DÉTECTION BOMBES ===
        {
            private _bomb = _x;
            private _obj = _bomb get "core_object";
            
            if (!isNull _obj && !(_bomb get "discovered") && !(_bomb get "defused")) then {
                if ({ _x distance _obj < 8 } count _players > 0) then {
                    _bomb set ["discovered", true];
                };
            };
        } forEach MISSION_var_task5_bombs;
        
        // === D. ACTIVATION TRAÎTRES (si bombe découverte/désamorcée) ===
        private _bombTriggered = { (_x get "discovered") || (_x get "defused") } count MISSION_var_task5_bombs > 0;
        
        if (_bombTriggered && !MISSION_var_task5_traitorsRecruited) then {
            MISSION_var_task5_traitorsRecruited = true;
            
            private _candidates = _civs select { alive _x };
            private _recruited = 0;
            
            {
                if (_recruited >= 3) exitWith {};
                
                // Marquer comme traître (reste dans groupe civil pour l'instant)
                _x setVariable ["isTraitor", true, true];
                _recruited = _recruited + 1;
            } forEach _candidates;
        };
        
        // === E. ARMEMENT TRAÎTRES (si joueur à <15m) ===
        {
            private _civ = _x;
            
            if (alive _civ && (_civ getVariable ["isTraitor", false]) && !(_civ getVariable ["traitorArmed", false])) then {
                // Trouver joueur le plus proche
                private _nearestDist = 999999;
                private _nearestPlayer = objNull;
                
                {
                    if (alive _x) then {
                        private _d = _civ distance _x;
                        if (_d < _nearestDist) then {
                            _nearestDist = _d;
                            _nearestPlayer = _x;
                        };
                    };
                } forEach _players;
                
                // Si à moins de 15m, armer et devenir hostile
                if (_nearestDist < 15 && !isNull _nearestPlayer) then {
                    _civ setVariable ["traitorArmed", true, true];
                    
                    // Rejoindre groupe OPFOR
                    [_civ] joinSilent _traitorGroup;
                    
                    // Activer IA combat
                    _civ enableAI "TARGET";
                    _civ enableAI "AUTOTARGET";
                    _civ enableAI "WEAPONAIM";
                    _civ enableAI "SUPPRESSION";
                    _civ setBehaviour "COMBAT";
                    _civ setCombatMode "RED";
                    
                    // Donner arme
                    _civ addMagazine "16Rnd_9x21_Mag";
                    _civ addMagazine "16Rnd_9x21_Mag";
                    _civ addWeapon "hgun_P07_F";
                    _civ selectWeapon "hgun_P07_F";
                    _civ setSkill 0.5;
                    
                    // Attaquer
                    _civ doTarget _nearestPlayer;
                    _civ doFire _nearestPlayer;
                    _civ doMove (getPos _nearestPlayer);
                };
            };
        } forEach _civs;
        
        // === F. SON DES BOMBES & EXPLOSION ===
        {
            private _bomb = _x;
            private _obj = _bomb get "core_object";
            
            if (!isNull _obj && !(_bomb get "defused") && !(_bomb get "exploded")) then {
                playSound3D ["A3\Sounds_F\sfx\Beep_Target.wss", _obj, false, getPosASL _obj, 2.5, 1, 50];
                
                // Vérifier timer global
                if (time > MISSION_var_task5_timerEndTime) then {
                    _bomb set ["exploded", true];
                    "Bo_GBU12_LGB" createVehicle (getPos _obj);
                    deleteVehicle _obj;
                };
            };
        } forEach MISSION_var_task5_bombs;
        
        // === G. VICTOIRE / DÉFAITE ===
        // Défaite: 2 civils morts
        if (MISSION_var_task5_civCasualties >= 2) exitWith {
            ["task_5", "FAILED"] call BIS_fnc_taskSetState;
            ["Tache5_Fail", [localize "STR_NOTIF_FAIL_CIVILIANS"]] call BIS_fnc_showNotification;
            MISSION_var_task5_running = false;
            [] spawn MISSION_fnc_task_x_failure;
        };
        
        // Défaite: Explosion
        if ({ _x get "exploded" } count MISSION_var_task5_bombs > 0) exitWith {
            ["task_5", "FAILED"] call BIS_fnc_taskSetState;
            ["Tache5_Fail", [localize "STR_NOTIF_FAIL_BOMB"]] call BIS_fnc_showNotification;
            MISSION_var_task5_running = false;
            [] spawn MISSION_fnc_task_x_failure;
        };
        
        // Victoire: 2 bombes désamorcées
        if (MISSION_var_task5_explosivesDefused >= 2) exitWith {
            ["task_5", "SUCCEEDED"] call BIS_fnc_taskSetState;
            ["Tache5_Win", [localize "STR_NOTIF_WIN_SECURED"]] call BIS_fnc_showNotification;
            [] spawn MISSION_fnc_task_x_finish;
            MISSION_var_task5_running = false;
        };
        
        sleep 1;
    };
    
    // Cleanup final
    publicVariable "MISSION_var_task5_running";
};
