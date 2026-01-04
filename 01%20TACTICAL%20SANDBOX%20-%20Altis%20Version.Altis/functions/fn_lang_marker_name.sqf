/*
    Description :
    Cette fonction se charge de localiser les noms des marqueurs sur la carte en fonction de la langue du client.
    Elle utilise les clés définies dans le fichier stringtable.xml.
*/

// Vérifie si l'instance est une machine client (joueur) qui possède une interface.
// Si ce n'est pas le cas (ex: serveur dédié), la fonction s'arrête ici pour économiser des ressources.
if (!hasInterface) exitWith {};

// Applique le texte localisé pour chaque marqueur de zone spécifique.
// "localize" récupère la traduction correspondante à la clé donnée (ex: "STR_MARKER_ZONE_1").
"marker_de_zone_1" setMarkerTextLocal (localize "STR_MARKER_ZONE_1");
"marker_de_zone_2" setMarkerTextLocal (localize "STR_MARKER_ZONE_2");
"marker_de_zone_3" setMarkerTextLocal (localize "STR_MARKER_ZONE_3");
"marker_de_zone_4" setMarkerTextLocal (localize "STR_MARKER_ZONE_4");
"marker_de_zone_5" setMarkerTextLocal (localize "STR_MARKER_ZONE_5");
"marker_de_zone_6" setMarkerTextLocal (localize "STR_MARKER_ZONE_6");
