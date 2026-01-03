/*
    File: fn_ajust_AI_skills.sqf
    Author: Antigravity
    Description: Adjusts AI skills for OPFOR and BLUFOR units every minute.
*/

while {true} do {
    {
        if (alive _x) then {
            private _side = side _x;
            
            // OPFOR Adjustment
            if (_side == east) then {
                _x setSkill ["aimingAccuracy", 0.10 + random 0.15];   // 0.10 -> 0.25
                _x setSkill ["aimingShake",   0.10 + random 0.20];   // 0.10 -> 0.30
                _x setSkill ["aimingSpeed",   0.10 + random 0.30];   // 0.10 -> 0.40
                _x setSkill ["spotDistance",  0.10 + random 0.50];   // 0.10 -> 0.60
                _x setSkill ["spotTime",      0.10 + random 0.40];   // 0.10 -> 0.50
                _x setSkill ["courage", 1];
                _x setSkill ["reloadSpeed", 0.6];
                _x setSkill ["commanding", 0.4];
                _x setSkill ["general", 0.5];
                _x allowFleeing 0;
            };

            // BLUFOR Adjustment
            if (_side == west) then {
                _x setSkill ["aimingAccuracy", 0.35 + random 0.15];   // 0.35 -> 0.50
                _x setSkill ["aimingShake",   0.40 + random 0.20];   // 0.40 -> 0.60
                _x setSkill ["aimingSpeed",   0.40 + random 0.20];   // 0.40 -> 0.60
                _x setSkill ["spotDistance",  0.60 + random 0.20];   // 0.60 -> 0.80
                _x setSkill ["spotTime",      0.65 + random 0.10];   // 0.65 -> 0.75
                _x setSkill ["courage", 1];
                _x setSkill ["reloadSpeed", 0.75];
                _x setSkill ["commanding", 0.6];
                _x setSkill ["general", 0.65];
                _x allowFleeing 0;
            };
        };
    } forEach allUnits;

    sleep 60;
};
