//-------------------------------------------
// Les éléments de préparation de mission :
//-------------------------------------------

// marker_de_zone_1 est un marker qui affiche la "zone du choix des armes"
// marker_de_zone_2 est un marker qui affiche la "zone du choix de mission"
// marker_de_zone_3 est un marker qui affiche la "zone du choix de l'équipe"
// marker_de_zone_4 est un marker qui affiche la "zone du choix du véhicule"
// marker_de_zone_5 est un marker qui affiche la "zone du choix du temps"

// brothers_in_arms_request est un trigger (lorsqu'on y entre on peut choisir l'équipe)
// brothers_in_arms_spawner est un héliport invisible (lieu d'apparition des membres de l'équipe)

// vehicles_request est un trigger (lorsqu'on y entre on peut choisir le véhicule)
// vehicles_spawner est un héliport invisible (lieu d'apparition du véhicule)
// arsenal_request est un trigger (lorsqu'on y entre on peut choisir l'arsenal)

// missions_request est un trigger (lorsqu'on y entre on peut choisir la mission et ses paramètres)
// weather_and_time_request est un trigger (lorsqu'on y entre on peut choisir l'heure et le temps)

// expel_spawn est un trigger (lorsqu'on y entre on est expulser du trigger)

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
// fonction qui spawn les taches séléctionnées
["INIT"] call MISSION_fnc_spawn_missions;
// fonction qui expulse les joueurs du spawn
[] spawn MISSION_fnc_expel_spawn;

//-------------------------------------------
// Les éléments du QG allié :
//-------------------------------------------

// officier_task_giver est un officier qui donne la tache (et doit rester en vie)
// batiment_officer est le batiment où se trouve officier_task_giver

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

//-------------------------------------------
// Les éléments de la tache 1 : (spawn a positionner sur des routes)
//-------------------------------------------

// task_1_spawn_01 à task_1_spawn_06 sont des héliports qui servent de lieux de spawn ennemi pour la tache 1

//-------------------------------------------
// Les éléments de la tache 2 : (spawn a positionner autours de bâtiments)
//-------------------------------------------

// task_2_spawn_01 à task_2_spawn_06 sont des héliports qui servent de lieux de spawn ennemi pour la tache 2
// task_2_document est un document à récupérer dans l'inventaire de l'officier ennemis

//-------------------------------------------
// Les éléments de la tache 3 : (spawn a positionner dans des zones couvertes)
//-------------------------------------------

// task_3_spawn_01 à task_3_spawn_12 sont des héliports qui servent de lieux de spawn pour la tache 3
// task_3_spawn_01 fait apparaitre un avion allié : A149 Gryphon (EMP_A149_Gryphon)
// task_3_spawn_02 à task_  3_spawn_12 fait apparaître des ennemis aléatoirement :
//          task_x_officer_1 à task_x_officer_3 sont les officiers ennemis
//          task_x_enemy_00 à task_x_enemy_15 sont des unités ennemies
//          task_x_vehicle_1 et task_x_vehicle_2 sont les véhicules ennemis
//          task_x_tank_1 est le tank ennemi

//-------------------------------------------
// Les éléments de la tache 4 : spawn a positionner dans des batiments
//-------------------------------------------

// task_4_spawn_01 et task_4_spawn_07 fait apparaître deux civils  (task_x_civil_01 et task_x_civil_02 sont les civils dans fn_task_x_memory)
// task_4_spawn_01 à task_4_spawn_07 sont des héliports qui servent de lieux de spawn ennemi pour la tache 4
// task_x_helicoptere est un hélicoptère  qui vient chercher les civils 
// task_4_spawn_08 à task_4_spawn_12 sont des héliports qui servent de lieux de pose de l'hélicoptère

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
// Les fonctions de tache :
//-------------------------------------------

// mise en memoire et suppression des unités ennemies
["SAVE"] call MISSION_fnc_task_x_memory;
// application de la tache 1 (attaque du QG allié) - Lancé via le menu missions
// [] call MISSION_fnc_task_1_launch;
// application de la tache 2 (assassinat et récupération) - Lancé via le menu missions
// [] call MISSION_fnc_task_2_launch;
// application de la tache 3 (guerre totale) - Lancé via le menu missions
// [] call MISSION_fnc_task_3_launch;
// application de la tache 4 (exfiltration d'otage) - Lancé via le menu missions
// [] call MISSION_fnc_task_4_launch;
// application de la tache 5 (bombe) - Lancé via le menu missions
// [] call MISSION_fnc_task_5_launch;




