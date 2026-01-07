// ============================================================================
// TACHE 7 : DESTRUCTION DE RADAR
// ============================================================================
/*
    Objectifs :
    1. Trouver le radar parmis les 7 positions possibles.
    2. Détruire le radar.
*/

// ============================================================================
// 1. INITIALISATION
// ============================================================================

MISSION_var_task7_running = true;
MISSION_var_task7_radar = objNull;
MISSION_var_task7_enemies = [];

// Sélection d'une position aléatoire parmi 7 (1 à 7)
private _randomIndex = floor (random 7) + 1; // 1 to 7

// Debug
// systemChat format ["Task 7: Selected Index %1", _randomIndex];

// ============================================================================
// 2. SPAWN DU RADAR
// ============================================================================

// Les radars spawnent sur des héliports nommés task_7_radar_8 à task_7_radar_14
// Index 1 -> Radar 8
// Index 2 -> Radar 9
// ...
// Index 7 -> Radar 14
private _radarMarkerIndex = _randomIndex + 7;
private _radarSpawnName = format ["task_7_spawn_%1", _radarMarkerIndex];
private _radarSpawnObj = missionNamespace getVariable [_radarSpawnName, objNull];

// Fallback si l'héliport n'est pas trouvé (position zéro)
private _radarPos = if (!isNull _radarSpawnObj) then { getPos _radarSpawnObj } else { [0,0,0] };
private _radarDir = if (!isNull _radarSpawnObj) then { getDir _radarSpawnObj } else { 0 };

if (isNull _radarSpawnObj) exitWith {
    systemChat format ["ERREUR CRITIQUE TACHE 7 : Point de spawn radar '%1' introuvable !", _radarSpawnName];
    ["task_7", "FAILED"] call BIS_fnc_taskSetState;
    MISSION_var_task7_running = false;
};

// Création du bâtiment radar
// ClassName : Land_Radar_Small_F
private _radar = createVehicle ["Land_Radar_Small_F", _radarPos, [], 0, "NONE"];
_radar setDir _radarDir;
_radar setPosATL [(_radarPos select 0), (_radarPos select 1), -0.05]; // Force la position exacte avec Z = -0.05
_radar setVectorUp [0,0,1]; // De niveau (parfaitement vertical, ignore la pente)

// On le rend destructible
_radar allowDamage true;

MISSION_var_task7_radar = _radar;

if (!MISSION_var_task7_running) exitWith {};

// ============================================================================
// 3. SPAWN DES ENNEMIS (15-20 unités)
// ============================================================================

// Les ennemis spawnent sur des héliports nommés task_7_spawn_1 à task_7_spawn_7
// Note : Le nom est sans '0' devant pour 1-9 selon instructions (task_7_spawn_1)
private _enemySpawnName = format ["task_7_spawn_%1", _randomIndex];
private _spawnObj = missionNamespace getVariable [_enemySpawnName, objNull];
private _spawnPos = if (!isNull _spawnObj) then { getPos _spawnObj } else { _radarPos };

if (isNull _spawnObj) exitWith {
    systemChat format ["ERREUR CRITIQUE TACHE 7 : Point de spawn ennemis '%1' introuvable !", _enemySpawnName];
    ["task_7", "FAILED"] call BIS_fnc_taskSetState;
    MISSION_var_task7_running = false;
};

// Création du groupe ennemi
private _grp = createGroup [east, true];

// Nombre d'ennemis aléatoire entre 15 et 20
private _nbEnemies = 15 + floor(random 6);

for "_i" from 1 to _nbEnemies do {
    // Sélection d'un template ennemi aléatoire
    private _enemyTemplate = selectRandom MISSION_var_enemies;
    _enemyTemplate params ["_eName", "_eType", "_ePos", "_eDir", "_eSide", "_eLoadout"];
    
    // Position aléatoire autour du spawn (rayon 10m pour le spawn)
    private _pos = _spawnPos getPos [random 10, random 360];
    
    private _unit = _grp createUnit [_eType, _pos, [], 0, "NONE"];
    _unit setUnitLoadout _eLoadout;
    
    // Compétences
    _unit setSkill 0.5;
    _unit setSkill ["aimingAccuracy", 0.3];
    _unit setSkill ["aimingShake", 0.3];
    
    MISSION_var_task7_enemies pushBack _unit;
    sleep 0.1;
};

// ============================================================================
// 4. PATROUILLE (40m)
// ============================================================================

// Patrouille autour de leur point de spawn (_spawnPos)
[_grp, _spawnPos, 40] call BIS_fnc_taskPatrol;

// ============================================================================
// 5. CRÉATION DE LA TÂCHE
// ============================================================================

[
    true,
    ["task_7"],
    [localize "STR_TASK_7_DESC", localize "STR_TASK_7_TITLE", ""],
    _radarPos, // Position du radar
    "CREATED",
    1,
    true,
    "destroy"
] call BIS_fnc_taskCreate;

["task_7"] remoteExec ["MISSION_fnc_task_briefing", 0, true];

// ============================================================================
// 6. BOUCLE DE SURVEILLANCE
// ============================================================================

[_grp] spawn {
    params ["_grp"];
    
    while {MISSION_var_task7_running} do {
        sleep 5;
        
        // Condition de Victoire : Radar détruit
        if (!alive MISSION_var_task7_radar) exitWith {
            ["task_7", "SUCCEEDED"] call BIS_fnc_taskSetState;
            MISSION_var_task7_running = false;
            
            // Nettoyage de fin de mission
            [] spawn MISSION_fnc_task_x_finish;
        };
    };
    
    // Nettoyage après fin de mission
    if (!MISSION_var_task7_running) then {
        sleep 60; // On laisse les corps un peu
        { deleteVehicle _x } forEach MISSION_var_task7_enemies;
        if (!isNull MISSION_var_task7_radar) then { deleteVehicle MISSION_var_task7_radar; };
        MISSION_var_task7_enemies = [];
    };
};
