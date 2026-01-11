// ============================================================================
// SCRIPT: fn_task_x_tableau.sqf
// DESCRIPTION: Affiche le statut de la mission sur le tableau (Land_MapBoard_01_Wall_F)
// USAGE: [_taskNumber] call MISSION_fnc_task_x_tableau;
//        _taskNumber: 0 = En Attente, 1-3 = Briefing correspondant
// OBJET: tableau_des_taches (variable éditeur pour Land_MapBoard_01_Wall_F)
// ============================================================================

params [["_taskNumber", 0, [0]]];

// Récupération de l'objet tableau placé dans l'éditeur
private _tableau = missionNamespace getVariable ["tableau_des_taches", objNull];

// Vérification que le tableau existe
if (isNull _tableau) exitWith {
    diag_log "[fn_task_x_tableau] ERREUR: Objet 'tableau_des_taches' introuvable!";
};

// Détermination du texte à afficher selon le numéro de tâche
private _texteAffiche = if (_taskNumber == 0) then {
    localize "STR_TABLEAU_EN_ATTENTE"                   // "En Attente"
} else {
    // Gestion des affichages spécifiques (Titres de mission)
    private _titreSpecial = switch (_taskNumber) do {
        case 1: { "" }; // Pas encore défini
        case 8: { localize "STR_TASK_8_TITLE" }; // "La bataille de Kavala"
        default { "" };
    };
    
    if (_titreSpecial != "") then {
        _titreSpecial
    } else {
        format ["%1 %2", localize "STR_TABLEAU_BRIEFING", _taskNumber]  // "Briefing X" (dynamique)
    };
};

// ============================================================================
// PARAMÈTRES DE LA TEXTURE TEXTE
// ============================================================================
// Format: #(rgb,WIDTH,HEIGHT,3)text(ALIGN_X,ALIGN_Y,"FONT",SIZE,"BG_COLOR","FG_COLOR","TEXT")
// - Align: 1,1 = Centre/Centre
// - Fond: #1A1A1A (Gris foncé)
// - Texte: #FFFFFF (Blanc)
// ============================================================================

// Debug pour le joueur
//systemChat format ["[Tableau] Mise à jour: %1", _texteAffiche];

private _texture = format [
    "#(rgb,2048,1024,3)text(1,1,""PuristaBold"",0.10,""#1A1A1A"",""#FFFFFF"",""%1"")",
    _texteAffiche
];

// Application de la texture au tableau (synchronisée globalement)
_tableau setObjectTextureGlobal [0, _texture];

// Log pour debug serveur
diag_log format ["[fn_task_x_tableau] Tableau mis à jour avec texture: %1", _texture];
