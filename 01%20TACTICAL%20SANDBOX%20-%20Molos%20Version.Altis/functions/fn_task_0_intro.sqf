/*
    ====================================================================================================
    FONCTION : MISSION_fnc_task_0_intro
    ====================================================================================================
    Description : 
        Introduction Cinématique V2 - Système de Caméra Avancé
        Cette fonction gère l'introduction immersive de la mission avec une séquence cinématique
        complète composée de 5 plans différents, synchronisée avec le vol d'un hélicoptère
        transportant les joueurs vers la zone de mission.
    
    Caractéristiques :
        - Gestion robuste des entrées utilisateur (avec sécurité anti-blocage)
        - Plans dynamiques : QG -> Survol Ville -> Intérieur Hélico -> Vue Orbitale -> Atterrissage
        - Points de référence : batiment_officer, task_5_spawn_15, task_1_spawn_06
        - Améliorations : Transitions fluides, animations FOV subtiles, post-processing par plan,
          boucles raffinées pour un mouvement fluide, léger balancement de caméra pour réalisme
    
    Structure :
        - Partie CLIENT (hasInterface) : Gère la caméra cinématique, les effets visuels et textes
        - Partie SERVEUR (isServer) : Gère le spawn et le vol de l'hélicoptère
    ====================================================================================================
*/

