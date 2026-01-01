/*
    ====================================================================================================
    FONCTION : MISSION_fnc_task_x_finish
    ====================================================================================================
    Description : 
        Séquence de fin de mission (succès).
        Affiche une séquence cinématique avec musique et messages de félicitations,
        puis termine la mission sur un succès.
    
    Séquence :
        1. Musique "00outro"
        2. "MISSION ACCOMPLIE." + sous-titre (10 sec)
        3. Pause (10 sec)
        4. "De nouvelles missions vous seront confiées prochainement...." (5 sec)
        5. "À bientôt sur..." (5 sec)
        6. Titre du jeu STR_INTRO_TITLE (10 sec)
        7. Fade noir (2 sec)
        8. Fin de mission (succès)
    ====================================================================================================
*/

// Exécution uniquement sur les machines avec interface (joueurs)
if (hasInterface) then {
    [] spawn {
        // Nécessaire pour manipuler les éléments d'interface utilisateur
        disableSerialization;
        
        // ==============================================================================================
        // INITIALISATION
        // ==============================================================================================
        
        // Bloquer les contrôles du joueur pendant la séquence
        disableUserInput true;
        
        // Afficher les bandes noires cinématiques
        showCinemaBorder true;
        
        // Rendre le joueur invulnérable pendant l'outro
        player allowDamage false;
        
        // ==============================================================================================
        // MUSIQUE D'OUTRO
        // ==============================================================================================
        playMusic "00outro";
        sleep 5;
        
        // ==============================================================================================
        // MESSAGE 1 : MISSION ACCOMPLIE (10 secondes)
        // ==============================================================================================
        // Utilisation de titleText avec PLAIN pour un simple fade (pas de défilement)
        titleText [
            format [
                "<t size='3.0' color='#00ff00' font='PuristaBold' shadow='2'>%1</t><br/><br/>" +
                "<t size='1.3' color='#cccccc' font='PuristaLight'>%2</t>",
                localize "STR_FINISH_MISSION_SUCCESS",
                localize "STR_FINISH_CONGRATULATIONS"
            ],
            "PLAIN", 1, true, true
        ];
        titleFadeOut 1;  // Prépare le fade out
        
        sleep 2;
        titleText ["", "PLAIN", 1];  // Estompe le texte
        sleep 7;
        
        // ==============================================================================================
        // PAUSE (10 secondes)
        // ==============================================================================================
        sleep 7;
        
        // ==============================================================================================
        // MESSAGE 2 : NOUVELLES MISSIONS (5 secondes)
        // ==============================================================================================
        titleText [
            format [
                "<t size='1.6' color='#ffffff' font='PuristaLight'>%1</t>",
                localize "STR_FINISH_NEW_MISSIONS"
            ],
            "PLAIN", 1, true, true
        ];
        
        sleep 4;
        titleText ["", "PLAIN", 1];
        sleep 5;
        
        // ==============================================================================================
        // MESSAGE 3 : À BIENTÔT SUR... (5 secondes)
        // ==============================================================================================
        titleText [
            format [
                "<t size='1.6' color='#bbbbbb' font='PuristaLight'>%1</t>",
                localize "STR_FINISH_SEE_YOU"
            ],
            "PLAIN", 1, true, true
        ];
        
        sleep 4;
        titleText ["", "PLAIN", 1];
        sleep 5;
        
        // ==============================================================================================
        // MESSAGE 4 : TITRE DU JEU (10 secondes)
        // ==============================================================================================
        titleText [
            format [
                "<t size='3.5' color='#ffffff' font='PuristaBold' shadow='2'>%1</t>",
                localize "STR_INTRO_TITLE"
            ],
            "PLAIN", 1, true, true
        ];
        
        sleep 7;
        titleText ["", "PLAIN", 2];  // Fade out plus long
        sleep 2;
        
        // ==============================================================================================
        // FADE NOIR ET FIN
        // ==============================================================================================
        
        // Fondu vers le noir
        cutText ["", "BLACK FADED", 2];
        sleep 2;
        
        // Restaurer les contrôles avant la fin
        disableUserInput false;
        showCinemaBorder false;
        
        // ==============================================================================================
        // TERMINER LA MISSION SUR UN SUCCÈS
        // ==============================================================================================
        // "END1" est l'identifiant de fin, true = succès (débriefing positif)
        ["END1", true] call BIS_fnc_endMission;
    };
};
