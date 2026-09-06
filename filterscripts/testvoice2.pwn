#define FILTERSCRIPT

#include <a_samp>
#undef MAX_PLAYERS
#define MAX_PLAYERS 250

#include <streamer>
#include <sampvoice>
#include <sscanf2>
#include "./voiceatrp/funcs.pwn"

public SV_VOID:OnPlayerActivationKeyPress(SV_UINT:playerid, SV_UINT:keyid)
{
    if (keyid == KeyVoice[playerid] && PlayerVoiceData[playerid][pHasRadio] == SV_TRUE && PlayerVoiceData[playerid][pIsRadioOn] == SV_TRUE && PlayerVoiceData[playerid][pIsRadioMicOn] == SV_TRUE && PlayerVoiceData[playerid][pRadioFreq] >= 1)
    {
        for(new i; i < 500; i++)
        {
            if(IsPlayerConnected(i) && PlayerVoiceData[i][pRadioFreq] == PlayerVoiceData[playerid][pRadioFreq] && PlayerVoiceData[i][pIsRadioOn] == SV_TRUE)
            {
                PlayerPlaySound(i, 21000, 0.0, 0.0, 0.0);
            }
        }
        ApplyAnimation(playerid, "ped", "phone_talk", 4.1, 1, 1, 1, 1, 1, 1);
        SetPlayerAttachedObject(playerid, 9, 19942, 6, 0.078999, 0.047999, 0.023999, 0.000000, 0.000000, 179.099899, 1.000000, 1.000000, 1.000000);
        SvAttachSpeakerToStream(vdRadioStream[PlayerVoiceData[playerid][pRadioFreq]], playerid);

        if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
            MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL:INVALID_STREAMER_ID;

        MouthStatusLabel[playerid] = CreateDynamic3DTextLabel("Radio..", 0x7fffd4d9, 0.0, 0.0, 0.35, 20.0, playerid, INVALID_VEHICLE_ID, 1, -1, -1, -1, 20.0, -1, 0);
    }

    if (keyid == KeyVoice[playerid] && PlayerVoiceData[playerid][pDuringPhoneConvers] == SV_TRUE)
    {
        ApplyAnimation(playerid, "ped", "phone_talk", 4.1, 1, 1, 1, 1, 1, 1);
        if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
            MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL: INVALID_STREAMER_ID;
        
        MouthStatusLabel[playerid] = CreateDynamic3DTextLabel("Telepon..", 0xff91a4d9, 0.0, 0.0, 0.35, 20.0, playerid, INVALID_VEHICLE_ID, 1, -1, -1, -1, 20.0, -1, 0);
    }

    if (keyid == KeyVoice[playerid] && vdLocalStream[playerid])
    {
        SvEffectAttachStream(vCompressor, vdLocalStream[playerid]);
        SvAttachSpeakerToStream(vdLocalStream[playerid], playerid);
        SvStreamParameterSet(vdLocalStream[playerid], SV_PARAMETER_VOLUME, 35.0);

        if(PlayerVoiceData[playerid][pIsRadioMicOn] == SV_FALSE && PlayerVoiceData[playerid][pDuringPhoneConvers] == SV_FALSE)
        {
            if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
                MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL:INVALID_STREAMER_ID;

            MouthStatusLabel[playerid] = CreateDynamic3DTextLabel("Talking..", 0x83C786FF, 0.0, 0.0, 0.35, 20.0, playerid, INVALID_VEHICLE_ID, 1, -1, -1, -1, 20.0, -1, 0);
        }
    }
}

public SV_VOID:OnPlayerActivationKeyRelease(SV_UINT:playerid, SV_UINT:keyid)
{
    if (keyid == KeyVoice[playerid] && PlayerVoiceData[playerid][pHasRadio] == SV_TRUE && PlayerVoiceData[playerid][pIsRadioOn] == SV_TRUE && PlayerVoiceData[playerid][pIsRadioMicOn] == SV_TRUE && PlayerVoiceData[playerid][pRadioFreq] >= 1)
    {
        for(new i; i < 500; i++)
        {
            if(IsPlayerConnected(i) && PlayerVoiceData[i][pRadioFreq] == PlayerVoiceData[playerid][pRadioFreq] && PlayerVoiceData[i][pIsRadioOn] == SV_TRUE)
            {
                PlayerPlaySound(i, 21001, 0.0, 0.0, 0.0);
            }
        }
        ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.0, 0, 0, 0, 0, 0, 1);
        SvDetachSpeakerFromStream(vdRadioStream[PlayerVoiceData[playerid][pRadioFreq]], playerid);
        RemovePlayerAttachedObject(playerid, 9);

        if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
            MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL:INVALID_STREAMER_ID;
    }

    if (keyid == KeyVoice[playerid] && PlayerVoiceData[playerid][pDuringPhoneConvers] == SV_TRUE)
    {
        if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
            MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL:INVALID_STREAMER_ID;
    }

    if (keyid == KeyVoice[playerid] && vdLocalStream[playerid] && PlayerVoiceData[playerid][pIsRadioMicOn] == SV_FALSE && PlayerVoiceData[playerid][pDuringPhoneConvers] == SV_FALSE)
    {
        SvEffectDetachStream(vCompressor, vdLocalStream[playerid]);
        SvDetachSpeakerFromStream(vdLocalStream[playerid], playerid);

        if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
            MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL:INVALID_STREAMER_ID;
    }
}

