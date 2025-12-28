# 🎮 Mission Arma 3 - Multi-Tâches SP/COOP

![SQF Wallpaper](SQFWallpaper.jpg)

> Mission dynamique avec système de sélection de tâches, recrutement d'alliés, spawn de véhicules et contrôle météo.

---

## 📋 Fonctionnalités Implémentées

| Fonction | Description | Zone Trigger |
|----------|-------------|--------------|
| `fn_spawn_missions` | Menu de sélection des missions avec 20 tâches | `missions_request` |
| `fn_spawn_brothers_in_arms` | Recrutement d'unités IA alliées | `brothers_in_arms_request` |
| `fn_spawn_vehicles` | Spawn de véhicules (pas de bateaux/avions) | `vehicles_spawner` |
| `fn_spawn_weather_and_time` | Contrôle du temps et de la météo | `weather_and_time_request` |
| `fn_spawn_arsenal` | Accès à l'arsenal virtuel | `arsenal_request` |


---

## 🔧 Comment Ajouter une Nouvelle Tâche

### Étape 1 : Ajouter les textes localisés

Dans `stringtable.xml`, ajoutez :

```xml
<Key ID="STR_TASK_2_TITLE">
    <English>Your Task Title</English>
    <French>Titre de votre tâche</French>
    ...
</Key>
<Key ID="STR_TASK_2_DESC">
    <English>Task description...</English>
    <French>Description de la tâche...</French>
    ...
</Key>
```

### Étape 2 : Créer la fonction de tâche

Créez `functions/fn_task_2_launch.sqf` :

```sqf
if (!isServer) exitWith {};

// Créer la tâche Arma 3
[
    true,
    ["task_2_your_id"],
    [localize "STR_TASK_2_DESC", localize "STR_TASK_2_TITLE", ""],
    objNull,      // Position ou objet cible
    "CREATED",
    1,
    true,
    "attack"      // Type: attack, defend, scout, etc.
] call BIS_fnc_taskCreate;

// Votre logique de mission ici...
```

### Étape 3 : Enregistrer dans description.ext

```cpp
class CfgFunctions {
    class MISSION {
        class Localization {
            file = "functions";
            class task_2_launch {};  // Ajouter cette ligne
        };
    };
};
```

### Étape 4 : Connecter au menu de missions

Dans `fn_spawn_missions.sqf`, modifiez :

```sqf
// Section SELECT (lignes ~70-77)
if (_taskNum == 2) then {
    _titleCtrl ctrlSetText (localize "STR_TASK_2_TITLE");
    _descCtrl ctrlSetText (localize "STR_TASK_2_DESC");
};

// Section LAUNCH (lignes ~120-127)
case 2: {
    [] call MISSION_fnc_task_2_launch;
};
```

---

## 📁 Structure des Fichiers

```
mission.sqm           # Fichier mission (éditeur)
init.sqf              # Initialisation
description.ext       # Configuration
stringtable.xml       # Localisation

functions/
├── fn_spawn_missions.sqf
├── fn_spawn_brothers_in_arms.sqf
├── fn_spawn_vehicles.sqf
├── fn_spawn_weather_and_time.sqf
├── fn_spawn_arsenal.sqf
├── fn_task_1_launch.sqf
├── fn_task_x_enemies_memory.sqf
└── fn_lang_marker_name.sqf

dialogs/
├── defines.hpp
├── missions_menu.hpp
├── recruit_menu.hpp
├── vehicle_menu.hpp
└── weather_time_menu.hpp
```

---

## 🌍 Langues Supportées

- 🇬🇧 English
- 🇫🇷 Français
- 🇬🇪 Deutsch
- 🇪🇸 Spanish
- 🇮🇹 Italiano
- 🇷🇺 Русский
- 🇵🇱 Polski
- 🇨🇿 Česky
- 🇹🇷 Türkçe
- 🇨🇳 中文
- 🇨🇳 简体中文

---

## 📝 Notes Techniques

- Toute la logique serveur utilise `isServer`
- Les textes UI sont dynamiques via `stringtable.xml`
- Compatible SP et COOP (1-5 joueurs)

### Types d’objectifs de mission à ajouter

- Extraction de VIP : Escorter un officier, scientifique ou informateur jusqu’à la base alliée.
- Récupération de personnel isolé : Secourir un prisonnier de guerre derrière les lignes ennemies.
- Assassinat et récupération de documents : Éliminer un officier ennemi de haut rang. + récuperation de documents dans son inventaire.
- Chasse à l’homme (HVT) : Traquer un commandant ennemi mobile entre plusieurs bases ou convois.
- Suppression de défenses : Neutraliser un radar anti-aérien pour permettre un soutien aérien allié.
- Destruction de convoi : Détruire un convoi de ravitaillement ou des véhicules ennemis lourds.
- Reconquête : Reprendre une base alliée (QG ennemie) tombée aux mains de l’ennemi.
- Récupération de renseignements : Infiltrer un QG ennemi pour pirater un ordinateur.
- Enquête mystérieuse : Explorer un laboratoire secret pour comprendre une anomalie.

**Options de mission**

- drone de reconnaissance (affiche les positions des unités ennemies)
- présence de tank ennemi 
- soutien aérien allié
- présence civile

**Besoins :** 
 - Officier allié (fait)
 - Officier ennemi avec documents (fait)
 - Officier ennemi mobile
 - QG ennemi (avec ordinateur à pirater)
 - QG allié
 - Radar anti-aérien
 - Convoie ennemie
 - laboratoire secret
