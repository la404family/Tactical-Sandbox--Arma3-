// ============================================================================
// FONCTION : fn_task_briefing.sqf corrigée pour DLC & Multijoueur
// ============================================================================

params ["_taskID"];

// Sécurité : Quitter si ce n'est pas un joueur (évite les erreurs sur Serveur Dédié/HC)
if (!hasInterface) exitWith {}; 

[_taskID] spawn {
    params ["_taskID"];

    // ÉTAPE 1 : ATTENTE DE SYNCHRONISATION
    // On attend que l'objet 'player' soit tangible et que la mission ait démarré.
    waitUntil {!isNull player && {time > 0}};

    // ÉTAPE 2 : GARANTIE DU CONTENEUR (SUJET)
    // Les cDLC peuvent ne pas initialiser le sujet "Diary" par défaut.
    if !(player diarySubjectExists "Diary") then {
        player createDiarySubject ["Diary", localize "STR_DIARY_TITLE"];
    };

    // ÉTAPE 3 : CRÉATION ATOMIQUE DE LA TÂCHE (BIS_fnc_taskCreate)
    switch (_taskID) do {
    case "task_1": {
        player createDiaryRecord ["Diary", [
            localize "STR_TASK_1_TITLE", 
            format ["
<font size='20' color='#FF0000'>%1</font><br/><br/>

<font color='#eba134'>%2</font><br/>
%3<br/>
<font color='#FF0000'>%4</font> %5<br/><br/>

<font color='#eba134'>%6</font><br/>
%7<br/><br/>

<font color='#eba134'>%8</font><br/>
<font color='#999999'>%9</font><br/>
%10<br/>
<font color='#ffdfbf'>%11</font><br/><br/>

<font color='#999999'>%12</font><br/>
%13<br/><br/>

<font color='#999999'>%14</font><br/>
- <font color='#00FF00'>%15</font><br/>
- <font color='#FF0000'>%16</font><br/>
- <font color='#FF0000'>%17</font><br/><br/>

<font color='#eba134'>%18</font><br/>
- <font color='#FF0000'>%19</font> %20<br/>
- <font color='#FFFF00'>%21</font> %22<br/>
- <font color='#0000FF'>%23</font> %24<br/>
            ",
            localize "STR_BRIEF_T1_OP_TITLE",
            localize "STR_BRIEF_HEADER_SITUATION",
            localize "STR_BRIEF_T1_SITUATION",
            localize "STR_BRIEF_HEADER_THREAT", localize "STR_BRIEF_T1_THREAT_TEXT",
            localize "STR_BRIEF_HEADER_MISSION",
            localize "STR_BRIEF_T1_MISSION",
            localize "STR_BRIEF_HEADER_EXECUTION",
            localize "STR_BRIEF_T1_EXE_A_TITLE",
            localize "STR_BRIEF_T1_EXE_A_TEXT",
            localize "STR_BRIEF_T1_NOTE_TECH",
            localize "STR_BRIEF_T1_EXE_B_TITLE",
            localize "STR_BRIEF_T1_EXE_B_TEXT",
            localize "STR_BRIEF_T1_ROE_TITLE",
            localize "STR_BRIEF_T1_ROE_1",
            localize "STR_BRIEF_T1_ROE_2",
            localize "STR_BRIEF_T1_ROE_3",
            localize "STR_BRIEF_HEADER_SIGNAL",
            localize "STR_BRIEF_SIG_RED", localize "STR_BRIEF_T1_SIG_RED_TEXT",
            localize "STR_BRIEF_SIG_YELLOW", localize "STR_BRIEF_T1_SIG_YELLOW_TEXT",
            localize "STR_BRIEF_SIG_BLUE", localize "STR_BRIEF_T1_SIG_BLUE_TEXT"
            ]
        ]];
    };
    case "task_2": {
        player createDiaryRecord ["Diary", [
            localize "STR_TASK_2_TITLE", 
            format ["
<font size='20' color='#FF0000'>%1</font><br/><br/>

<font color='#eba134'>%2</font><br/>
%3<br/>
<font color='#FF0000'>%4</font> %5<br/><br/>

<font color='#eba134'>%6</font><br/>
%7<br/><br/>

<font color='#eba134'>%8</font><br/>
<font color='#999999'>%9</font><br/>
%10<br/><br/>

<font color='#999999'>%11</font><br/>
%12<br/>
- <font color='#00FF00'>%13</font> %14<br/><br/>

<font color='#eba134'>%15</font><br/>
- <font color='#FF0000'>%16</font> %17<br/>
- <font color='#FFFFFF'>%18</font> %19<br/>
            ",
            localize "STR_BRIEF_T2_OP_TITLE",
            localize "STR_BRIEF_HEADER_SITUATION",
            localize "STR_BRIEF_T2_SITUATION",
            localize "STR_BRIEF_HEADER_THREAT", localize "STR_BRIEF_T2_THREAT_TEXT",
            localize "STR_BRIEF_HEADER_MISSION",
            localize "STR_BRIEF_T2_MISSION",
            localize "STR_BRIEF_HEADER_EXECUTION",
            localize "STR_BRIEF_T1_EXE_A_TITLE",
            localize "STR_BRIEF_T2_EXE_A_TEXT",
            localize "STR_BRIEF_T2_EXE_B_TITLE",
            localize "STR_BRIEF_T2_EXE_B_TEXT",
            localize "STR_BRIEF_HEADER_RECOVERY", localize "STR_BRIEF_T2_RECOVERY_TEXT",
            localize "STR_BRIEF_HEADER_SIGNAL",
            localize "STR_BRIEF_SIG_TARGET", localize "STR_BRIEF_T2_SIG_TARGET_TEXT",
            localize "STR_BRIEF_SIG_DOC", localize "STR_BRIEF_T2_SIG_DOC_TEXT"
            ]
        ]];
    };
    case "task_3": {
        player createDiaryRecord ["Diary", [
            localize "STR_TASK_3_TITLE", 
            format ["
<font size='20' color='#FF0000'>%1</font><br/><br/>

<font color='#eba134'>%2</font><br/>
%3<br/>
<font color='#FF0000'>%4</font> %5<br/><br/>

<font color='#eba134'>%6</font><br/>
%7<br/><br/>

<font color='#eba134'>%8</font><br/>
<font color='#999999'>%9</font><br/>
%10<br/><br/>

<font color='#999999'>%11</font><br/>
<font color='#00aaff'>%12</font> %13<br/><br/>

<font color='#eba134'>%14</font><br/>
- <font color='#FF0000'>%15</font> %16<br/>
- %17<br/>
            ",
            localize "STR_BRIEF_T3_OP_TITLE",
            localize "STR_BRIEF_HEADER_SITUATION",
            localize "STR_BRIEF_T3_SITUATION",
            localize "STR_BRIEF_HEADER_THREAT", localize "STR_BRIEF_T3_THREAT_TEXT",
            localize "STR_BRIEF_HEADER_MISSION",
            localize "STR_BRIEF_T3_MISSION",
            localize "STR_BRIEF_HEADER_EXECUTION",
            localize "STR_BRIEF_T3_EXE_A_TITLE",
            localize "STR_BRIEF_T3_EXE_A_TEXT",
            localize "STR_BRIEF_T3_EXE_B_TITLE",
            localize "STR_BRIEF_HEADER_AIR_SUPPORT", localize "STR_BRIEF_T3_EXE_B_TEXT",
            localize "STR_BRIEF_HEADER_SIGNAL",
            localize "STR_BRIEF_SIG_CARGO", localize "STR_BRIEF_T3_SIG_CARGO_TEXT",
            localize "STR_BRIEF_T3_SIG_NOTE"
            ]
        ]];
    };
    case "task_4": {
        player createDiaryRecord ["Diary", [
            localize "STR_TASK_4_TITLE", 
            format ["
<font size='20' color='#FF0000'>%1</font><br/><br/>

<font color='#eba134'>%2</font><br/>
%3<br/>
<font color='#FF0000'>%4</font> %5<br/><br/>

<font color='#eba134'>%6</font><br/>
%7<br/><br/>

<font color='#eba134'>%8</font><br/>
<font color='#999999'>%9</font><br/>
%10<br/><br/>

<font color='#999999'>%11</font><br/>
%12<br/><br/>

<font color='#999999'>%13</font><br/>
%14<br/>
<font color='#ffdfbf'>%15</font> %16<br/><br/>

<font color='#eba134'>%17</font><br/>
- <font color='#FFA500'>%18</font> %19<br/>
- <font color='#00FF00'>%20</font> %21<br/>
            ",
            localize "STR_BRIEF_T4_OP_TITLE",
            localize "STR_BRIEF_HEADER_SITUATION",
            localize "STR_BRIEF_T4_SITUATION",
            localize "STR_BRIEF_HEADER_THREAT", localize "STR_BRIEF_T4_THREAT_TEXT",
            localize "STR_BRIEF_HEADER_MISSION",
            localize "STR_BRIEF_T4_MISSION",
            localize "STR_BRIEF_HEADER_EXECUTION",
            localize "STR_BRIEF_T4_PHASE_1_TITLE",
            localize "STR_BRIEF_T4_PHASE_1_TEXT",
            localize "STR_BRIEF_T4_PHASE_2_TITLE",
            localize "STR_BRIEF_T4_PHASE_2_TEXT",
            localize "STR_BRIEF_T4_PHASE_3_TITLE",
            localize "STR_BRIEF_T4_PHASE_3_TEXT",
            localize "STR_BRIEF_HEADER_NOTE", localize "STR_BRIEF_T4_NOTE",
            localize "STR_BRIEF_HEADER_SIGNAL",
            localize "STR_BRIEF_SIG_ORANGE", localize "STR_BRIEF_T4_SIG_ORANGE_TEXT",
            localize "STR_BRIEF_SIG_EXTRACTION", localize "STR_BRIEF_T4_SIG_EXTRACTION_TEXT"
            ]
        ]];
    };
    case "task_5": {
        player createDiaryRecord ["Diary", [
            localize "STR_TASK_5_TITLE", 
            format ["
<font size='20' color='#FF0000'>%1</font><br/><br/>

<font color='#eba134'>%2</font><br/>
%3<br/>
<font color='#FF0000'>%4</font> %5<br/><br/>

<font color='#eba134'>%6</font><br/>
%7<br/><br/>

<font color='#eba134'>%8</font><br/>
<font color='#999999'>%9</font><br/>
%10<br/><br/>

<font color='#999999'>%11</font><br/>
%12<br/><br/>

<font color='#999999'>%13</font><br/>
- <font color='#FF0000'>%14</font> %15<br/>
- <font color='#FFFF00'>%16</font> %17<br/><br/>

<font color='#eba134'>%18</font><br/>
- %19<br/>
- %20<br/>
            ",
            localize "STR_BRIEF_T5_OP_TITLE",
            localize "STR_BRIEF_HEADER_SITUATION",
            localize "STR_BRIEF_T5_SITUATION",
            localize "STR_BRIEF_HEADER_THREAT", localize "STR_BRIEF_T5_THREAT_TEXT",
            localize "STR_BRIEF_HEADER_MISSION",
            localize "STR_BRIEF_T5_MISSION",
            localize "STR_BRIEF_HEADER_EXECUTION",
            localize "STR_BRIEF_T5_EXE_A_TITLE",
            localize "STR_BRIEF_T5_EXE_A_TEXT",
            localize "STR_BRIEF_T5_EXE_B_TITLE",
            localize "STR_BRIEF_T5_EXE_B_TEXT",
            localize "STR_BRIEF_T5_ROE_TITLE",
            localize "STR_BRIEF_ROE_STRICT", localize "STR_BRIEF_T5_ROE_STRICT_TEXT",
            localize "STR_BRIEF_ROE_VIGILANCE", localize "STR_BRIEF_T5_ROE_VIGILANCE_TEXT",
            localize "STR_BRIEF_HEADER_DEFEAT",
            localize "STR_BRIEF_T5_DEFEAT_TEXT_1",
            localize "STR_BRIEF_T5_DEFEAT_TEXT_2"
            ]
        ]];
    };
    case "task_6": {
        player createDiaryRecord ["Diary", [
            localize "STR_TASK_6_TITLE", 
            format ["
<font size='20' color='#FF0000'>%1</font><br/><br/>

<font color='#eba134'>%2</font><br/>
%3<br/>
<font color='#FF0000'>%4</font> %5<br/><br/>

<font color='#eba134'>%6</font><br/>
%7<br/><br/>

<font color='#eba134'>%8</font><br/>
<font color='#999999'>%9</font><br/>
%10<br/><br/>

<font color='#999999'>%11</font><br/>
<font color='#00FF00'>%12</font> %13<br/>
%14<br/><br/>

<font color='#999999'>%15</font><br/>
%16<br/><br/>

<font color='#eba134'>%17</font><br/>
- <font color='#FF0000'>%18</font> %19<br/>
- <font color='#0000FF'>%20</font> %21<br/>
            ",
            localize "STR_BRIEF_T6_OP_TITLE",
            localize "STR_BRIEF_HEADER_SITUATION",
            localize "STR_BRIEF_T6_SITUATION",
            localize "STR_BRIEF_HEADER_THREAT", localize "STR_BRIEF_T6_THREAT_TEXT",
            localize "STR_BRIEF_HEADER_MISSION",
            localize "STR_BRIEF_T6_MISSION",
            localize "STR_BRIEF_HEADER_EXECUTION",
            localize "STR_BRIEF_T6_EXE_A_TITLE",
            localize "STR_BRIEF_T6_EXE_A_TEXT",
            localize "STR_BRIEF_T6_EXE_B_TITLE",
            localize "STR_BRIEF_HEADER_URGENCY", localize "STR_BRIEF_T6_EXE_B_TEXT_1",
            localize "STR_BRIEF_T6_EXE_B_TEXT_2",
            localize "STR_BRIEF_T6_EXE_C_TITLE",
            localize "STR_BRIEF_T6_EXE_C_TEXT",
            localize "STR_BRIEF_HEADER_SIGNAL",
            localize "STR_BRIEF_SIG_CRASH", localize "STR_BRIEF_T6_SIG_CRASH_TEXT",
            localize "STR_BRIEF_SIG_BLUE", localize "STR_BRIEF_T6_SIG_BLUE_TEXT"
            ]
        ]];
    };
    case "task_7": {
        player createDiaryRecord ["Diary", [
            localize "STR_TASK_7_TITLE", 
            format ["
<font size='20' color='#FF0000'>%1</font><br/><br/>

<font color='#eba134'>%2</font><br/>
%3<br/>
<font color='#FF0000'>%4</font> %5<br/><br/>

<font color='#eba134'>%6</font><br/>
%7<br/><br/>

<font color='#eba134'>%8</font><br/>
<font color='#999999'>%9</font><br/>
%10<br/><br/>

<font color='#999999'>%11</font><br/>
%12<br/><br/>

<font color='#eba134'>%13</font><br/>
- <font color='#FF0000'>%14</font> %15<br/>
            ",
            localize "STR_BRIEF_T7_OP_TITLE",
            localize "STR_BRIEF_HEADER_SITUATION",
            localize "STR_BRIEF_T7_SITUATION",
            localize "STR_BRIEF_HEADER_THREAT", localize "STR_BRIEF_T7_THREAT_TEXT",
            localize "STR_BRIEF_HEADER_MISSION",
            localize "STR_BRIEF_T7_MISSION",
            localize "STR_BRIEF_HEADER_EXECUTION",
            localize "STR_BRIEF_T7_EXE_A_TITLE",
            localize "STR_BRIEF_T7_EXE_A_TEXT",
            localize "STR_BRIEF_T7_EXE_B_TITLE",
            localize "STR_BRIEF_T7_EXE_B_TEXT",
            localize "STR_BRIEF_HEADER_SIGNAL",
            localize "STR_BRIEF_SIG_TARGET", localize "STR_BRIEF_T7_SIG_RADAR_TEXT"
            ]
        ]];
    };
};
};