public OnPlayerConnect(playerid)
{
    ResetVoiceVariables(playerid);

    if (SvGetVersion(playerid) == SV_NULL)
    {
        new lstring[512];
        format(lstring, sizeof(lstring), ""WHITE"Dari: Penjaga kota Warga Indo\nKepada: Warga (pemain peran) di Kota Warga Indo Roleplay, "RED"%s\n\n"WHITE"Untuk bermain peran di Warga Indo Roleplay, maka anda harus memenuhi syarat yaitu memasang Plugin Voice anda.", GetName(playerid));
        ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, ""WIRP"Warga Indo Roleplay "WHITE"- Plugin Tidak Terdeteksi", lstring, "Keluar", "");

        SendClientMessage(playerid, 0xFFFF00AA, "[i] Anda telah ditendang dari server karena "RED"Plugin Voice "YELLOW"tidak terdeteksi!");
        return KickEx(playerid);
    }
    else if(!SvHasMicro(playerid))
    {
        new lstring[512];
        format(lstring, sizeof(lstring), ""WHITE"Dari: Penjaga kota Warga Indo Roleplay\nKepada: Warga (pemain peran) di Kota Warga Indo Roleplay, "RED"%s\n\n"WHITE"Untuk bermain peran di Warga Indo Roleplay, maka anda harus memenuhi syarat yaitu mengaktifkan Voice Sistem anda.", GetName(playerid));
        ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, ""WIRP"Warga Indo Roleplay "WHITE"- Mic Tidak Terdeteksi", lstring, "Keluar", "");

        SendClientMessage(playerid, 0xFFFF00AA, "[i] Anda telah ditendang dari server karena "RED"Mic/Headset "YELLOW"tidak terdeteksi!");
        return KickEx(playerid);
    }
    else if((vdLocalStream[playerid] = SvCreateDLStreamAtPlayer(15.0, SV_INFINITY, playerid, 0xffff0000, "")))
    {
        SvAddKey(playerid, KeyVoice[playerid]);
        if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
            MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL:INVALID_STREAMER_ID;
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(vdLocalStream[playerid])
    {
        SvEffectDetachStream(vCompressor, vdLocalStream[playerid]);
        SvDeleteStream(vdLocalStream[playerid]);
        vdLocalStream[playerid] = SV_NULL;
    }

    if(vdPhoneStream[playerid])
    {
        SvDeleteStream(vdPhoneStream[playerid]);
        vdPhoneStream[playerid] = SV_NULL;
    }

    ResetVoiceVariables(playerid);
    return 1;
}

forward Cek(playerid);
public Cek(playerid)
{
    SendClientMessageEx(playerid, -1, "%d", KeyVoice[playerid]);
    return 1;
}

public OnFilterScriptInit()
{
    vCompressor = SvEffectCreateCompressor(1, 15.0, 2.0, 100.0, -14.0, 4.00, 0.0);
    for(new x; x < MAX_FREQ; x++)
    {
        vdRadioStream[x] = SvCreateGStream(0xffffff00, "");
        SvEffectAttachStream(vCompressor, vdRadioStream[x]);
        SvStreamParameterSet(vdRadioStream[x], SV_PARAMETER_VOLUME, 0.4);
    }

    print("-------------------- [WIRP Voice Chat System] --------------------\
    \n===>> Berhasil dimuat dengan baik!\
    \n===>> by: Jaden (WIRP)\
    \n===>> dipersembahkan untuk WargaIndo\
    \n-----------------------------------------------------------------");
    return 1;
}

public OnFilterScriptExit()
{
    for(new x; x < MAX_FREQ; x++)
    {
        SvDeleteStream(vdRadioStream[x]);
    }
    return 1;
}
