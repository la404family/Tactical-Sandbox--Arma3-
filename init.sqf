//-------------------------------------------
// Les éléments de préparation de mission :
//-------------------------------------------

// ==================================================================================================
// INITIALISATION IMMEDIATE (Blackout pour cacher le chargement)
// ==================================================================================================
if (hasInterface) then {
    cutText ["", "BLACK FADED", 999];
    0 fadeSound 0;
};

// marker_de_zone_1 est un marker qui affiche la "zone du choix des armes"
// marker_de_zone_2 est un marker qui affiche la "zone du choix de mission"
// marker_de_zone_3 est un marker qui affiche la "zone du choix de l'équipe"
// marker_de_zone_4 est un marker qui affiche la "zone du choix du véhicule"
// marker_de_zone_5 est un marker qui affiche la "zone du choix du temps"
// marker_de_zone_6 est un marker qui affiche la "zone du choix des ennemis"

// brothers_in_arms_request est un trigger (lorsqu'on y entre on peut choisir l'équipe)
// brothers_in_arms_spawner est un héliport invisible (lieu d'apparition des membres de l'équipe)

// vehicles_request est un trigger (lorsqu'on y entre on peut choisir le véhicule)
// vehicles_spawner est un héliport invisible (lieu d'apparition du véhicule)
// arsenal_request est un trigger (lorsqu'on y entre on peut choisir l'arsenal)
// missions_request est un trigger (lorsqu'on y entre on peut choisir la mission et ses paramètres)
// weather_and_time_request est un trigger (lorsqu'on y entre on peut choisir l'heure et le temps)
// enemies_request est un trigger (lorsqu'on y entre on peut choisir les ennemis)



//-------------------------------------------
// Les fonctions de préparation de mission :
//-------------------------------------------
// fonction qui traduit les noms des markers
[] call MISSION_fnc_lang_marker_name;
// fonction qui spawn un membre de l'équipe
["INIT"] call MISSION_fnc_spawn_brothers_in_arms;
// fonction qui spawn un véhicule
["INIT"] call MISSION_fnc_spawn_vehicles;
// fonction qui spawn le temps
["INIT"] call MISSION_fnc_spawn_weather_and_time;
// fonction qui spawn l'arsenal
["INIT"] call MISSION_fnc_spawn_arsenal;
// fonction qui gère les badges d'équipe
["INIT"] call MISSION_fnc_task_x_badge;
// fonction qui spawn les taches séléctionnées
["INIT"] call MISSION_fnc_spawn_missions;
// fonction qui spawn le menu des ennemis
["INIT"] call MISSION_fnc_spawn_ennemies;

// Lancement automatique de l'ajustement des skills I.A.
[] spawn MISSION_fnc_ajust_AI_skills;

// Lancement de la gestion du soin du groupe
[] spawn MISSION_fnc_task_x_revival;

//-------------------------------------------
// Les fonctions helper globales (pour le multijoueur) :
//-------------------------------------------

// Fonction pour créer un marqueur captif sur tous les clients
MISSION_fnc_createCaptiveMarker = {
    params ["_markerName", "_pos", "_text"];
    private _marker = createMarkerLocal [_markerName, _pos];
    _marker setMarkerTypeLocal "hd_dot";
    _marker setMarkerColorLocal "ColorBlue";
    _marker setMarkerTextLocal _text;
};

// Fonction pour ajouter l'action "Soumettre" sur un fugitif
MISSION_fnc_addSubmitAction = {
    params ["_fugitive", "_actionText"];
    
    if (isNull _fugitive) exitWith {};
    
    private _actionID = _fugitive addAction [
        _actionText,
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            
            // Marquer comme capturé (publicVariable via setVariable)
            _target setVariable ["isCaptured", true, true];
            
            // Retirer l'action sur ce client
            _target removeAction _actionId;
            
            // Supprimer le marqueur (locale)
            private _markerName = _target getVariable ["captiveMarker", ""];
            if (_markerName != "") then {
                deleteMarkerLocal _markerName;
            };
            
            // Notification finale (son + hint)
            playSound "3DEN_notificationDefault";
            hint (localize "STR_HINT_FUGITIVE_SURRENDERED");
        },
        nil,
        6,
        true,
        true,
        "",
        "alive _target && _this distance _target < 3"
    ];
};

//-------------------------------------------
// Les éléments du QG allié :
//-------------------------------------------

