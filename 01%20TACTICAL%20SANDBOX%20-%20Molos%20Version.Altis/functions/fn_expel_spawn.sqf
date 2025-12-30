//-------------------------------------------
// Description : Expulse les joueurs et IA du trigger "expel_spawn" sans les blesser.
//-------------------------------------------

if (isNil "expel_spawn") exitWith {
    diag_log "ERREUR : fn_expel_spawn : Le trigger 'expel_spawn' n'existe pas.";
    systemChat "ERREUR : fn_expel_spawn : Le trigger 'expel_spawn' n'existe pas.";
};

private ["_units", "_toPush", "_veh", "_center", "_pos", "_dir", "_speed"];

while {true} do {
    // Sélectionne toutes les unités vivantes dans la zone du trigger
    _units = allUnits select { alive _x && (_x inArea expel_spawn) };
    
    // Liste des entités uniques à pousser (véhicules ou piétons)
    _toPush = [];
    {
        _veh = vehicle _x;
        _toPush pushBackUnique _veh;
    } forEach _units;
    
    // Application de la force d'expulsion
    {
        _veh = _x;
        _center = getPos expel_spawn;
        _pos = getPos _veh;
        
        // Calcul de la direction opposée au centre du trigger
        _dir = _center getDir _pos;
        
        // Vitesse d'expulsion (modérée pour ne pas blesser)
        _speed = 7;
        
        // Application de la vélocité
        // Z = 0.2 pour un léger soulèvement et éviter le frottement au sol immédiat
        _veh setVelocity [
            (sin _dir) * _speed, 
            (cos _dir) * _speed, 
            0.2
        ];
        
    } forEach _toPush;
    
    // Pause pour économiser les ressources et attendre la prochaine vérification
    sleep 0.2;
};
