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
        waitUntil {time > 0};    // Ajouter l'action au joueur pour ouvrir le menu météo/temps
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
};};// ============================================================================
// OPEN - Ouverture et remplissage du dialogue
// ============================================================================
if (_mode == "OPEN") exitWith {
    createDialog "Refour_Weather_Time_Dialog";// Remplir la liste des Heures disponibles
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
private _fogs = [0,0.2,0.4,0.6,0.8,1,1.3,1.6,2,2.5];
{
    private _index = _ctrlFog lbAdd format ["%1%2", _x, "%"];
    _ctrlFog lbSetData [_index, str (_x / 100)]; // Stocke la valeur normalisée
} forEach _fogs;
_ctrlFog lbSetCurSel 0;};// ============================================================================
// APPLY - Application des changements choisis
// ============================================================================
if (_mode == "APPLY") exitWith {
    private _ctrlTime = (findDisplay 9999) displayCtrl 2100;
    private _ctrlClouds = (findDisplay 9999) displayCtrl 2101;
    private _ctrlFog = (findDisplay 9999) displayCtrl 2102;// Récupération des données sélectionnées
private _timeSel = _ctrlTime lbData (lbCurSel _ctrlTime);
private _cloudSel = _ctrlClouds lbData (lbCurSel _ctrlClouds);
private _fogSel = _ctrlFog lbData (lbCurSel _ctrlFog);

// Vérification que les sélections sont valides (non vides)
if (_timeSel != "" && _cloudSel != "" && _fogSel != "") then {
    // Appliquer l'heure et la météo (Exécution serveur pour synchro et fiabilité)
    private _hour = parseNumber _timeSel;
    private _overcast = parseNumber _cloudSel;
    private _fog = parseNumber _fogSel;

   [[_hour, _overcast, _fog], {
        params ["_h", "_o", "_f"];
        
        // 1. Appliquer l'heure
        private _date = date; 
        _date set [3, _h]; 
        _date set [4, 0];
        setDate _date;

        // 2. Appliquer la météo (Nuages)
        0 setOvercast _o;
        999999 setOvercast _o;
        forceWeatherChange; // Force le moteur à redessiner les nuages
        
        // 3. Appliquer le Brouillard
        // Syntaxe : [Densité, Dégradation (0.01 à 1), Altitude Base]
        // J'ai mis l'altitude à 0 pour que le brouillard soit au sol.
        0 setFog [_f, 0.05, 150]; 
        
        // 4. SYNCHRONISATION (La ligne manquante)
        // Obligatoire pour que tous les joueurs voient le changement instantanément
        simulWeatherSync;
        
    }] remoteExec ["spawn", 2]; 

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
};};