// ==================================================================================================
// PARTIE CLIENT - Exécution uniquement sur les machines avec interface graphique (joueurs)
// ==================================================================================================
if (hasInterface) then {
    [] spawn {
        // ==============================================================================================
        // SECTION 1 : INITIALISATION ET SECURITE
        // ==============================================================================================
        
        // Nécessaire pour manipuler les éléments d'interface utilisateur (UI)
        disableSerialization;
        
        // ----------------------------------------------------------------------------------------------
        // SECURITE ANTI-BLOCAGE (Failsafe)
        // ----------------------------------------------------------------------------------------------
        // Ce thread parallèle garantit que les contrôles du joueur seront TOUJOURS restaurés
        // après 90 secondes, même si le script principal plante ou se bloque.
        // C'est une protection essentielle pour éviter que le joueur reste bloqué.
        [] spawn {
            sleep 90;  // Durée maximale de la cinématique
            
            // Triple appel pour forcer la réinitialisation des contrôles
            // (technique Arma 3 pour garantir le déblocage)
            disableUserInput false;
            disableUserInput true;
            disableUserInput false;
            
            // Restauration de l'état normal du joueur
            player allowDamage true;       // Le joueur peut à nouveau subir des dégâts
            showCinemaBorder false;        // Masque les bandes noires cinématiques
        };

        // ----------------------------------------------------------------------------------------------
        // ÉTAT INITIAL DE LA CINEMATIQUE
        // ----------------------------------------------------------------------------------------------
        cutText ["", "BLACK FADED", 999];  // Écran noir total (fondu instantané)
        0 fadeSound 0;                      // Coupe le son immédiatement (volume à 0 en 0 sec)
        showCinemaBorder true;              // Affiche les bandes noires cinématiques (style film)
        disableUserInput true;              // Bloque tous les contrôles du joueur
        
        // Attendre que l'objet joueur soit initialisé (sécurité multijoueur)
        waitUntil { !isNull player };
        player allowDamage false;           // Rend le joueur invulnérable pendant l'intro

        // ==============================================================================================
        // SECTION 2 : EFFETS DE POST-PROCESSING (PP)
        // ==============================================================================================
        // Les effets PP modifient le rendu final de l'image pour créer une atmosphère cinématique
        
        // ----------------------------------------------------------------------------------------------
        // EFFET DE CORRECTION COULEUR (ColorCorrections)
        // ----------------------------------------------------------------------------------------------
        // Paramètres : [intensité, luminosité, contraste, [mélange couleur ombres], 
        //              [mélange couleur hauts], [mélange couleur moyens]]
        private _ppColor = ppEffectCreate ["ColorCorrections", 1500];  // Priorité 1500
        _ppColor ppEffectEnable true;
        _ppColor ppEffectAdjust [
            1,                    // Intensité globale (1 = 100%)
            1.0,                  // Luminosité
            -0.05,                // Contraste (légèrement réduit pour un look cinéma)
            [0.2, 0.2, 0.2, 0.0], // Teinte des ombres (gris neutre)
            [0.8, 0.8, 0.9, 0.7], // Teinte des hautes lumières (léger bleu)
            [0.1, 0.1, 0.2, 0]    // Teinte des tons moyens
        ]; 
        _ppColor ppEffectCommit 0;  // Application immédiate (0 seconde de transition)

        // ----------------------------------------------------------------------------------------------
        // EFFET DE GRAIN DE FILM (FilmGrain)
        // ----------------------------------------------------------------------------------------------
        // Ajoute un grain subtil à l'image pour simuler une caméra de cinéma
        // Paramètres : [intensité, netteté, tailleGrain, intensitéRGB, monochromatique]
        private _ppGrain = ppEffectCreate ["FilmGrain", 2005];  // Priorité 2005
        _ppGrain ppEffectEnable true;
        _ppGrain ppEffectAdjust [0.1, 1, 1, 0.1, 1, false];  // Grain léger, couleur
        _ppGrain ppEffectCommit 0;

        // ==============================================================================================
        // SECTION 3 : DEFINITION DES CIBLES DE CAMERA
        // ==============================================================================================
        // Ces objets servent de points de référence pour les mouvements de caméra.
        // Si un objet n'existe pas, on utilise un fallback (joueur ou autre cible)
        
        // Cible 1 : Quartier Général Allié (pour le Plan 1)
        private _targetHQ = if (!isNil "batiment_officer") then { batiment_officer } else { player };
        
        // Cible 2 : Centre de la ville (pour le Plan 2 - départ)
        private _targetCityMid = if (!isNil "task_3_spawn_12") then { task_3_spawn_12 } else { _targetHQ };
        
        // Cible 3 : Fin de la ville (pour le Plan 2 - arrivée)
        private _targetCityEnd = if (!isNil "task_2_spawn_17") then { task_2_spawn_17 } else { _targetHQ };

        // ==============================================================================================
        // SECTION 4 : MUSIQUE D'INTRODUCTION
        // ==============================================================================================
        playMusic "00intro";   // Démarre la musique d'intro (définie dans description.ext)
        3 fadeSound 1;         // Remonte le volume à 100% en 3 secondes (fondu audio progressif)

        // ##############################################################################################
        // PLAN 1 : VUE AERIENNE DE LA VILLE (15 secondes)
        // ##############################################################################################
        // Description : Survol fluide de la ville avec affichage des crédits.
        // Séquence : 3s vue pure -> 5s texte auteur -> 1s pause -> 5s titre -> 1s pause
        
        private _targetCityMid = if (!isNil "task_3_spawn_12") then { task_3_spawn_12 } else { _targetHQ };
        private _targetCityEnd = if (!isNil "task_2_spawn_17") then { task_2_spawn_17 } else { _targetHQ };
        
        private _posCityStart = getPos _targetCityMid;
        
        // Création de la caméra
        private _cam = "camera" camCreate [(_posCityStart select 0), (_posCityStart select 1), 100];
        _cam cameraEffect ["INTERNAL", "BACK"];
        
        // Position de DEPART
        _cam camSetPos [(_posCityStart select 0) + 200, (_posCityStart select 1) - 200, 150];
        _cam camSetTarget _targetCityMid; 
        _cam camSetFov 0.65;
        _cam camCommit 0;
        waitUntil { camCommitted _cam };  // Attendre que la caméra soit en place
        
        // FAIRE APPARAITRE L'IMAGE (depuis le noir initial)
        cutText ["", "BLACK IN", 2];  // Fondu depuis le noir en 2 secondes
        
        // Démarrer le mouvement de caméra PENDANT le fondu
        private _posCityEnd = getPos _targetCityEnd;
        _cam camSetPos [(_posCityEnd select 0) + 80, (_posCityEnd select 1) + 80, 120];
        _cam camSetTarget _targetCityEnd;
        _cam camCommit 15; 
        
        // === PAUSE : 3 secondes pour admirer la vue (fondu + vue) ===
        sleep 3;
        
        // TEXTE 1 : Auteur & Présente (5 secondes)
        titleText [
            format [
                "<t size='1.6' color='#bbbbbb' font='PuristaMedium'>%1</t><br/>" +
                "<t size='1.2' color='#a0a0a0' font='PuristaLight'>%2</t>",
                localize "STR_INTRO_AUTHOR",
                localize "STR_INTRO_PRESENTS"
            ],
            "PLAIN", 1, true, true
        ];
        
        sleep 5;
        titleText ["", "PLAIN", 0.5];
        sleep 1;
        
        // TEXTE 2 : Titre de la Mission (5 secondes)
        titleText [
            format [
                "<t size='3.0' color='#ffffff' font='PuristaBold' shadow='2'>%1</t>",
                localize "STR_INTRO_TITLE"
            ],
            "PLAIN", 1, true, true
        ];
        
        sleep 5;
        titleText ["", "PLAIN", 0.5];

        // ##############################################################################################
        // PLAN 3 : VUE INTERIEURE DE L'HELICOPTERE (15 secondes)
        // ##############################################################################################
        // Description : Caméra à l'intérieur de l'hélicoptère regardant vers l'arrière (cargo).
        //               Mouvement progressif avec balancement subtil pour le réalisme.
        
        // ==============================================================================================
        // CORRECTION : OUVERTURE ROBUSTE DE LA RAMPE
        // ==============================================================================================
        private _heli = vehicle player; 

        // 1. On utilise remoteExec avec l'argument 'true' (JIP) pour forcer la synchro même en cas de lag
        // Le Huron utilise principalement "Door_Rear_Source"
        [_heli, ["Door_Rear_Source", 1]] remoteExec ["animateSource", 0, true];
        
        // 2. Sécurité : On force aussi l'animation "Ramp" qui est parfois utilisée par certaines variantes
        [_heli, ["Ramp", 1]] remoteExec ["animateSource", 0, true];

        // 3. Petite pause pour laisser le moteur initier l'animation avant de détacher la caméra
        sleep 0.1;

        // Détacher la caméra de toute attache précédente
        detach _cam;
        
        // Transition visuelle
        sleep 1;
        cutText ["", "BLACK FADED", 1];  // Fondu vers le noir en 1s
        sleep 1;
        cutText ["", "BLACK IN", 1];       // Fondu depuis le noir en 1s
        // ----------------------------------------------------------------------------------------------
        // TEXTE : SOUS-TITRE
        // ----------------------------------------------------------------------------------------------
        [
            format [
                "<t size='1.4' color='#dddddd' font='PuristaLight'>%1</t>",
                localize "STR_INTRO_SUBTITLE"
            ],
            -1, 
            safeZoneY + safeZoneH - 0.2,  // Bas de l'écran
            6, 
            1, 
            0, 
            791
        ] spawn BIS_fnc_dynamicText;
        
        // ----------------------------------------------------------------------------------------------
        // AJUSTEMENT PP POUR L'INTERIEUR : Plus sombre, plus contrasté
        // ----------------------------------------------------------------------------------------------
        _ppColor ppEffectAdjust [0.9, 1.2, -0.1, [0.3, 0.3, 0.3, 0.1], [0.7, 0.7, 0.8, 0.6], [0.2, 0.2, 0.3, 0.1]]; 
        _ppColor ppEffectCommit 1;
        // Augmentation du grain pour une atmosphère plus immersive
        _ppGrain ppEffectAdjust [0.15, 1.2, 1.2, 0.15, 1.2, false];
        _ppGrain ppEffectCommit 1;

        // ----------------------------------------------------------------------------------------------
        // CAMERA FIXE INTERIEURE
        // ----------------------------------------------------------------------------------------------
        // Position fixe au fond de l'hélicoptère (cargo arrière), regardant vers l'avant (cockpit)
        // Pour le CH-67 Huron (B_Heli_Transport_03_F), ces valeurs placent la caméra au fond du cargo
        
        // Position relative par rapport au centre de l'hélicoptère :
        // X = 0 : centré latéralement
        // Y = -3 : 3 mètres vers l'arrière (fond du cargo)
        // Z = -0.5 : légèrement sous le niveau des sièges pour une vue immersive
        private _fixedPos = [0, -3, -0.5];
        
        // Attacher la caméra à l'hélicoptère (elle suivra ses mouvements automatiquement)
        _cam attachTo [_heli, _fixedPos];
        
        // Orientation : regarder vers l'AVANT de l'hélicoptère (vers le cockpit)
        // [0, 1, 0] = Direction positive sur l'axe Y (avant de l'hélico)
        // [0, 0, 1] = Vecteur "haut" standard (axe Z vers le haut)
        _cam setVectorDirAndUp [[0, 1, 0], [0, 0, 1]];
        
        // Champ de vision légèrement large pour voir l'intérieur du cargo
        _cam camSetFov 0.9;
        _cam camCommit 0;
        
        // Attendre la durée du plan (15 secondes)
        sleep 15;

        // ##############################################################################################
        // PLAN 4 : VUE ORBITALE EXTERIEURE (14 secondes)
        // ##############################################################################################
        // Description : La caméra orbite autour de l'hélicoptère en vol, offrant une vue 
        //               spectaculaire de l'appareil et du paysage. Rotation fluide avec easing.
        
        detach _cam;  // Détacher la caméra de l'hélicoptère
        
        // Transition visuelle
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        cutText ["", "BLACK IN", 1];
        
        // ----------------------------------------------------------------------------------------------
        // REINITIALISATION PP POUR L'EXTERIEUR : Plus lumineux, moins de grain
        // ----------------------------------------------------------------------------------------------
        _ppColor ppEffectAdjust [1, 1.0, -0.05, [0.2, 0.2, 0.2, 0.0], [0.8, 0.8, 0.9, 0.7], [0.1, 0.1, 0.2, 0]]; 
        _ppColor ppEffectCommit 1;
        _ppGrain ppEffectAdjust [0.05, 0.8, 0.8, 0.05, 0.8, false];
        _ppGrain ppEffectCommit 1;
        
        // Variables de timing pour l'orbite
        private _orbStartTime = time;
        private _orbDuration = 14;
        private _orbitAngle = -90;  // Angle initial : côté gauche de l'hélico
        
        // Configuration initiale pour un mouvement fluide
        private _updateInterval = 0.1;  // Intervalle de mise à jour (100ms)
        private _commitTime = 0.5;      // Temps de transition entre positions (plus long = plus fluide)
        
        while { time < _orbStartTime + _orbDuration } do {
            private _progress = (time - _orbStartTime) / _orbDuration;
            
            // -----------------------------------------------------------------------------------------
            // CALCUL DE L'ANGLE D'ORBITE AVEC EASING
            // -----------------------------------------------------------------------------------------
            // Rotation de -90° à +45° (total 135°) avec fonction sinus pour un mouvement fluide
            _orbitAngle = -90 + (_progress * 135);
            
            // -----------------------------------------------------------------------------------------
            // DISTANCE ET HAUTEUR DYNAMIQUES (simplifiées pour moins de saccades)
            // -----------------------------------------------------------------------------------------
            // Distance : de 35m à 25m (rapprochement linéaire progressif)
            private _distance = 35 - (_progress * 10);
            
            // Hauteur : fixe pour éviter les oscillations saccadées
            private _height = 12;
            
            // -----------------------------------------------------------------------------------------
            // CALCUL DE LA POSITION ORBITALE
            // -----------------------------------------------------------------------------------------
            private _heliPos = getPosATL _heli;
            private _heliDir = getDir _heli;
            private _finalAngle = _heliDir + _orbitAngle;
            
            // Conversion polaire -> cartésienne pour la position de la caméra
            private _camX = (_heliPos select 0) + (sin _finalAngle * _distance);
            private _camY = (_heliPos select 1) + (cos _finalAngle * _distance);
            private _camZ = (_heliPos select 2) + _height;
            
            // -----------------------------------------------------------------------------------------
            // CIBLE FIXE SUR L'HELICOPTERE (sans décalage pour éviter les tremblements)
            // -----------------------------------------------------------------------------------------
            _cam camSetPos [_camX, _camY, _camZ];
            _cam camSetTarget _heli;
            _cam camSetFov 0.75;
            _cam camCommit _commitTime;  // Temps de transition plus long pour fluidité
            
            sleep _updateInterval;  // Fréquence de mise à jour réduite
        };

       // ##############################################################################################
        // PLAN 5 : VUE AERIENNE PLONGEANTE SUR LE QG - ✅ MODIFIÉ
        // ##############################################################################################
        
        detach _cam;
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        
        private _qgPos = if (!isNil "QG_Center") then { getPos QG_Center } else { getPos vehicles_spawner };
        
        private _aerialCamPos = [
            (_qgPos select 0),
            (_qgPos select 1) - 90,
            (_qgPos select 2) + 35
        ];
        
        _cam camSetPos _aerialCamPos;
        _cam camSetTarget _qgPos;
        _cam camSetFov 0.55;
        _cam camCommit 0;
        waitUntil { camCommitted _cam };
        
        cutText ["", "BLACK IN", 1];
        
        private _rampOpened = false;
        private _plan5StartTime = time;
        
        while { !isTouchingGround _heli && (getPos _heli select 2) > 1 } do {
            
            // ✅ MOUVEMENT AMPLIFIÉ : Oscillations et descente plus prononcées
            private _progress = (time - _plan5StartTime) / 10;
            private _newCamPos = [
                (_qgPos select 0) + (sin (time * 5) * 12),
                (_qgPos select 1) - 90 + (cos (time * 5) * 12),
                (_qgPos select 2) + 35 - (_progress * 11.7)
            ];
            _cam camSetPos _newCamPos;
            _cam camSetFov (0.55 + (_progress * 0.15));  // Au lieu de 0.1 - zoom out plus prononcé
            _cam camCommit 0.5;
            
            // Ouverture de la rampe
            _heli animateSource ["door_rear_source", 1];
            // Remplacement pour les lignes 91 à 94
            if (!_rampOpened && (getPos _heli select 2) < 30) then {
                // Force l'ouverture de la rampe arrière (Huron spécifique) sur toutes les machines
                [_heli, ["Door_Rear_Source", 1]] remoteExec ["animateSource", 0, true];
                
                // Sécurité : Force aussi l'animation "Ramp" qui existe sur certaines variantes
                [_heli, ["Ramp", 1]] remoteExec ["animateSource", 0, true];
                
                _rampOpened = true;
            };
            
            sleep 0.2;
        };
        
        sleep 2;
        
        // ----------------------------------------------------------------------------------------------
        // FONDU FINAL ET ATTENTE DU JOUEUR
        // ----------------------------------------------------------------------------------------------
        cutText ["", "BLACK FADED", 1.5];
        
        // Attendre que le joueur sorte de l'hélicoptère
        waitUntil { vehicle player == player };
        
        sleep 1;

        // ##############################################################################################
        // FIN DE LA CINEMATIQUE : NETTOYAGE ET RESTAURATION
        // ##############################################################################################
        
        // Fondu final vers le noir
        cutText ["", "BLACK FADED", 1];
        sleep 1;

        // ----------------------------------------------------------------------------------------------
        // NETTOYAGE DES OBJETS CINEMATIQUES
        // ----------------------------------------------------------------------------------------------
        _cam cameraEffect ["TERMINATE", "BACK"];  // Désactive l'effet caméra
        camDestroy _cam;                          // Détruit l'objet caméra
        ppEffectDestroy _ppColor;                 // Supprime l'effet de correction couleur
        ppEffectDestroy _ppGrain;                 // Supprime l'effet de grain
        
        // ----------------------------------------------------------------------------------------------
        // RESTAURATION DU JOUEUR
        // ----------------------------------------------------------------------------------------------
        player switchCamera "INTERNAL";  // Retour à la vue première personne
        showCinemaBorder false;          // Masque les bandes noires
        player allowDamage true;         // Le joueur peut à nouveau subir des dégâts

        // DEBLOCAGE COMPLET DES CONTROLES
        // Triple appel pour garantir le déblocage (technique Arma 3)
        disableUserInput false;
        disableUserInput true;
        disableUserInput false;

        // Fondu depuis le noir vers le jeu normal
        cutText ["", "BLACK IN", 3];  // Augmenté à 3 secondes pour une transition plus douce

        // ----------------------------------------------------------------------------------------------
        // TEXTE FINAL : DEBUT DE MISSION
        // ----------------------------------------------------------------------------------------------
        [
            format [
                "<t size='2.0' color='#ffffff' font='PuristaBold'>%1</t><br/>" +
                "<t size='1.3' color='#cccccc' font='PuristaLight'>%2</t>",
                localize "STR_MISSION_START",          // "Mission commencée" ou équivalent
                localize "STR_MISSION_START_SUBTITLE"  // Sous-titre
            ],
            -1,   // Centré X
            -1,   // Centré Y
            5,    // Durée : 5 secondes
            1,    // Fondu entrée
            0,    // Fondu sortie
            793   // ID calque
        ] spawn BIS_fnc_dynamicText;
        
        // Signale à tous les clients et au serveur que l'intro est terminée
        missionNamespace setVariable ["MISSION_intro_finished", true, true];
    };
};

