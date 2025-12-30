/*
    Fonction: MISSION_fnc_task_2_launch
    Description: Tâche d'assassinat d'un officier et récupération de documents.
    Étapes :
    1. Spawn d'un officier et de gardes.
    2. À la mort de l'officier, un document apparaît sous son corps.
    3. Le joueur doit ramasser ce document pour valider la tâche.
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

// Masquer le document initialement (il n'apparaît qu'à la mort de l'officier)
_document hideObjectGlobal true;
_document enableSimulationGlobal false;

// 2. Sélection du point de spawn
private _spawnMarkers = [
    "task_2_spawn_01", "task_2_spawn_02", "task_2_spawn_03", 
    "task_2_spawn_04", "task_2_spawn_05", "task_2_spawn_06"
];

private _selectedMarker = selectRandom _spawnMarkers;
private _spawnObj = missionNamespace getVariable [_selectedMarker, objNull];
private _spawnPos = if (!isNull _spawnObj) then { getPosATL _spawnObj } else { [0,0,0] };
_spawnPos set [2, 0]; // Force z = 0 (au sol)

if (_spawnPos isEqualTo [0,0,0]) exitWith { systemChat "ERROR: Task 2 Spawn Point not found."; };

// 3. Spawn de l'Officier (VIP)
private _officerTemplate = selectRandom MISSION_var_officers;
_officerTemplate params ["_oVar", "_oType", "", "", "_oSide", "_oLoadout"];

private _grpEnemies = createGroup [east, true];
_grpEnemies setBehaviour "AWARE";
_grpEnemies setCombatMode "RED";

private _officer = _grpEnemies createUnit [_oType, _spawnPos, [], 5, "NONE"];
_officer setUnitLoadout _oLoadout;
_officer setRank "COLONEL";
_officer setSkill 0.8;
_officer disableAI "PATH"; // L'officier reste plus ou moins statique

// 4. Spawn des Gardes du corps (5 soldats)
private _guards = [];
for "_i" from 1 to 5 do {
    private _eTemplate = selectRandom MISSION_var_enemies;
    _eTemplate params ["_eVar", "_eType", "", "", "_eSide", "_eLoadout"];
    
    private _guard = _grpEnemies createUnit [_eType, _spawnPos, [], 5, "NONE"];
    _guard setUnitLoadout _eLoadout;
    _guards pushBack _guard;
};

// 5. Positionnement et Comportement initial
{
    private _relPos = _officer getPos [2 + random 5, random 360];
    _x setPos _relPos;
    _x setUnitPos "AUTO";
} forEach _guards;

// Boucle de repositionnement dynamique (IA rudimentaire pour patrouiller autour de l'officier)
[_grpEnemies, _officer, _guards] spawn {
    params ["_grp", "_officer", "_guards"];
    
    while {alive _officer} do {
        sleep 45; // Changement de position toutes les 45 secondes
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

// 6. Création de la tâche Arma 3
private _taskID = "task_2_assassination";
[
    true,
    [_taskID],
    [
        localize "STR_TASK_2_DESC",
        localize "STR_TASK_2_TITLE",
        ""
    ],
    getPosWorld _officer, // Marqueur sur l'officier
    "CREATED",
    1,
    true,
    "kill" // Icône "tuer"
] call BIS_fnc_taskCreate;

// 7. Surveillance des conditions - Récupération du document
MISSION_var_task2_completed = false; // Variable synchronisée réseau si nécessaire (ici publicVariable utilisée plus bas mais localement au thread)
publicVariable "MISSION_var_task2_completed";

[_taskID, _officer, _document] spawn {
    params ["_taskID", "_officer", "_document"];
    
    private _markerCreated = false;
    private _documentRevealed = false;
    
    while {true} do {
        sleep 1;
        
        // Mort de l'officier - Révéler le document près du corps
        if (!alive _officer && !_documentRevealed) then {
            _documentRevealed = true;
            
            private _bodyPos = getPosATL _officer;
            _bodyPos set [2, 0];
            
            // Déplacer le document sur le corps et le rendre visible
            _document setPosATL _bodyPos;
            _document hideObjectGlobal false;
            _document enableSimulationGlobal true;
            
            // Créer un marqueur map sur le document
            private _mkrName = createMarker ["mkr_task_2_doc", _bodyPos];
            _mkrName setMarkerType "mil_objective";
            _mkrName setMarkerColor "ColorWhite";
            _mkrName setMarkerText (localize "STR_MARKER_DOCUMENT");
            _markerCreated = true;
            
            // Mettre à jour la cible de la tâche sur le document
            [_taskID, _bodyPos] call BIS_fnc_taskSetDestination;
            
            // Ajouter l'action de ramassage au document (exécuté sur tous les clients)
            [[_document], {
                params ["_doc"];
                _doc addAction [
                    localize "STR_MARKER_DOCUMENT", // Texte de l'action
                    {
                        params ["_target", "_caller", "_actionId"];
                        // Validation de la tâche
                        MISSION_var_task2_completed = true;
                        publicVariable "MISSION_var_task2_completed"; // Synchro réseau
                        // Suppression visuelle du document
                        _target hideObjectGlobal true;
                        _target enableSimulationGlobal false;
                        hint (localize "STR_MARKER_DOCUMENT" + " - OK");
                    },
                    nil,
                    6,
                    true,
                    true,
                    "",
                    "_this distance _target < 3" // Condition de distance
                ];
            }] remoteExec ["call", 0, true];
        };
        
        // Succès de la tâche - Document ramassé
        if (MISSION_var_task2_completed) exitWith {
            [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
            if (_markerCreated) then { deleteMarker "mkr_task_2_doc"; };
        };
    };
};

