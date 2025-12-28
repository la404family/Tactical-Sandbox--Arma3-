/*
    Fonction: MISSION_fnc_task_x_enemies_memory
    Description:
    Sauvegarde ("SAVE") les unités placées dans l'éditeur (officiers, ennemis, véhicules) dans des variables globales
    pour pouvoir les utiliser plus tard comme "templates" lors des spawns de mission.
    Une fois sauvegardées, les unités d'origine sont supprimées pour nettoyer la carte.
*/

params [["_mode", ""]];

// Variables globales pour stocker les données par catégorie (templates)
if (isNil "MISSION_var_officers") then { MISSION_var_officers = []; };
if (isNil "MISSION_var_enemies") then { MISSION_var_enemies = []; };
if (isNil "MISSION_var_vehicles") then { MISSION_var_vehicles = []; };
if (isNil "MISSION_var_tanks") then { MISSION_var_tanks = []; };
if (isNil "MISSION_var_planes") then { MISSION_var_planes = []; };
if (isNil "MISSION_var_airtargets") then { MISSION_var_airtargets = []; };

if (_mode == "SAVE") exitWith {
    
    // ---- Sauvegarde des Officiers ----
    private _officerNames = ["task_x_officer_1", "task_x_officer_2", "task_x_officer_3"];
    {
        private _unit = missionNamespace getVariable [_x, objNull];
        if (!isNull _unit) then {
            // [NomVariable, ClassName, Position, Direction, Camp, Loadout]
            MISSION_var_officers pushBack [_x, typeOf _unit, getPosWorld _unit, getDir _unit, side group _unit, getUnitLoadout _unit];
            deleteVehicle _unit; // Supprime l'original
        };
    } forEach _officerNames;

    // ---- Sauvegarde des Ennemis (infanterie standard) ----
    for "_i" from 0 to 15 do {
        private _numStr = if (_i < 10) then { format ["0%1", _i] } else { str _i };
        private _varName = format ["task_x_enemy_%1", _numStr];
        private _unit = missionNamespace getVariable [_varName, objNull];
        if (!isNull _unit) then {
            MISSION_var_enemies pushBack [_varName, typeOf _unit, getPosWorld _unit, getDir _unit, side group _unit, getUnitLoadout _unit];
            deleteVehicle _unit;
        };
    };

    // ---- Sauvegarde des Véhicules (légers, transport) ----
    private _vehicleNames = ["task_x_vehicle_1", "task_x_vehicle_2"];
    {
        private _veh = missionNamespace getVariable [_x, objNull];
        if (!isNull _veh) then {
            MISSION_var_vehicles pushBack [_x, typeOf _veh, getPosWorld _veh, getDir _veh, east, []];
            deleteVehicle _veh;
        };
    } forEach _vehicleNames;

    // ---- Sauvegarde des Tanks (Tâche 3) ----
    private _tankNames = ["task_x_tank_1"];
    {
        private _tank = missionNamespace getVariable [_x, objNull];
        if (!isNull _tank) then {
            MISSION_var_tanks pushBack [_x, typeOf _tank, getPosWorld _tank, getDir _tank, east, []];
            deleteVehicle _tank;
        };
    } forEach _tankNames;

    // ---- Sauvegarde des Avions (Support Allié Tâche 3) ----
    private _planeNames = ["task_x_avion_1"];
    {
        private _plane = missionNamespace getVariable [_x, objNull];
        if (!isNull _plane) then {
            // Sauvegarde spécifique des pylônes (armement)
            private _pylons = getPylonMagazines _plane;
            MISSION_var_planes pushBack [_x, typeOf _plane, getPosWorld _plane, getDir _plane, west, _pylons];
            deleteVehicle _plane;
        };
    } forEach _planeNames;

    // ---- Sauvegarde des Cibles Aériennes (pour Tâche 3) ----
    private _airTargetNames = ["task_x_cible_avion"];
    {
        private _target = missionNamespace getVariable [_x, objNull];
        if (!isNull _target) then {
            MISSION_var_airtargets pushBack [_x, typeOf _target, getPosWorld _target, getDir _target, east, []];
            deleteVehicle _target;
        };
    } forEach _airTargetNames;

    // Debug (désactivé) - Affiche le nombre d'éléments sauvegardés
    // systemChat format ["Memory: Officers=%1, Enemies=%2, Vehicles=%3, Tanks=%4", 
    //     count MISSION_var_officers, 
    //     count MISSION_var_enemies, 
    //     count MISSION_var_vehicles, 
    //     count MISSION_var_tanks
    // ];
};

if (_mode == "SPAWN") exitWith {
    // Respawn tout (fonctionnalité future possible pour reset la mission)
    // À implémenter selon les besoins
};
