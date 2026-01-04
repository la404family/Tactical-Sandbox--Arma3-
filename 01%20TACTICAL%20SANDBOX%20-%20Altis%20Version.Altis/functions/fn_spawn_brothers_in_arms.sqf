
/*
    Description :
    Cette fonction gère le système de recrutement "Frères d'armes".
    Elle permet au joueur de recruter jusqu'à 14 unités IA de sa faction.
    Les unités sélectionnées apparaissent avec 2 secondes d'intervalle.
    
    Modes disponibles:
    - INIT : Initialisation de l'action d'interaction
    - OPEN_UI : Ouverture et peuplement du menu de recrutement
    - ADD : Ajouter une unité à la liste de sélection
    - VALIDATE : Confirmer et faire apparaître toutes les unités sélectionnées
    - RESET : Supprimer toutes les unités I.A. du groupe du joueur
*/

params [["_mode", ""], ["_params", []]];

// Variable globale pour stocker les unités sélectionnées
if (isNil "MISSION_selectedBrothers") then {
    MISSION_selectedBrothers = [];
};

switch (_mode) do {
    // ==========================================================================================
    // MODE INIT : Initialise l'action de recrutement
    // ==========================================================================================
    case "INIT": {
        // Condition : Interface uniquement (joueur)
        if (!hasInterface) exitWith {};
        
        // Attend que l'objet joueur soit prêt
        waitUntil { !isNull player };
        
        // Ajoute l'action de recrutement
        player addAction [
            localize "STR_ADD_BROTHER", // "Recruter des frères d'armes"
            {
                // Appelle ce script avec le mode OPEN_UI
                ["OPEN_UI"] call MISSION_fnc_spawn_brothers_in_arms;
            },
            [],
            1.5, 
            true, 
            true, 
            "",
            "player inArea brothers_in_arms_request" // Visible seulement dans la zone de requête
        ];
        
        // ============================================================
        // TRIGGER ANTI-COLLISION : Pousse les joueurs hors de la zone de spawn
        // ============================================================
        [] spawn {
            while {true} do {
                sleep 0.1;
                
                // Vérifie si le trigger et le point de sortie existent
                if (isNil "brothers_in_arms_spawner_trigger" || isNil "brothers_in_arms_spawner_1") then {
                    continue;
                };
                
                // Vérifie si le joueur est dans le trigger
                if (player inArea brothers_in_arms_spawner_trigger) then {
                    // Affiche l'avertissement
                    hint (localize "STR_ZONE_RESERVED");
                    
                    // Calcule la direction vers le point de sortie
                    private _exitPos = getPosATL brothers_in_arms_spawner_1;
                    private _playerPos = getPosATL player;
                    private _direction = _playerPos getDir _exitPos;
                    
                    // Pousse le joueur dans cette direction
                    private _pushDistance = 0.7;
                    private _newPos = player getRelPos [_pushDistance, _direction - (getDir player)];
                    player setPosATL [_newPos select 0, _newPos select 1, getPosATL player select 2];
                };
            };
        };
    };

    // ==========================================================================================
    // MODE OPEN_UI : Ouvre le dialogue et peuple les listes
    // ==========================================================================================
    case "OPEN_UI": {
        // Réinitialise la liste des unités sélectionnées
        MISSION_selectedBrothers = [];
        
        // Crée la boîte de dialogue
        createDialog "Refour_Recruit_Dialog";
        
        // Attend que le dialogue soit effectivement ouvert (ID 8888)
        waitUntil {!isNull (findDisplay 8888)};
        
        private _display = findDisplay 8888;
        private _ctrlAvailable = _display displayCtrl 1500; // Liste des unités disponibles
        private _ctrlSelected = _display displayCtrl 1503;  // Liste des unités sélectionnées
        private _ctrlCounter = _display displayCtrl 1502;   // Compteur
        
        // Vide les listes
        lbClear _ctrlAvailable;
        lbClear _ctrlSelected;
        
        // Compte les unités déjà dans le groupe du joueur (sans le joueur lui-même)
        private _currentGroupCount = {alive _x && !isPlayer _x} count (units group player);
        
        // Met à jour le compteur avec le nombre actuel
        _ctrlCounter ctrlSetText format ["%1 / 14", _currentGroupCount];
        
        // Colore le compteur selon le niveau
        if (_currentGroupCount >= 14) then {
            _ctrlCounter ctrlSetTextColor [1, 0.2, 0.2, 1]; // Rouge si max
        } else {
            if (_currentGroupCount >= 10) then {
                _ctrlCounter ctrlSetTextColor [1, 0.8, 0, 1]; // Orange
            } else {
                _ctrlCounter ctrlSetTextColor [0.6, 1, 0.2, 1]; // Vert
            };
        };

        // Récupération des classes de configuration
        private _sideInt = (side player) call BIS_fnc_sideID;
        private _cfgVehicles = configFile >> "CfgVehicles";
        
        // Sélectionne les unités compatibles
        private _units = "
            (getNumber (_x >> 'scope') == 2) && 
            (getText (_x >> 'simulation') == 'soldier') && 
            (getNumber (_x >> 'side') == _sideInt)
        " configClasses _cfgVehicles;

        // Prépare un tableau triable
        private _sortableUnits = [];

        {
            private _class = _x;
            private _displayName = getText (_class >> "displayName");
            private _className = configName _class;
            private _factionClass = getText (_class >> "faction");
            
            // Récupère le nom affiché de la faction
            private _factionDisplayName = getText (configFile >> "CfgFactionClasses" >> _factionClass >> "displayName");
            if (_factionDisplayName == "") then { _factionDisplayName = _factionClass; };

            // Construit le texte de l'entrée
            private _entryText = format ["[%1] %2", _factionDisplayName, _displayName];
            
            _sortableUnits pushBack [_entryText, _className];

        } forEach _units;

        // Tri alphabétique
        _sortableUnits sort true;

        // --- AJOUT OPTION SPECIALE "COMME MOI" EN PREMIER ---
        private _textLikeMe = localize "STR_BROTHERS_LIKE_ME";
        if (_textLikeMe == "" || _textLikeMe == "STR_BROTHERS_LIKE_ME") then { _textLikeMe = "Un soldat comme moi !"; };
        
        private _likeMeIndex = _ctrlAvailable lbAdd _textLikeMe;
        _ctrlAvailable lbSetData [_likeMeIndex, "LIKE_ME"];
        _ctrlAvailable lbSetColor [_likeMeIndex, [0.85, 0.85, 0, 1]];

        // Ajoute les éléments triés dans la ListBox
        {
            _x params ["_text", "_data"];
            private _index = _ctrlAvailable lbAdd _text;
            _ctrlAvailable lbSetData [_index, _data];
        } forEach _sortableUnits;

        // Sélectionne le premier élément par défaut
        if (lbSize _ctrlAvailable > 0) then {
            _ctrlAvailable lbSetCurSel 0;
        };
    };

    // ==========================================================================================
    // MODE ADD : Ajoute l'unité sélectionnée à la liste de recrutement
    // ==========================================================================================
    case "ADD": {
        disableSerialization;
        private _display = findDisplay 8888;
        if (isNull _display) exitWith {};
        
        private _ctrlAvailable = _display displayCtrl 1500;
        private _ctrlSelected = _display displayCtrl 1503;
        private _ctrlCounter = _display displayCtrl 1502;
        
        // Compte les unités déjà dans le groupe (sans le joueur)
        private _currentGroupCount = {alive _x && !isPlayer _x} count (units group player);
        private _selectedCount = count MISSION_selectedBrothers;
        private _totalCount = _currentGroupCount + _selectedCount;
        
        // Vérifie la limite de 14 unités (groupe actuel + sélectionnées)
        if (_totalCount >= 14) exitWith {
            // Son d'erreur
            playSound "AddItemFailed";
            // Hint avec message localisé
            hint localize "STR_MAX_UNITS_REACHED";
        };
        
        // Récupère l'unité sélectionnée
        private _index = lbCurSel _ctrlAvailable;
        if (_index == -1) exitWith {};
        
        private _className = _ctrlAvailable lbData _index;
        private _displayName = _ctrlAvailable lbText _index;
        
        // Ajoute à la liste des sélectionnées (stocke classe et nom)
        MISSION_selectedBrothers pushBack [_className, _displayName];
        
        // Ajoute à la liste visuelle
        private _newIndex = _ctrlSelected lbAdd _displayName;
        _ctrlSelected lbSetData [_newIndex, _className];
        
        // Colore en jaune/doré si c'est "Comme moi"
        if (_className == "LIKE_ME") then {
            _ctrlSelected lbSetColor [_newIndex, [0.85, 0.85, 0, 1]];
        };
        
        // Met à jour le compteur (groupe actuel + sélectionnées)
        _selectedCount = count MISSION_selectedBrothers;
        _totalCount = _currentGroupCount + _selectedCount;
        _ctrlCounter ctrlSetText format ["%1 / 14", _totalCount];
        
        // Change la couleur du compteur selon le niveau
        if (_totalCount >= 14) then {
            _ctrlCounter ctrlSetTextColor [1, 0.2, 0.2, 1]; // Rouge si max
        } else {
            if (_totalCount >= 10) then {
                _ctrlCounter ctrlSetTextColor [1, 0.8, 0, 1]; // Orange si proche du max
            } else {
                _ctrlCounter ctrlSetTextColor [0.6, 1, 0.2, 1]; // Vert sinon
            };
        };
    };

    // ==========================================================================================
    // MODE VALIDATE : Fait apparaître toutes les unités sélectionnées
    // ==========================================================================================
    case "VALIDATE": {
        disableSerialization;
        
        // Vérifie qu'il y a des unités à faire apparaître
        if (count MISSION_selectedBrothers == 0) exitWith {
            hint localize "STR_NO_UNITS_SELECTED";
        };
        
        // Ferme le dialogue
        closeDialog 1;
        
        // Copie la liste et la vide immédiatement
        private _unitsToSpawn = +MISSION_selectedBrothers;
        MISSION_selectedBrothers = [];
        
        // Notification du début du spawn
        private _totalUnits = count _unitsToSpawn;
        hint format [localize "STR_SPAWNING_UNITS", _totalUnits];
        
        // Lance le processus de spawn dans un nouveau thread
        [_unitsToSpawn] spawn {
            params ["_units"];
            
            private _spawnIndex = 0;
            
            {
                _x params ["_classOrType", "_displayName"];
                _spawnIndex = _spawnIndex + 1;
                
                // Définit la position d'apparition
                private _spawnPos = [];
                if (!isNil "brothers_in_arms_spawner" && {!isNull brothers_in_arms_spawner}) then {
                    _spawnPos = getPosATL brothers_in_arms_spawner;
                } else {
                    _spawnPos = player getRelPos [5, 0]; 
                };

                // ============================================================
                // EFFET FUMÉE BLANCHE - APPARAIT 0.4s AVANT LE SOLDAT
                // ============================================================
                // Grenade fumigène blanche
                private _smoke = "SmokeShellWhite" createVehicle _spawnPos;
                
                // Effet de particules supplémentaire pour plus de densité
                private _source = "#particlesource" createVehicle _spawnPos;
                _source setParticleParams [
                    ["\A3\Data_F\ParticleEffects\Universal\Universal.p3d", 16, 12, 8, 1],
                    "", "Billboard", 1, 3, [0, 0, 0.5], [0, 0, 2], 1, 1.5, 1, 0.3,
                    [2, 4, 8], [[1, 1, 1, 0.6], [1, 1, 1, 0.4], [1, 1, 1, 0]], [1],
                    0.1, 0.3, "", "", ""
                ];
                _source setParticleRandom [2, [1, 1, 0.5], [1, 1, 0.5], 0, 0.5, [0, 0, 0, 0.1], 0, 0];
                _source setDropInterval 0.01;
                
                // Suppression de la source de particules après 3 secondes
                [_source] spawn {
                    params ["_src"];
                    sleep 3;
                    if (!isNull _src) then { deleteVehicle _src; };
                };
                
                // Attend 0.4 seconde avant de faire apparaître le soldat
                sleep 0.4;

                // Crée un groupe temporaire
                private _tempGroup = createGroup [side player, true];
                private _newUnit = objNull;

                if (_classOrType == "LIKE_ME") then {
                    // CAS SPECIAL : CLONE DU JOUEUR
                    _newUnit = _tempGroup createUnit [typeOf player, _spawnPos, [], 0, "CAN_COLLIDE"];
                    
                    if (isNull _newUnit) then {
                        _newUnit = _tempGroup createUnit ["B_Soldier_F", _spawnPos, [], 0, "CAN_COLLIDE"];
                    };

                    if (!isNull _newUnit) then {
                        _newUnit setUnitLoadout (getUnitLoadout player);
                        
                        // Change le visage aléatoirement
                        private _faces = [
                            "WhiteHead_01", "WhiteHead_02", "WhiteHead_03", "WhiteHead_04", "WhiteHead_05",
                            "WhiteHead_06", "WhiteHead_07", "WhiteHead_08", "WhiteHead_09", "WhiteHead_10",
                            "WhiteHead_11", "WhiteHead_12", "WhiteHead_13", "WhiteHead_14", "WhiteHead_15",
                            "WhiteHead_16", "WhiteHead_17", "WhiteHead_18", "WhiteHead_19", "WhiteHead_20",
                            "AfricanHead_01", "AfricanHead_02", "AfricanHead_03",
                            "AsianHead_A3_01", "AsianHead_A3_02", "AsianHead_A3_03",
                            "GreekHead_A3_01", "GreekHead_A3_02", "GreekHead_A3_03", "GreekHead_A3_04",
                            "PersianHead_A3_01", "PersianHead_A3_02", "PersianHead_A3_03"
                        ];
                        _newUnit setFace (selectRandom _faces);
                    };
                } else {
                    // CAS STANDARD
                    _newUnit = _tempGroup createUnit [_classOrType, _spawnPos, [], 0, "CAN_COLLIDE"];
                };

                // Vérification finale
                if (isNull _newUnit) then {
                    deleteGroup _tempGroup;
                } else {
                    // Oriente l'unité comme le spawner
                    if (!isNil "brothers_in_arms_spawner" && {!isNull brothers_in_arms_spawner}) then {
                        _newUnit setDir (getDir brothers_in_arms_spawner);
                    };
                    
                    // Pause pour initialisation
                    
                    // ============================================================
                    // DÉPLACEMENT VERS LE POINT DE SORTIE
                    // ============================================================
                    if (!isNil "brothers_in_arms_spawner_1" && {!isNull brothers_in_arms_spawner_1}) then {
                        private _exitPos = getPosATL brothers_in_arms_spawner_1;
                        
                        _newUnit doMove _exitPos;
                        _newUnit setSpeedMode "FULL";
                        
                        private _timeout = time + 10;
                        waitUntil {
                            sleep 0.3;
                            (_newUnit distance2D _exitPos < 2) || (time > _timeout) || !alive _newUnit
                        };
                        
                        doStop _newUnit;
                    };
                    
                    // L'unité rejoint le groupe du joueur
                    [_newUnit] joinSilent (group player);
                    
                    // Notification
                    hint format [localize "STR_UNIT_JOINED", _displayName];
                    
                    // Nettoyage du groupe temporaire
                    deleteGroup _tempGroup;
                };
                
                // Attend 2 secondes avant de faire apparaître la prochaine unité
                if (_spawnIndex < count _units) then {
                    sleep 2;
                };
                
            } forEach _units;
            
            // Notification finale
            hint format [localize "STR_ALL_UNITS_SPAWNED", count _units];
        };
    };

    // ==========================================================================================
    // MODE RESET : Supprime toutes les unités I.A. du groupe du joueur
    // ==========================================================================================
    case "RESET": {
        disableSerialization;
        
        // Récupérer toutes les unités du groupe du joueur
        private _playerGroup = group player;
        private _unitsToDelete = [];
        
        // Collecter les unités I.A. (pas le joueur lui-même)
        {
            if (!isPlayer _x && alive _x) then {
                _unitsToDelete pushBack _x;
            };
        } forEach (units _playerGroup);
        
        // Compter les unités supprimées
        private _count = count _unitsToDelete;
        
        // Supprimer les unités I.A.
        {
            deleteVehicle _x;
        } forEach _unitsToDelete;
        
        // Notification du nombre d'unités supprimées
        if (_count > 0) then {
            hint format [localize "STR_AI_RESET_COUNT", _count];
        } else {
            hint localize "STR_AI_RESET_NONE";
        };
        
        // Mise à jour du compteur si l'interface est ouverte
        private _display = findDisplay 8888;
        if (!isNull _display) then {
            private _ctrlCounter = _display displayCtrl 1502;
            
            // Recalcul : Groupe (0) + Sélection en cours
            private _currentGroupCount = 0; // On vient de tout supprimer
            private _selectedCount = count MISSION_selectedBrothers; // On garde la sélection en cours
            private _totalCount = _currentGroupCount + _selectedCount;
            
            _ctrlCounter ctrlSetText format ["%1 / 14", _totalCount];
            
            // Mise à jour couleur (Vert car forcément < 10 si on vient de reset le groupe, sauf si sélection énorme)
            if (_totalCount >= 14) then {
                _ctrlCounter ctrlSetTextColor [1, 0.2, 0.2, 1];
            } else {
                if (_totalCount >= 10) then {
                    _ctrlCounter ctrlSetTextColor [1, 0.8, 0, 1];
                } else {
                    _ctrlCounter ctrlSetTextColor [0.6, 1, 0.2, 1];
                };
            };
        };
    };
};