// ==================================================================================================
// PARTIE SERVEUR - Gestion du vol de l'hélicoptère d'introduction
// ==================================================================================================
// Cette partie ne s'exécute QUE sur le serveur. Elle gère :
// - La création de l'hélicoptère et de son équipage
// - Le chargement des joueurs à bord
// - Le pilotage automatique vers la zone de mission
// - L'atterrissage et le débarquement des joueurs
// - Le départ et la suppression de l'hélicoptère

if (isServer) then {
    [] spawn {
        // Attendre que les données de configuration soient chargées
        waitUntil {!isNil "MISSION_var_helicopters" };   // Liste des hélicoptères disponibles
        waitUntil {!isNil "MISSION_var_model_player" };   // Modèle du joueur (pour les équipements)

        // ----------------------------------------------------------------------------------------------
        // RECUPERATION DES DONNEES DE L'HELICOPTERE
        // ----------------------------------------------------------------------------------------------
        // Recherche de l'hélicoptère marqué "task_x_helicoptere" dans la liste des hélicoptères
        private _heliData = [];
        { 
            if ((_x select 0) == "task_x_helicoptere") exitWith { _heliData = _x; }; 
        } forEach MISSION_var_helicopters;
        
        // Si aucun hélicoptère configuré, on skip l'intro et on marque comme terminée
        if (count _heliData == 0) exitWith { 
            missionNamespace setVariable ["MISSION_intro_finished", true, true];
        };

        // ----------------------------------------------------------------------------------------------
        // CALCUL DES POSITIONS DE DEPART ET D'ARRIVEE
        // ----------------------------------------------------------------------------------------------
        private _destPos = getPosATL vehicles_spawner;  // Position de la zone d'atterrissage
        
        // Position de départ : 1300m de distance, direction aléatoire, à 200m d'altitude
        private _startDist = 1300; 
        private _startDir = random 360;  // Direction aléatoire (pour varier les entrées)
        private _startPos = vehicles_spawner getPos [_startDist, _startDir];
        _startPos set [2, 200];  // Force l'altitude à 200m

        // ----------------------------------------------------------------------------------------------
        // CREATION DE L'HELICOPTERE
        // ----------------------------------------------------------------------------------------------
        private _heliClass = _heliData select 1;  // Classe de l'hélicoptère (ex: "B_Heli_Transport_01_F")
        
        // Création en mode vol
        private _heli = createVehicle [_heliClass, _startPos, [], 0, "FLY"];
        _heli setPos _startPos;
        _heli setDir (_heli getDir _destPos);  // Orienter vers la destination
        _heli flyInHeight 150;                  // Altitude de croisière
        _heli allowDamage false;                // Invulnérable pendant l'intro
        

        // ----------------------------------------------------------------------------------------------
        // CREATION ET CONFIGURATION DE L'EQUIPAGE
        // ----------------------------------------------------------------------------------------------
        createVehicleCrew _heli;  // Crée automatiquement pilote et copilote
        private _crew = crew _heli;
        { _x allowDamage false; } forEach _crew;  // Équipage invulnérable
        
        // Application de l'équipement du modèle joueur à l'équipage (pour cohérence visuelle)
        private _modelPlayerData = [];
        { if ((_x select 0) == "model_player") exitWith { _modelPlayerData = _x; }; } forEach MISSION_var_model_player;
        
        if (count _modelPlayerData > 0) then {
            { _x setUnitLoadout (_modelPlayerData select 5); } forEach _crew;
        };
        
        // Configuration du comportement du groupe hélico
        private _grpHeli = group driver _heli;
        _grpHeli setBehaviour "CARELESS";  // Ignore les menaces (pas d'esquive)
        _grpHeli setCombatMode "BLUE";     // Ne jamais engager (mode passif total)

        // ----------------------------------------------------------------------------------------------
        // EMBARQUEMENT DES JOUEURS ET DE LEURS GROUPES I.A.
        // ----------------------------------------------------------------------------------------------
        // Cette section embarque :
        // 1. Tous les joueurs connectés au serveur (playableUnits)
        // 2. Toutes les unités I.A. appartenant aux groupes des joueurs
        
        private _players = playableUnits;
        // En solo, playableUnits peut être vide, donc on ajoute le joueur local
        if (count _players == 0 && hasInterface) then { _players = [player]; };
        
        // Collecter toutes les unités à embarquer (joueurs + I.A. de leurs groupes)
        private _allUnitsToBoard = [];
        private _processedGroups = [];  // Pour éviter de traiter le même groupe plusieurs fois
        
        // Parcourir tous les joueurs pour récupérer leurs groupes
        {
            private _playerUnit = _x;
            private _playerGroup = group _playerUnit;
            
            // Vérifier si ce groupe n'a pas déjà été traité
            if !(_playerGroup in _processedGroups) then {
                _processedGroups pushBack _playerGroup;
                
                // Ajouter toutes les unités du groupe (joueurs ET I.A.)
                {
                    if (alive _x && !(_x in _allUnitsToBoard)) then {
                        _allUnitsToBoard pushBack _x;
                    };
                } forEach (units _playerGroup);
            };
        } forEach _players;
        
        // Ajouter aussi les joueurs qui ne sont peut-être pas dans un groupe standard
        {
            if (alive _x && !(_x in _allUnitsToBoard)) then {
                _allUnitsToBoard pushBack _x;
            };
        } forEach _players;
        
        // Embarquer toutes les unités collectées
        {
            private _unit = _x;
            
            // Application de l'équipement si disponible
            if (count _modelPlayerData > 0) then { _unit setUnitLoadout (_modelPlayerData select 5); };
            
            // Placement dans l'hélicoptère (cargo en priorité)
            _unit moveInCargo _heli;
            
            // Fallback si le cargo est plein : essayer n'importe quel siège disponible
            if (vehicle _unit == _unit) then { _unit moveInAny _heli; };
            
            // Assigner comme cargo
            _unit assignAsCargo _heli;
            
        } forEach _allUnitsToBoard;
        
        // Log pour debug (optionnel - décommenter si besoin)
        // systemChat format ["INTRO: %1 unités embarquées dans l'hélicoptère", count _allUnitsToBoard];

        sleep 1;  // Petit délai pour stabilisation

        // ##############################################################################################
        // PHASES DE VOL SYNCHRONISEES AVEC LES PLANS CAMERA
        // ##############################################################################################
        
        // ----------------------------------------------------------------------------------------------
        // PHASE 1 : Approche rapide (Plans 1+2 de la caméra = 14 secondes)
        // ----------------------------------------------------------------------------------------------
        _heli doMove _destPos;     // Ordre de déplacement vers la destination
        _heli flyInHeight 150;     // Maintenir 150m d'altitude
        _heli limitspeed 200;      // Vitesse élevée pour l'approche

        sleep 14;  // Durée des Plans 1+2

        // ----------------------------------------------------------------------------------------------
        // PHASE 2 : Vol intermédiaire (Plan 3 = 15 secondes)
        // ----------------------------------------------------------------------------------------------
        // L'hélico continue vers la destination pendant la vue intérieure
        sleep 15;

        // ----------------------------------------------------------------------------------------------
        // PHASE 3 : Approche finale (Plan 4 = 14 secondes)
        // ----------------------------------------------------------------------------------------------
        _heli limitspeed 120;  // Ralentissement pour l'approche finale
        
        sleep 14;

        // ----------------------------------------------------------------------------------------------
        // PHASE 4 : Atterrissage (Plan 5)
        // ----------------------------------------------------------------------------------------------
        // Attendre d'être proche de la LZ
        waitUntil { (_heli distance2D _destPos) < 250 };
        
        // Ordre d'atterrissage avec débarquement automatique
        _heli land "GET OUT";
        
        // Attendre le poser (altitude < 2m)
        waitUntil { (getPos _heli) select 2 < 2 };
        
        sleep 1;
        
        // ----------------------------------------------------------------------------------------------
        // DEBARQUEMENT SECURISE DES JOUEURS ET DE LEURS GROUPES I.A.
        // ----------------------------------------------------------------------------------------------
        // Éjecter chaque joueur ET ses unités I.A. groupées, puis les positionner autour de l'hélico
        
        // Collecter toutes les unités à débarquer (même logique que l'embarquement)
        private _unitsToDisembark = [];
        private _processedGroupsDisembark = [];
        
        {
            private _playerUnit = _x;
            private _playerGroup = group _playerUnit;
            
            if !(_playerGroup in _processedGroupsDisembark) then {
                _processedGroupsDisembark pushBack _playerGroup;
                
                // Ajouter toutes les unités du groupe (joueurs + I.A.)
                {
                    if (alive _x && vehicle _x == _heli && !(_x in _unitsToDisembark)) then {
                        _unitsToDisembark pushBack _x;
                    };
                } forEach (units _playerGroup);
            };
        } forEach _players;
        
        // Variable pour espacer les unités lors du débarquement
        private _unitIndex = 0;
        
        {
            private _unit = _x;
            
            moveOut _unit;              // Forcer la sortie du véhicule
            unassignVehicle _unit;      // Désassigner du véhicule
            
            // Positionner les unités en arc autour du côté droit de l'hélico
            private _dir = getDir _heli;
            private _dist = 6 + (_unitIndex mod 3);  // Distance variable : 6, 7, 8m
            private _angleOffset = 70 + (_unitIndex * 12);  // Arc de 70° à ~210° (côté droit en éventail)
            
            private _pos = _heli getPos [_dist, _dir + _angleOffset];
            _pos set [2, 0];  // Forcer au niveau du sol
            _unit setPos _pos;
            _unit setDir _dir;   // Orienter dans la même direction que l'hélico
            
            _unitIndex = _unitIndex + 1;
        } forEach _unitsToDisembark;
        
        sleep 5;  // Pause pour permettre au joueur de s'orienter
        _heli animateSource ["door_rear_source", 0];
        // ----------------------------------------------------------------------------------------------
        // DEPART DE L'HELICOPTERE
        // ----------------------------------------------------------------------------------------------
        _heli land "NONE";  // Annuler l'ordre d'atterrissage
        
        // Définir une position de sortie à 3km dans la direction d'origine
        private _exitPos = _destPos getPos [3000, _startDir];
        _heli doMove _exitPos;
        _heli flyInHeight 200;
        _heli limitspeed 300;  // Vitesse maximale pour le départ
        
        // ----------------------------------------------------------------------------------------------
        // NETTOYAGE FINAL
        // ----------------------------------------------------------------------------------------------
        sleep 60;  // Attendre que l'hélico soit hors de vue
        
        // Supprimer l'équipage et l'hélicoptère pour libérer les ressources
        { deleteVehicle _x } forEach _crew;
        deleteVehicle _heli;
    };
};