
/*
    Description :
    Cette fonction gère le système de spawn de véhicules (garage).
    Elle permet l'apparition de véhicules terrestres et aériens, et gère leur suppression.
    Modes : INIT, OPEN_UI, SPAWN, DELETE.
*/

params ["_mode", ["_params", []]];

switch (_mode) do {
    case "INIT": {
        // Condition : Interface uniquement (joueur)
        if (!hasInterface) exitWith {};
        
        // Attend que le joueur soit prêt
        waitUntil { !isNull player };
        
        // Ajoute l'action d'ouverture du garage
        player addAction [
            localize "STR_ACTION_GARAGE", 
            {
                ["OPEN_UI"] call MISSION_fnc_spawn_vehicles;
            },
            [],
            1.5, 
            true, 
            true, 
            "",
            "player inArea vehicles_request" // Visible dans la zone dédiée
        ];
    };

    case "OPEN_UI": {
        createDialog "Refour_Vehicle_Dialog";
        
        // Attend l'ouverture réelle du dialogue
        waitUntil {!isNull (findDisplay 8888)};
        
        private _display = findDisplay 8888;
        private _ctrlList = _display displayCtrl 1500;
        
        lbClear _ctrlList;

        // Récupération des véhicules
        private _sideInt = (side player) call BIS_fnc_sideID;
        private _cfgVehicles = configFile >> "CfgVehicles";
        
        // Filtre initial : portée publique et même camp
        private _units = "
            (getNumber (_x >> 'scope') >= 2) && 
            (getNumber (_x >> 'side') == _sideInt)
        " configClasses _cfgVehicles;

        private _sortableUnits = [];

        {
            private _class = _x;
            private _className = configName _class;
            
            // Logique de filtrage spécifique
            // Inclus : Voitures, Tanks, Hélicoptères
            // Exclus : Drones (UAV), Navires, Avions, Armes statiques, Hommes
            
            private _isLandOrAir = (_className isKindOf "Car") || (_className isKindOf "Tank") || (_className isKindOf "Helicopter");
            
            if (_isLandOrAir) then {
                // Vérification des exclusions
                private _isExcluded = 
                    (_className isKindOf "UAV") ||          
                    (_className isKindOf "Ship") ||         
                    (_className isKindOf "Plane") ||        
                    (_className isKindOf "StaticWeapon") || 
                    (_className isKindOf "Man");            

                if (!_isExcluded) then {
                    private _displayName = getText (_class >> "displayName");
                    private _factionClass = getText (_class >> "faction");
                    
                    private _factionDisplayName = getText (configFile >> "CfgFactionClasses" >> _factionClass >> "displayName");
                    if (_factionDisplayName == "") then { _factionDisplayName = _factionClass; }; // Fallback
        
                    private _entryText = format ["[%1] %2", _factionDisplayName, _displayName];
                    
                    _sortableUnits pushBack [_entryText, _className];
                };
            };

        } forEach _units;

        // Tri alphabétique
        _sortableUnits sort true;

        // Ajout à la listbox avec icônes si disponibles
        {
            _x params ["_text", "_data"];
            private _index = _ctrlList lbAdd _text;
            _ctrlList lbSetData [_index, _data];
            
            private _pic = getText (configFile >> "CfgVehicles" >> _data >> "picture");
            if (_pic != "") then {
                _ctrlList lbSetPicture [_index, _pic];
            };
        } forEach _sortableUnits;

        if (lbSize _ctrlList > 0) then {
            _ctrlList lbSetCurSel 0;
        };
    };

    case "SPAWN": {
        disableSerialization;
        private _display = findDisplay 8888;
        private _listBox = _display displayCtrl 1500;

        // Validation
        private _indexSelection = lbCurSel _listBox;
        if (_indexSelection == -1) exitWith {
            systemChat (localize "STR_ERR_NO_VEHICLE_SELECTED");
        };

        // Récupération des données sélectionnés
        private _classname = _listBox lbData _indexSelection;
        private _displayName = _listBox lbText _indexSelection;

        // Ferme le dialogue
        closeDialog 1;

        // Spawn dans un nouveau thread pour permettre l'attente (sleep)
        [_classname, _displayName] spawn {
            params ["_classname", "_displayName"];

            // Suppression des véhicules existants dans la zone "vehicles_request" pour éviter l'empilement
            if (!isNil "vehicles_request" && {!isNull vehicles_request}) then {
                private _existingVehicles = vehicles select {_x inArea vehicles_request};
                if (count _existingVehicles > 0) then {
                    {
                        deleteVehicle _x;
                    } forEach _existingVehicles;
                    
                    // Attente pour éviter les collisions physique
                    sleep 0.5;
                };
            };

            // Définition de la position d'apparition
            private _spawnPos = [];
            private _spawnDir = 0;

            if (!isNil "vehicles_spawner" && {!isNull vehicles_spawner}) then {
                _spawnPos = getPosATL vehicles_spawner;
                _spawnDir = getDir vehicles_spawner;
                
                // Ajuste la hauteur (Z) légèrement pour éviter que le véhicule soit "dans" le sol
                _spawnPos = [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.1];
            } else {
                systemChat (localize "STR_DEBUG_NO_SPAWNER");
                // Position par défaut derrière le joueur
                _spawnPos = player getRelPos [10, 0]; 
                _spawnDir = getDir player;
                _spawnPos = [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.1];
            };

            // Processus de création du véhicule (vide)
            private _veh = createVehicle [_classname, _spawnPos, [], 0, "CAN_COLLIDE"];
            _veh setDir _spawnDir;
            _veh setPosATL _spawnPos;
            
            // Notification
            hint format [localize "STR_VEHICLE_AVAILABLE", _displayName];
        };
    };

    case "DELETE": {
        // Supprime tous les véhicules présents dans la zone du déclencheur (trigger)
        private _deletedCount = 0;
        
        if (!isNil "vehicles_request" && {!isNull vehicles_request}) then {
            private _vehiclesInArea = vehicles select {_x inArea vehicles_request};
            
            {
                deleteVehicle _x;
                _deletedCount = _deletedCount + 1;
            } forEach _vehiclesInArea;
            
            hint format [localize "STR_VEHICLES_DELETED", _deletedCount];
        } else {
            systemChat "DEBUG: vehicles_request trigger not found.";
        };
    };
};
