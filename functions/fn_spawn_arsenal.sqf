
/*
    Description :
    Cette fonction initialise l'arsenal virtuel pour le joueur.
    Elle ajoute une action au joueur qui n'est visible que lorsqu'il se trouve dans la zone "arsenal_request".
    
    Lorsqu'un chef de groupe sort de la zone arsenal, sa voix (langue du personnage) est
    automatiquement synchronisée vers toutes les unités I.A. du groupe et les autres joueurs alliés.
    
    Modes disponibles:
    - INIT : Initialisation de l'action arsenal et surveillance du trigger
    - SYNC : Synchronisation de la voix du chef vers tous les alliés
*/

// Récupère les paramètres passés à la fonction. "_mode" détermine l'action à effectuer.
params [["_mode", ""], ["_params", []]];

// Gère les différents modes d'exécution.
switch (_mode) do {
    // ==========================================================================================
    // MODE INIT : Initialise l'action arsenal et la surveillance de sortie du trigger
    // ==========================================================================================
    case "INIT": {
        // Cette partie ne doit être exécutée que par les clients avec interface (joueurs).
        if (!hasInterface) exitWith {};
        
        // Attend que l'objet "player" soit initialisé et valide.
        waitUntil { !isNull player };
        
        // Ajoute une action au joueur pour ouvrir l'arsenal.
        player addAction [
            localize "STR_ACTION_ARSENAL", // Nom de l'action affiché (localisé).
            {
                // Script exécuté lors de l'activation de l'action :
                // Ouvre l'arsenal virtuel de BIS pour le joueur.
                ["Open", [true]] call BIS_fnc_arsenal;
            },
            [],
            1.5, 
            true, 
            true, 
            "",
            "player inArea arsenal_request" // Condition : l'action n'est visible que si le joueur est dans la zone "arsenal_request".
        ];
        
        // ============================================================
        // BOUCLE DE DÉTECTION DE SORTIE DU TRIGGER ARSENAL
        // Synchronise la voix du chef de groupe lorsqu'il sort de l'arsenal
        // ============================================================
        [] spawn {
            private _wasInArea = false;
            
            while {true} do {
                sleep 0.5;
                
                // Vérifie si le trigger existe
                if (isNil "arsenal_request") then {
                    continue;
                };
                
                // Vérifie si le joueur est actuellement dans la zone
                private _isInArea = player inArea arsenal_request;
                
                // Détecte la SORTIE du trigger (passage de true à false)
                if (_wasInArea && !_isInArea) then {
                    // Appelle le mode SYNC avec le joueur qui sort
                    ["SYNC", [player]] call MISSION_fnc_spawn_arsenal;
                };
                
                // Met à jour l'état précédent
                _wasInArea = _isInArea;
            };
        };
    };

    // ==========================================================================================
    // MODE SYNC : Synchronise la voix du chef vers tous les alliés
    // ==========================================================================================
    case "SYNC": {
        _params params [["_unit", objNull]];
        
        // Vérifications de base
        if (isNull _unit) exitWith {};
        if (!alive _unit) exitWith {};
        
        // Vérifie si c'est le chef de groupe
        if (leader group _unit != _unit) exitWith {};
        
        // Récupère la voix actuelle du chef (classe de speaker)
        private _speakerClass = speaker _unit;
        
        // Si pas de speaker valide, on sort
        if (_speakerClass == "") exitWith {};
        
        // ============================================================
        // APPLICATION AUX I.A. DU GROUPE LOCAL
        // ============================================================
        {
            if (!isPlayer _x && alive _x) then {
                _x setSpeaker _speakerClass;
            };
        } forEach (units group _unit);
        
        // ============================================================
        // SYNCHRONISATION AVEC LES AUTRES JOUEURS DU SERVEUR
        // ============================================================
        // Envoie la voix à tous les clients pour synchroniser les joueurs alliés
        [[_unit, _speakerClass], {
            params ["_leader", "_voiceClass"];
            
            // Vérifie que c'est bien un joueur avec interface
            if (!hasInterface) exitWith {};
            if (isNull player) exitWith {};
            
            // Applique la voix si le joueur est du même camp que le leader
            if (side player == side _leader) then {
                player setSpeaker _voiceClass;
                
                // Applique également aux I.A. locales du groupe du joueur
                {
                    if (!isPlayer _x && alive _x && local _x) then {
                        _x setSpeaker _voiceClass;
                    };
                } forEach (units group player);
            };
        }] remoteExec ["call", 0];
    };
};
