// *********************************************************************
// Damage System (FIXED VERSION)
// Author Original : ZiiM
// Fixed by        : ChatGPT
// *********************************************************************

#include <a_samp>
#include <izcmd>
#include <sscanf2>
#include <YSI\y_ini>

#define MAX_DAMAGE 100

/* ================= DIALOG ID (AMAN) ================= */
#define DIALOG_DMG_DEFAULT        2000
#define DIALOG_DMG_LIST           2001
#define DIALOG_DMG_SETTINGS       2002
#define DIALOG_DMG_WEP_LIST       2003
#define DIALOG_DMG_SET_DAMAGE     2004

/* ================= VARIABLES ================= */
enum dmgData {
    dmgExist,
    dmgDamage,
    dmgBodypart,
    dmgWeapon,
    dmgArmour,
    dmgTime
};

new DamageData[MAX_PLAYERS][MAX_DAMAGE][dmgData];
new TotalDamages[MAX_PLAYERS];

new bool:dmgEnabled = true;
new WepDamage[43];

/* ================= INI LOAD ================= */
INI:wepdmg[Damages](name[], value[])
{
    new id = strval(name);
    if(id >= 0 && id < sizeof(WepDamage))
    {
        WepDamage[id] = strval(value);
    }
    return 1;
}

INI:wepdmg[SystemToggle](name[], value[])
{
    INI_Bool("System", dmgEnabled);
    return 1;
}

/* ================= FS INIT ================= */
public OnFilterScriptInit()
{
    for(new i; i < sizeof(WepDamage); i++)
        WepDamage[i] = -1;

    INI_Load("wepdmg.ini");

    print("[DamageSystem] Loaded (FIXED)");
    return 1;
}

public OnFilterScriptExit()
{
    SaveAll();
    return 1;
}

/* ================= PLAYER ================= */
public OnPlayerConnect(playerid)
{
    WipeDamages(playerid);
    return 1;
}

public OnPlayerDeath(playerid)
{
    WipeDamages(playerid);
    return 1;
}

stock WipeDamages(playerid)
{
    for(new i; i < MAX_DAMAGE; i++)
    {
        DamageData[playerid][i][dmgExist] = 0;
        DamageData[playerid][i][dmgDamage] = 0;
        DamageData[playerid][i][dmgBodypart] = 0;
        DamageData[playerid][i][dmgWeapon] = 0;
        DamageData[playerid][i][dmgArmour] = 0;
        DamageData[playerid][i][dmgTime] = 0;
    }
    TotalDamages[playerid] = 0;
    return 1;
}

/* ================= DAMAGE HANDLER ================= */
public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
    if(!dmgEnabled) return 1;

    new id = -1;
    for(new i; i < MAX_DAMAGE; i++)
    {
        if(!DamageData[playerid][i][dmgExist])
        {
            id = i;
            break;
        }
    }
    if(id == -1) return 1;

    new dmg = (WepDamage[weaponid] == -1) ? floatround(amount) : WepDamage[weaponid];

    DamageData[playerid][id][dmgExist] = 1;
    DamageData[playerid][id][dmgDamage] = dmg;
    DamageData[playerid][id][dmgWeapon] = weaponid;
    DamageData[playerid][id][dmgBodypart] = bodypart;
    DamageData[playerid][id][dmgTime] = gettime();

    TotalDamages[playerid]++;
    return 1;
}

/* ================= COMMAND ================= */
CMD:damagesetting(playerid)
{
    new str[128];
    format(str, sizeof(str),
        "Set Weapon Damage\nDamage System: %s",
        dmgEnabled ? "{00FF00}Enabled" : "{FF0000}Disabled"
    );

    ShowPlayerDialog(playerid, DIALOG_DMG_SETTINGS, DIALOG_STYLE_LIST,
        "Damage System Settings", str, "Select", "Close");
    return 1;
}

/* ================= DIALOG ================= */
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(!response) return 1;

    switch(dialogid)
    {
        case DIALOG_DMG_SETTINGS:
        {
            if(listitem == 0)
            {
                new list[1024], tmp[32];
                for(new i; i < 43; i++)
                {
                    if(GetWeaponName(i, tmp, sizeof tmp))
                    {
                        format(list, sizeof(list), "%s%d - %s\n", list, i, tmp);
                    }
                }
                ShowPlayerDialog(playerid, DIALOG_DMG_WEP_LIST, DIALOG_STYLE_LIST,
                    "Weapon List", list, "Select", "Back");
            }
            else if(listitem == 1)
            {
                dmgEnabled = !dmgEnabled;
                SaveAll();
                SendClientMessage(playerid, -1,
                    dmgEnabled ? "Damage System Enabled" : "Damage System Disabled");
            }
        }

        case DIALOG_DMG_WEP_LIST:
        {
            SetPVarInt(playerid, "EditWeapon", listitem);
            ShowPlayerDialog(playerid, DIALOG_DMG_SET_DAMAGE,
                DIALOG_STYLE_INPUT, "Set Weapon Damage",
                "Input damage (-1 = default)", "Save", "Cancel");
        }

        case DIALOG_DMG_SET_DAMAGE:
        {
            new wid = GetPVarInt(playerid, "EditWeapon");
            WepDamage[wid] = strval(inputtext);
            SaveAll();
            SendClientMessage(playerid, -1, "Weapon damage updated");
        }
    }
    return 1;
}

/* ================= SAVE ================= */
SaveAll()
{
    new INI:ini = INI_Open("wepdmg.ini");

    INI_SetTag(ini, "Damages");
    for(new i; i < sizeof(WepDamage); i++)
    {
        new key[8];
        format(key, sizeof(key), "%d", i);
        INI_WriteInt(ini, key, WepDamage[i]);
    }

    INI_SetTag(ini, "SystemToggle");
    INI_WriteBool(ini, "System", dmgEnabled);

    INI_Close(ini);
    return 1;
}