// batiment_officer est le batiment où se trouve officier_task_giver
// tableau_des_taches est le tableau qui affiche la tache en cours.
// chaise_0 à chaise_13 sont des chaises installées dans la salle de briefing
// briefing_request est un trigger (lorsqu'on y entre on peut organiser une réunion)


//-------------------------------------------
// Les éléments des communs aux taches :
//-------------------------------------------

// éléménts en mémoire (supprimés en début de mission) voir fn_task_x_memory
// task_x_officer_1 à task_x_officer_3 sont les officiers ennemis
// task_x_enemy_00 à task_x_enemy_15 sont des unités ennemies
// task_x_vehicle_1 et task_x_vehicle_2 sont les véhicules ennemis
// task_x_tank_1 est le tank ennemi
// task_x_civil_01 et task_x_civil_02 sont les civils
// task_x_helicoptere est un hélicoptère 
// task_x_explosif_00 est une charge explosive
// task_x_explosif_01 est une caisse d'explosif
// task_x_explosif_02 et task_x_explosif_03 sont des éclairages portatifs pour héliport (simule le signal visuel de la bombe)
// task_x_tank_2 est le tank ennemi type T-140K Angara
task_x_tank_2 = "O_T_MBT_04_command_F";
//-------------------------------------------
// Les éléments de la tache 1 : (spawn a positionner sur des routes)
//-------------------------------------------

// task_x_fugitif_1 à task_x_fugitif_3 sont les fugitifs en mémoire 
// task_1_spawn_01 à task_1_spawn_42  sont les héliports qui servent de lieux de passage pour les fugitifs
// task_1_spawn_01 à task_1_spawn_06 est un chemin 
// task_1_spawn_07 à task_1_spawn_12 est un chemin 
// task_1_spawn_13 à task_1_spawn_18 est un chemin 
// task_1_spawn_19 à task_1_spawn_24 est un chemin 
// task_1_spawn_25 à task_1_spawn_30 est un chemin 
// task_1_spawn_31 à task_1_spawn_36 est un chemin 
// task_1_spawn_37 à task_1_spawn_42 est un chemin 
// task_1_spawn_43 à task_1_spawn_48 est un chemin 
// task_1_boat_place_1 à task_1_boat_place_7 sont des héliports qui déterminent la position du bateau
// task_x_boat_1 à task_1_boat_7 sont des bateaux en mémoire.
// task_1_boat_direction_1 à task_1_boat_direction_7 sont des directions pour les bateaux


//-------------------------------------------
// Les éléments de la tache 2 : (spawn a positionner autours de bâtiments)
//-------------------------------------------

// task_2_spawn_01 à task_2_spawn_30 sont des héliports qui servent de lieux de spawn ennemi pour la tache 2
// task_2_document est un document à récupérer dans l'inventaire de l'officier ennemis

//-------------------------------------------
// Les éléments de la tache 3 : (spawn a positionner dans des zones couvertes)
//-------------------------------------------

// task_3_spawn_01 à task_3_spawn_18 sont des héliports qui servent de lieux de spawn pour la tache 3
// task_3_spawn_01 fait apparaitre un avion allié : A149 Gryphon (EMP_A149_Gryphon)
// task_3_spawn_02 à task_3_spawn_18 fait apparaître des ennemis aléatoirement :
//          task_x_officer_1 à task_x_officer_3 sont les officiers ennemis
//          task_x_enemy_00 à task_x_enemy_15 sont des unités ennemies
//          task_x_vehicle_1 et task_x_vehicle_2 sont les véhicules ennemis
//          task_x_tank_1 est le tank ennemi

//-------------------------------------------
// Les éléments de la tache 4 : spawn a positionner dans des batiments
//-------------------------------------------

// task_4_spawn_01 et task_4_spawn_12 fait apparaître deux civils  (task_x_civil_01 et task_x_civil_02 sont les civils dans fn_task_x_memory)
// task_4_spawn_01 à task_4_spawn_12 sont des héliports qui servent de lieux de spawn ennemi pour la tache 4
// task_x_helicoptere est un hélicoptère  qui vient chercher les civils 
// task_4_spawn_13 à task_4_spawn_18 sont des héliports qui servent de lieux de pose de l'hélicoptère

//-------------------------------------------
// Les éléments de la tache 5 : spawn a positionner dans des batiments
//-------------------------------------------

