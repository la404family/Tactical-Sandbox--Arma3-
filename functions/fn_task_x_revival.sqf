/*
    File: fn_task_x_revival.sqf
    Author: la404family
    Description:
    Toutes les 60 secondes, vérifie si le joueur est chef de groupe et a des IA.
    Si oui, ajoute une action pour ordonner aux IA de se soigner.
*/

if (!hasInterface) exitWith {};

[] spawn {
    while {true} do {
        private _id = player getVariable ["HealActionID", -1];
        private _isLeader = (leader group player) == player;
        private _hasAI = ({!isPlayer _x} count (units group player)) > 0;

        if (_isLeader && _hasAI) then {
            if (_id == -1) then {
                _id = player addAction [
                    localize "STR_ACTION_HEAL_YOURSELVES",
                    {
                        params ["_target", "_caller", "_actionId", "_arguments"];
                        {
                            if (alive _x && !isPlayer _x && damage _x > 0) then {
                                _x action ["HealSoldierSelf", _x];
                            };
                        } forEach (units group _caller);
                    },
                    nil,
                    1.5, 
                    false, 
                    true
                ];
                player setVariable ["HealActionID", _id];
            };
        } else {
            if (_id != -1) then {
                player removeAction _id;
                player setVariable ["HealActionID", -1];
            };
        };

        sleep 60;
    };
};
