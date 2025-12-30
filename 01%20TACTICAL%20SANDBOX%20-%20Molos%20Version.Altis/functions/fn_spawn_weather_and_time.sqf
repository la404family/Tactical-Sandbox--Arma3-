/*
    Description :
    Cette fonction permet de modifier l'heure et la météo (nuages, brouillard) via une interface.
    Modes : INIT, OPEN, APPLY.
*/

params ["_mode"];

// ============================================================================
// INIT - Initialisation de l'action
// ============================================================================
if (_mode == "INIT") exitWith {
    // Attendre que la mission commence réellement (temps > 0)
    [] spawn {
        waitUntil {time > 0};
        
        // Ajouter l'action au joueur pour ouvrir le menu météo/temps
        // La condition "player inArea weather_and_time_request" assure que l'action n'apparaît que dans la zone spécifique
        player addAction [
            localize "STR_ACTION_WEATHER", 
            {
                ["OPEN"] call MISSION_fnc_spawn_weather_and_time;
            },
            [],
            1.5, 
            true, 
            true, 
            "", 
            "player inArea weather_and_time_request"
        ];
    };
};

// ============================================================================
// OPEN - Ouverture et remplissage du dialogue
// ============================================================================
if (_mode == "OPEN") exitWith {
    createDialog "Refour_Weather_Time_Dialog";
    
    // Remplir la liste des Heures disponibles
    // Valeurs : 3, 5, 7, 10, 11, 13, 17, 18, 19, 22
    private _ctrlTime = (findDisplay 9999) displayCtrl 2100;
    private _times = [3,5,7,10,11,13,17,18,19,22];
    {
        private _index = _ctrlTime lbAdd format ["%1:00", _x];
        _ctrlTime lbSetData [_index, str _x]; // Stocke l'heure brute
    } forEach _times;
    _ctrlTime lbSetCurSel 0;

    // Remplir la liste de Couverture Nuageuse
    // Valeurs : 5%, 10%, ..., 95%
    private _ctrlClouds = (findDisplay 9999) displayCtrl 2101;
    private _clouds = [5,10,15,30,45,55,60,75,80,95];
    {
        private _index = _ctrlClouds lbAdd format ["%1%2", _x, "%"];
        _ctrlClouds lbSetData [_index, str (_x / 100)]; // Stocke la valeur normalisée (0.05 à 0.95)
    } forEach _clouds;
    _ctrlClouds lbSetCurSel 0;

    // Remplir la liste du Brouillard
    // Valeurs : 0%, 10%, ..., 75%
    private _ctrlFog = (findDisplay 9999) displayCtrl 2102;
    private _fogs = [0,10,15,20,25,30,45,55,60,75];
    {
        private _index = _ctrlFog lbAdd format ["%1%2", _x, "%"];
        _ctrlFog lbSetData [_index, str (_x / 100)]; // Stocke la valeur normalisée
    } forEach _fogs;
    _ctrlFog lbSetCurSel 0;
};

// ============================================================================
// APPLY - Application des changements choisis
// ============================================================================
if (_mode == "APPLY") exitWith {
    private _ctrlTime = (findDisplay 9999) displayCtrl 2100;
    private _ctrlClouds = (findDisplay 9999) displayCtrl 2101;
    private _ctrlFog = (findDisplay 9999) displayCtrl 2102;

    // Récupération des données sélectionnées
    private _timeSel = _ctrlTime lbData (lbCurSel _ctrlTime);
    private _cloudSel = _ctrlClouds lbData (lbCurSel _ctrlClouds);
    private _fogSel = _ctrlFog lbData (lbCurSel _ctrlFog);

    // Vérification que les sélections sont valides (non vides)
    if (_timeSel != "" && _cloudSel != "" && _fogSel != "") then {
        // Appliquer l'heure
        private _hour = parseNumber _timeSel;
        private _date = date; // Récupère la date actuelle [année, mois, jour, heure, minute]
        _date set [3, _hour]; // Change l'heure
        _date set [4, 0];     // Met les minutes à 0
        setDate _date;

        // Appliquer la météo
        // 0 transition time pour effet immédiat
        // setOvercast définit la couverture nuageuse (0 à 1)
        0 setOvercast (parseNumber _cloudSel);
        // setFog définit la densité du brouillard (0 à 1)
        0 setFog (parseNumber _fogSel);
        
        // Forcer le changement immédiat de la météo (forceRefresh)
        forceWeatherChange;

        // Message de confirmation au joueur
        hint format [
            "%1: %2:00\n%3: %4%5\n%6: %7%8", 
            localize "STR_LABEL_TIME", _hour,
            localize "STR_LABEL_CLOUDS", (parseNumber _cloudSel) * 100, "%",
            localize "STR_LABEL_FOG", (parseNumber _fogSel) * 100, "%"
        ];
        
        closeDialog 0;
    } else {
        hint "Error: Invalid selection";
    };
};