// task_5_spawn_01 à task_5_spawn_09 sont des héliports qui servent de lieux de spawn pour la première bombe
// task_5_spawn_11 à task_5_spawn_19 sont des héliports qui servent de lieux de spawn pour la deuxième bombe
// Chaque bombe est composé de :
//          task_x_explosif_00 est une charge explosive
//          task_x_explosif_01 est une caisse d'explosif
//          task_x_explosif_02 et task_x_explosif_03 sont des éclairages portatifs pour héliport (simule le signal visuel de la bombe)
// task_5_spawn_10 permet de situer la ville de présence civile.

//-------------------------------------------
// Les éléments de la tache 6 : utilise les spawn de la tache 1
//-------------------------------------------

// tache 6 récupère des éléments de la tache 1
// task_1_spawn_02 à task_1_spawn_04 
// task_1_spawn_06 à task_1_spawn_10 
// task_1_spawn_12 à task_1_spawn_16 
// task_1_spawn_18 à task_1_spawn_22 
// task_1_spawn_24 à task_1_spawn_28 
// task_1_spawn_30 à task_1_spawn_34 
// task_1_spawn_36 à task_1_spawn_40  
// task_1_spawn_42 à task_1_spawn_46 

//-------------------------------------------
// Les éléments de la tache 7 : spwawn a positionner dans une zone montagneuse
//-------------------------------------------

// task_7_spawn_1 à task_7_spawn_7 sont des héliports qui servent de lieux de spawn pour les ennemis de la tache 7
// task_7_spawn_8 à task_7_spawn_14 sont des héliports qui servent de lieux de spawn pour les radar à détruire

//-------------------------------------------
// Les éléments de la tache 8 : spwawn a positionner dans une zone montagneuse
//-------------------------------------------

// task_8_spawn_1 est le lieux de spawn pour l'équipe allié 1 de la tache 8 (héliport invisible)
// task_8_spawn_2 est le lieux de spawn pour l'équipe allié 2 de la tache 8 (héliport invisible)
// task_8_spawn_3 est le lieux de spawn pour l'équipe allié 3 de la tache 8 (héliport invisible)
// task_8_spawn_4 est le lieux de spawn pour les ennemis de la tache 8 (héliport invisible)
// task_8_spawn_5 à task_8_spawn_10 sont les lieux de spawn pour les tanks ennemis (héliport invisible)
// task_3_spawn_01 fait apparaitre un avion allié : A149 Gryphon (EMP_A149_Gryphon)
// task_8_spawn_11 est le lieux de spawn pour l'officier ennemi (héliport invisible)
// task_8_spawn_12 et task_8_spawn_13 sont les lieux de spawn pour les unités ennemies (protection de l'officier)
// task_8_spawn_14  à task_8_spawn_43 sont les lieux de passages des équipes alliés et ennemies des spawn 1 à 4

//-------------------------------------------
// Les fonctions de tache :
//-------------------------------------------

// mise en memoire et suppression des unités ennemies
["SAVE"] call MISSION_fnc_task_x_memory;
// application de la tache 1 (fugitif) - Lancé via le menu missions
// [] call MISSION_fnc_task_1_launch;
// application de la tache 2 (assassinat et récupération) - Lancé via le menu missions
// [] call MISSION_fnc_task_2_launch;
// application de la tache 3 (destruction de cargaisons) - Lancé via le menu missions
// [] call MISSION_fnc_task_3_launch;
// application de la tache 4 (exfiltration d'otage) - Lancé via le menu missions
// [] call MISSION_fnc_task_4_launch;
// application de la tache 5 (bombe) - Lancé via le menu missions
// [] call MISSION_fnc_task_5_launch;
// application de la tache 6 (secours alliés) - Lancé via le menu missions
// [] call MISSION_fnc_task_6_launch;
// application de la tache 7 (destruction de radar) - Lancé via le menu missions
// [] call MISSION_fnc_task_7_launch;

//-------------------------------------------
// Les fonctions de tache : (A remettre à la fin du développement)
//-------------------------------------------
[] spawn MISSION_fnc_task_0_intro;
// fonction fn_task_x_tableau
[] call MISSION_fnc_task_x_tableau;
// fonction fn_task_x_briefing
[] spawn MISSION_fnc_task_x_briefing;

// toutes les 5 secondes on vérifie si le joueur est en vie et leader : [] call MISSION_fnc_ajust_change_team_leader;
[] spawn {
    while {true} do {
        sleep 5;
        [] call MISSION_fnc_ajust_change_team_leader;
    };
};

