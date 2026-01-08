
/*
    Description :
    Cette fonction gère la synchronisation des badges (insignes) d'équipe.
    Lorsqu'un chef de groupe sort du trigger arsenal_request, son badge
    est automatiquement appliqué à toutes les unités I.A. et joueurs alliés.
    
    Modes disponibles:
    - INIT : Initialisation de la surveillance du trigger arsenal
    - SYNC : Synchronisation des badges vers les alliés
    
    Utilisation :
    ["INIT"] call MISSION_fnc_task_x_badge;  // Au démarrage
    ["SYNC", [player]] call MISSION_fnc_task_x_badge;  // Manuel
*/

params [["_mode", ""], ["_params", []]];

switch (_mode) do {
    // ==========================================================================================
    // MODE INIT : Initialise la surveillance du trigger arsenal_request
    // ==========================================================================================
    case "INIT": {
        // Cette partie ne doit être exécutée que par les clients avec interface (joueurs)
        if (!hasInterface) exitWith {};
        
        // Attend que l'objet joueur soit prêt
        waitUntil { !isNull player };
        
        // Boucle de détection de sortie du trigger arsenal_request
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
                    ["SYNC", [player]] call MISSION_fnc_task_x_badge;
                };
                
                // Met à jour l'état précédent
                _wasInArea = _isInArea;
            };
        };
    };

    // ==========================================================================================
    // MODE SYNC : Synchronise le badge du chef vers tous les alliés
    // ==========================================================================================
    case "SYNC": {
        _params params [["_unit", objNull]];
        
        // Vérifications de base
        if (isNull _unit) exitWith {};
        if (!alive _unit) exitWith {};
        
        // Vérifie si c'est le chef de groupe
        if (leader group _unit != _unit) exitWith {};
        
        // Récupère le badge actuel du chef
        private _insignia = [_unit] call BIS_fnc_getUnitInsignia;
        
        // Si pas de badge, on sort
        if (_insignia == "") exitWith {};
        
        // ============================================================
        // APPLICATION AUX I.A. DU GROUPE LOCAL
        // ============================================================
        {
            if (!isPlayer _x && alive _x) then {
                [_x, _insignia] call BIS_fnc_setUnitInsignia;
            };
        } forEach (units group _unit);
        
        // ============================================================
        // SYNCHRONISATION AVEC LES AUTRES JOUEURS DU SERVEUR
        // ============================================================
        // Envoie le badge à tous les clients pour synchroniser les joueurs alliés
        [[_unit, _insignia], {
            params ["_leader", "_badgeClass"];
            
            // Vérifie que c'est bien un joueur avec interface
            if (!hasInterface) exitWith {};
            if (isNull player) exitWith {};
            
            // Applique le badge si le joueur est du même camp que le leader
            if (side player == side _leader) then {
                [player, _badgeClass] call BIS_fnc_setUnitInsignia;
                
                // Applique également aux I.A. locales du groupe du joueur
                {
                    if (!isPlayer _x && alive _x && local _x) then {
                        [_x, _badgeClass] call BIS_fnc_setUnitInsignia;
                    };
                } forEach (units group player);
            };
        }] remoteExec ["call", 0];
        
        // Notification au chef
        hint format [localize "STR_BADGE_SYNCED", _insignia];
    };
};
