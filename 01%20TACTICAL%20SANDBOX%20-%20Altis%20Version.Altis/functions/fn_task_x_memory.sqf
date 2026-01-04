/*
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
if (isNil "MISSION_var_cargaisons") then { MISSION_var_cargaisons = []; };
if (isNil "MISSION_var_planes") then { MISSION_var_planes = []; };
if (isNil "MISSION_var_airtargets") then { MISSION_var_airtargets = []; };
if (isNil "MISSION_var_civilians") then { MISSION_var_civilians = []; };
if (isNil "MISSION_var_helicopters") then { MISSION_var_helicopters = []; };
if (isNil "MISSION_var_explosives") then { MISSION_var_explosives = []; };
if (isNil "MISSION_var_model_player") then { MISSION_var_model_player = []; };
if (isNil "MISSION_var_fugitives") then { MISSION_var_fugitives = []; };
if (isNil "MISSION_var_boats") then { MISSION_var_boats = []; };
if (isNil "MISSION_var_escape_trigger") then { MISSION_var_escape_trigger = []; };
if (isNil "MISSION_var_documents") then { MISSION_var_documents = []; };

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

    // ---- Sauvegarde des Cargaisons (Tâche 3) ----
    private _cargaisonNames = ["task_x_cargaison_1"];
    {
        private _cargaison = missionNamespace getVariable [_x, objNull];
        if (!isNull _cargaison) then {
            MISSION_var_cargaisons pushBack [_x, typeOf _cargaison, getPosWorld _cargaison, getDir _cargaison, east, []];
            deleteVehicle _cargaison;
        };
    } forEach _cargaisonNames;

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

    // ---- Sauvegarde des Civils (pour Tâche 4) ----
    private _civilNames = ["task_x_civil_01", "task_x_civil_02", "task_x_civil_03", "task_x_civil_04", "task_x_civil_05", "task_x_civil_06", "task_x_civil_07", "task_x_civil_08"];
    {
        private _civil = missionNamespace getVariable [_x, objNull];
        if (!isNull _civil) then {
            // [NomVariable, ClassName, Position, Direction, Camp, Loadout]
            MISSION_var_civilians pushBack [_x, typeOf _civil, getPosWorld _civil, getDir _civil, civilian, getUnitLoadout _civil];
            deleteVehicle _civil;
        };
    } forEach _civilNames;

    // ---- Sauvegarde des Hélicoptères (pour Tâche 4) ----
    private _heliNames = ["task_x_helicoptere"];
    {
        private _heli = missionNamespace getVariable [_x, objNull];
        if (!isNull _heli) then {
            MISSION_var_helicopters pushBack [_x, typeOf _heli, getPosWorld _heli, getDir _heli, east, []];
            deleteVehicle _heli;
        };
    } forEach _heliNames;

    // ---- Sauvegarde des Explosifs (pour Tâche 5) ----
    // task_x_explosif_00 est une charge explosive
    // task_x_explosif_01 est une caisse d'explosif
    // task_x_explosif_02 et task_x_explosif_03 sont des éclairages portatifs pour héliport (simule le signal visuel de la bombe)
    private _explosiveNames = ["task_x_explosif_00", "task_x_explosif_01", "task_x_explosif_02", "task_x_explosif_03"];
    {
        private _obj = missionNamespace getVariable [_x, objNull];
        if (!isNull _obj) then {
            MISSION_var_explosives pushBack [_x, typeOf _obj, getPosWorld _obj, getDir _obj, side group _obj, []];
            deleteVehicle _obj;
        };
    } forEach _explosiveNames;

    // ---- Sauvegarde du Modèle Joueur (pour l'intro) ----
    private _modelPlayerName = "model_player";
    private _modelP = missionNamespace getVariable [_modelPlayerName, objNull];
    if (!isNull _modelP) then {
        MISSION_var_model_player pushBack [_modelPlayerName, typeOf _modelP, getPosWorld _modelP, getDir _modelP, side group _modelP, getUnitLoadout _modelP];
        deleteVehicle _modelP;
    };

    // ---- Sauvegarde des Fugitifs (pour Tâche 1 - Chasse à l'homme) ----
    private _fugitiveNames = ["task_x_fugitif_1", "task_x_fugitif_2", "task_x_fugitif_3"];
    {
        private _unit = missionNamespace getVariable [_x, objNull];
        if (!isNull _unit) then {
            MISSION_var_fugitives pushBack [_x, typeOf _unit, getPosWorld _unit, getDir _unit, side group _unit, getUnitLoadout _unit];
            deleteVehicle _unit;
        };
    } forEach _fugitiveNames;

    // ---- Sauvegarde des Bateaux (pour Tâche 1 - Chasse à l'homme) ----
    private _boatNames = ["task_x_boat_1", "task_x_boat_2", "task_x_boat_3", "task_x_boat_4", "task_x_boat_5", "task_x_boat_6", "task_x_boat_7"];
    {
        private _boat = missionNamespace getVariable [_x, objNull];
        if (!isNull _boat) then {
            MISSION_var_boats pushBack [_x, typeOf _boat, getPosWorld _boat, getDir _boat, civilian, []];
            deleteVehicle _boat;
        };
    } forEach _boatNames;

    // ---- Sauvegarde du Trigger d'Échappement (pour Tâche 1) ----
    // Position exacte : [1877.508, 19870.643, 130.173], Rotation : 84.76
    private _escapeTrigger = missionNamespace getVariable ["task_1_boat_direction_trigger", objNull];
    if (!isNull _escapeTrigger) then {
        MISSION_var_escape_trigger = [getPosWorld _escapeTrigger, getDir _escapeTrigger, triggerArea _escapeTrigger];
        deleteVehicle _escapeTrigger;
    };

    // ---- Sauvegarde des Documents (pour Tâche 2) ----
    private _docName = "task_2_document";
    private _docObj = missionNamespace getVariable [_docName, objNull];
    if (!isNull _docObj) then {
        MISSION_var_documents pushBack [_docName, typeOf _docObj, getPosWorld _docObj, getDir _docObj, side group _docObj, []];
        deleteVehicle _docObj;
    };

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
