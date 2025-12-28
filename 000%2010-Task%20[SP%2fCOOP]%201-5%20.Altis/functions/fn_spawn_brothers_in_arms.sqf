
/*
    Fichier : fn_spawn_brothers_in_arms.sqf
    Auteur : [Votre Nom]
    Description :
    Cette fonction gère le système de recrutement "Frères d'armes".
    Elle permet au joueur de recruter des unités IA de sa faction pour l'accompagner.
    Trois modes : 
    - INIT (initialisation de l'action)
    - OPEN_UI (ouverture et peuplement du menu de recrutement)
    - SPAWN (création de l'unité sélectionnée)
*/

params ["_mode", ["_params", []]];

switch (_mode) do {
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
    };

    case "OPEN_UI": {
        // Crée la boîte de dialogue définie dans les fichiers de ressources (terminologie Arma : Dialog)
        createDialog "Refour_Recruit_Dialog";
        
        // Attend que le dialogue soit effectivement ouvert (ID 8888)
        waitUntil {!isNull (findDisplay 8888)};
        
        private _display = findDisplay 8888;
        private _ctrlList = _display displayCtrl 1500; // Contrôle ListBox
        
        // Vide la liste précédente
        lbClear _ctrlList;

        // Récupération des classes de configuration
        // Filtre par camp (Side) pour n'inclure que les factions amies (NATO, FIA, etc. selon le camp du joueur)
        private _sideInt = (side player) call BIS_fnc_sideID;
        private _cfgVehicles = configFile >> "CfgVehicles";
        
        // Sélectionne les unités qui :
        // 1. Ont une portée publique (scope == 2)
        // 2. Sont des soldats (simulation == 'soldier')
        // 3. Appartiennent au même camp que le joueur
        private _units = "
            (getNumber (_x >> 'scope') == 2) && 
            (getText (_x >> 'simulation') == 'soldier') && 
            (getNumber (_x >> 'side') == _sideInt)
        " configClasses _cfgVehicles;

        // Prépare un tableau triable : [CléDeTri, NomAffiché, NomDeClasse]
        // La clé de tri sera "NomFaction NomUnité" pour regrouper par faction
        private _sortableUnits = [];

        {
            private _class = _x;
            private _displayName = getText (_class >> "displayName");
            private _className = configName _class;
            private _factionClass = getText (_class >> "faction");
            
            // Récupère le nom affiché de la faction
            private _factionDisplayName = getText (configFile >> "CfgFactionClasses" >> _factionClass >> "displayName");
            if (_factionDisplayName == "") then { _factionDisplayName = _factionClass; }; // Sécurité si pas de nom

            // Construit le texte de l'entrée : [Faction] Nom de l'unité
            private _entryText = format ["[%1] %2", _factionDisplayName, _displayName];
            
            // Ajoute au tableau temporaire
            _sortableUnits pushBack [_entryText, _className];

        } forEach _units;

        // Tri alphabétique du tableau
        _sortableUnits sort true;

        // Ajoute les éléments triés dans la ListBox
        {
            _x params ["_text", "_data"];
            private _index = _ctrlList lbAdd _text;
            _ctrlList lbSetData [_index, _data]; // Stocke la classe (ex: "B_Soldier_F") comme donnée cachée
        } forEach _sortableUnits;

        // Sélectionne le premier élément par défaut s'il y en a
        if (lbSize _ctrlList > 0) then {
            _ctrlList lbSetCurSel 0;
        };
    };

    case "SPAWN": {
        disableSerialization; // Nécessaire pour manipuler les contrôles UI dans un contexte schedulé
        private _display = findDisplay 8888;
        private _listBox = _display displayCtrl 1500;

        // Validation : Vérifie qu'une unité est sélectionnée
        private _indexSelection = lbCurSel _listBox;
        if (_indexSelection == -1) exitWith {
            systemChat (localize "STR_ERR_NO_UNIT_SELECTED");
        };

        // Récupération des données (classe et nom)
        private _classname = _listBox lbData _indexSelection;
        private _displayName = _listBox lbText _indexSelection;

        // Ferme le dialogue (code de retour 1)
        closeDialog 1;

        // Définit la position d'apparition
        private _spawnPos = [];
        // Si un objet logique "brothers_in_arms_spawner" existe, on l'utilise
        if (!isNil "brothers_in_arms_spawner" && {!isNull brothers_in_arms_spawner}) then {
            _spawnPos = getPosATL brothers_in_arms_spawner;
        } else {
            // Sinon, apparait derrière le joueur (fallback)
            _spawnPos = player getRelPos [5, 0]; 
        };

        // Processus d'apparition (spawn) dans un nouveau thread
        [_classname, _spawnPos, _displayName] spawn {
            params ["_class", "_pos", "_name"];
            
            // Crée un groupe temporaire pour éviter les problèmes de "join" immédiat
            private _tempGroup = createGroup [side player, true];
            
            // Crée l'unité
            private _newUnit = _tempGroup createUnit [_class, _pos, [], 0, "CAN_COLLIDE"];
            
            // Oriente l'unité comme le spawner
            if (!isNil "brothers_in_arms_spawner" && {!isNull brothers_in_arms_spawner}) then {
                _newUnit setDir (getDir brothers_in_arms_spawner);
            };
            
            // Notification de départ
            systemChat format [localize "STR_UNIT_ARRIVING", _name];
            
            // Pause critique pour laisser le temps au moteur d'initialiser l'unité avant de changer de groupe
            sleep 0.7;
            
            // L'unité rejoint le groupe du joueur sans message vocal ("joinSilent")
            [_newUnit] joinSilent (group player);
            
            // Notification finale (Hint)
            hint format [localize "STR_UNIT_JOINED", _name];
            
            // Nettoyage du groupe temporaire (maintenant vide)
            deleteGroup _tempGroup;
        };
    };
};
