/*
    Fonction: MISSION_fnc_task_2_launch
    Description: Tâche d'assassinat - Récupération de documents classifiés.
    
    Objectif :
    - 3 officiers ennemis sont identifiés comme cibles potentielles
    - Un seul d'entre eux possède les documents classés secret défense
    - Aucune indication sur lequel détient les documents
    - Neutraliser les officiers et récupérer les documents sur le corps
    
    Étapes :
    1. Spawn de 3 officiers avec leurs gardes à 3 lieux différents
    2. Marqueurs sur la carte pour les 3 cibles potentielles
    3. À la mort de l'officier porteur, un document apparaît
    4. Le joueur doit ramasser ce document pour valider la tâche
*/

if (!isServer) exitWith {};

// Attend l'initialisation des listes d'ennemis et d'officiers
waitUntil { !isNil "MISSION_var_enemies" && !isNil "MISSION_var_officers" };
if (count MISSION_var_enemies == 0 || count MISSION_var_officers == 0) exitWith {
    // systemChat "ERROR: No memory enemies/officers found for Task 2.";
};

// 1. Récupération de l'objet "Document physique" placé dans l'éditeur
private _document = missionNamespace getVariable ["task_2_document", objNull];
if (isNull _document) exitWith {
    // systemChat "ERROR: task_2_document not found in editor.";
};

// Masquer le document initialement (il n'apparaît qu'à la mort du bon officier)
_document hideObjectGlobal true;
_document enableSimulationGlobal false;

// 2. Liste des points de spawn possibles
private _spawnMarkers = [
    "task_2_spawn_01", "task_2_spawn_02", "task_2_spawn_03", 
    "task_2_spawn_04", "task_2_spawn_05", "task_2_spawn_06",
    "task_2_spawn_07", "task_2_spawn_08", "task_2_spawn_09",
    "task_2_spawn_10", "task_2_spawn_11", "task_2_spawn_12",
    "task_2_spawn_13", "task_2_spawn_14", "task_2_spawn_15",
    "task_2_spawn_16", "task_2_spawn_17", "task_2_spawn_18",
    "task_2_spawn_19", "task_2_spawn_20", "task_2_spawn_21",
    "task_2_spawn_22", "task_2_spawn_23", "task_2_spawn_24",
    "task_2_spawn_25", "task_2_spawn_26", "task_2_spawn_27",
    "task_2_spawn_28", "task_2_spawn_29", "task_2_spawn_30"
];

// Mélanger et sélectionner 3 points de spawn différents
_spawnMarkers = _spawnMarkers call BIS_fnc_arrayShuffle;
private _selectedSpawns = [];
{
    private _spawnObj = missionNamespace getVariable [_x, objNull];
    if (!isNull _spawnObj && count _selectedSpawns < 3) then {
        _selectedSpawns pushBack _x;
    };
} forEach _spawnMarkers;

if (count _selectedSpawns < 3) exitWith { 
    systemChat "ERROR: Not enough valid spawn points for Task 2 (need 3)."; 
};

// 3. Déterminer aléatoirement quel officier aura les documents (0, 1 ou 2)
private _documentHolderIndex = floor random 3;

// Variables globales pour le suivi
MISSION_var_task2_officers = [];
MISSION_var_task2_groups = [];
MISSION_var_task2_markers = [];
MISSION_var_task2_documentHolder = objNull;
MISSION_var_task2_completed = false;
publicVariable "MISSION_var_task2_completed";

