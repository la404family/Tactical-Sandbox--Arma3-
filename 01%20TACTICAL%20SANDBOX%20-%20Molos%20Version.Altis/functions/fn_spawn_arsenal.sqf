
/*
    Description :
    Cette fonction initialise l'arsenal virtuel pour le joueur.
    Elle ajoute une action au joueur qui n'est visible que lorsqu'il se trouve dans la zone "arsenal_request".
*/

// Récupère les paramètres passés à la fonction. "_mode" détermine l'action à effectuer.
params ["_mode", ["_params", []]];

// Gère les différents modes d'exécution.
switch (_mode) do {
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
    };
};