// 4. Spawn des 3 officiers avec leurs gardes
for "_i" from 0 to 2 do {
    private _markerName = _selectedSpawns select _i;
    private _spawnObj = missionNamespace getVariable [_markerName, objNull];
    private _spawnPos = getPosATL _spawnObj;
    _spawnPos set [2, 0];
    
    // Créer le groupe ennemi
    private _grpEnemies = createGroup [east, true];
    _grpEnemies setBehaviour "AWARE";
    _grpEnemies setCombatMode "RED";
    MISSION_var_task2_groups pushBack _grpEnemies;
    
    // Spawn de l'officier
    private _officerTemplate = selectRandom MISSION_var_officers;
    _officerTemplate params ["_oVar", "_oType", "", "", "_oSide", "_oLoadout"];
    
    private _officer = _grpEnemies createUnit [_oType, _spawnPos, [], 3, "NONE"];
    _officer setUnitLoadout _oLoadout;
    _officer setRank "COLONEL";
    _officer setSkill 0.8;
    _officer disableAI "PATH";
    
    MISSION_var_task2_officers pushBack _officer;
    
    // Marquer l'officier qui possède les documents
    if (_i == _documentHolderIndex) then {
        MISSION_var_task2_documentHolder = _officer;
        _officer setVariable ["hasDocuments", true, true];
    } else {
        _officer setVariable ["hasDocuments", false, true];
    };
    
    // Spawn des gardes (3 gardes par officier)
    private _guards = [];
    for "_g" from 1 to 3 do {
        private _eTemplate = selectRandom MISSION_var_enemies;
        _eTemplate params ["_eVar", "_eType", "", "", "_eSide", "_eLoadout"];
        
        private _guard = _grpEnemies createUnit [_eType, _spawnPos, [], 5, "NONE"];
        _guard setUnitLoadout _eLoadout;
        _guards pushBack _guard;
    };
    
    // Positionnement des gardes autour de l'officier
    {
        private _relPos = _officer getPos [2 + random 5, random 360];
        _x setPos _relPos;
        _x setUnitPos "AUTO";
    } forEach _guards;
    
    // Créer un marqueur sur la carte pour cette cible
    private _mkrName = format ["mkr_task2_target_%1", _i];
    createMarker [_mkrName, _spawnPos];
    _mkrName setMarkerType "mil_destroy";
    _mkrName setMarkerColor "ColorRed";
    _mkrName setMarkerText format ["%1 %2", localize "STR_MARKER_TARGET", _i + 1];
    MISSION_var_task2_markers pushBack _mkrName;
    
    // Thread de patrouille des gardes
    [_grpEnemies, _officer, _guards] spawn {
        params ["_grp", "_officer", "_guards"];
        
        while {alive _officer} do {
            sleep 45;
            if (!alive _officer) exitWith {};
            {
                if (alive _x) then {
                    private _newPos = _officer getPos [2 + random 5, random 360];
                    _x doMove _newPos;
                    _x setUnitPos "AUTO";
                };
            } forEach _guards;
        };
    };
};

// 5. Création de la tâche Arma 3
private _taskID = "task_2_assassination";
[
    true,
    [_taskID],
    [
        localize "STR_TASK_2_DESC",
        localize "STR_TASK_2_TITLE",
        ""
    ],
    objNull, // Pas de destination unique - 3 cibles sur la carte
    "CREATED",
    1,
    true,
    "kill"
] call BIS_fnc_taskCreate;

// 6. Surveillance des conditions - Récupération du document
[_taskID, _document] spawn {
    params ["_taskID", "_document"];
    
    private _documentRevealed = false;
    private _documentMarkerCreated = false;
    
    while {true} do {
        sleep 1;
        
        // Vérifier si le détenteur des documents est mort
        if (!isNull MISSION_var_task2_documentHolder && !alive MISSION_var_task2_documentHolder && !_documentRevealed) then {
            _documentRevealed = true;
            
            private _bodyPos = getPosATL MISSION_var_task2_documentHolder;
            _bodyPos set [2, 0];
            
            // Déplacer le document sur le corps et le rendre visible
            _document setPosATL _bodyPos;
            _document hideObjectGlobal false;
            _document enableSimulationGlobal true;
            
            // Créer un marqueur sur le document
            private _mkrName = createMarker ["mkr_task_2_doc", _bodyPos];
            _mkrName setMarkerType "mil_objective";
            _mkrName setMarkerColor "ColorWhite";
            _mkrName setMarkerText (localize "STR_MARKER_DOCUMENT");
            _documentMarkerCreated = true;
            
            // Mettre à jour la destination de la tâche
            [_taskID, _bodyPos] call BIS_fnc_taskSetDestination;
            
            // Ajouter l'action de ramassage au document
            [[_document], {
                params ["_doc"];
                _doc addAction [
                    localize "STR_MARKER_DOCUMENT",
                    {
                        params ["_target", "_caller", "_actionId"];
                        MISSION_var_task2_completed = true;
                        publicVariable "MISSION_var_task2_completed";
                        _target hideObjectGlobal true;
                        _target enableSimulationGlobal false;
                        hint (localize "STR_MARKER_DOCUMENT" + " - OK");
                    },
                    nil,
                    6,
                    true,
                    true,
                    "",
                    "_this distance _target < 3"
                ];
            }] remoteExec ["call", 0, true];
        };
        
        // Succès de la tâche - Document ramassé
        if (MISSION_var_task2_completed) exitWith {
            [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
            [] spawn MISSION_fnc_task_x_finish;
            
            // Nettoyage des marqueurs
            if (_documentMarkerCreated) then { deleteMarker "mkr_task_2_doc"; };
            { deleteMarker _x; } forEach MISSION_var_task2_markers;
        };
    };
};
