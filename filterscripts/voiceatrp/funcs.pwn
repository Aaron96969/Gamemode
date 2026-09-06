#define MAX_FREQ    10000

#define WHITE       "{FFFFFF}"
#define RED         "{FF0000}"
#define YELLOW      "{FFFF00}"
#define WIRP       "{1DF0BB85}"

#define Y_WHITE     0xFFFFFFFF
#define Y_RED       0xFF0000D9
#define Y_YELLOW    0xFFFF00FF
#define RED_W     0x1DF0BB85

#define KEY_B   0x42
#define KEY_R   0x52
#define KEY_X   0x58
#define KEY_Z   0x5A
#define KEY_SHIFT 0x10

enum
{
    DIALOG_UNUSED
};

enum e_player_voice_stuff
{
    SV_BOOL:pHasRadio,
    SV_BOOL:pIsRadioOn,
    SV_BOOL:pIsRadioMicOn,
    VoiceModeDistance,
    pRadioFreq,
    SV_BOOL:pDuringPhoneConvers,
    pCallingWithPlayerID,
};
new PlayerVoiceData[MAX_PLAYERS][e_player_voice_stuff];

new SV_GSTREAM:vdRadioStream[MAX_FREQ] = { SV_NULL, ... };
new SV_GSTREAM:vdPhoneStream[MAX_PLAYERS] = { SV_NULL, ... };
new SV_LSTREAM:vdLocalStream[MAX_PLAYERS] = { SV_NULL, ... };
new SV_EFFECT:vCompressor;

new KeyVoice[MAX_PLAYERS];
new STREAMER_TAG_3D_TEXT_LABEL:MouthStatusLabel[MAX_PLAYERS];

GetName(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid,name,sizeof(name));
    return name;
}

ResetVoiceVariables(playerid)
{
    if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
        MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL: INVALID_STREAMER_ID;
    
    KeyVoice[playerid] = KEY_B;
    PlayerVoiceData[playerid][pHasRadio] = false;
    PlayerVoiceData[playerid][pIsRadioOn] = false;
    PlayerVoiceData[playerid][pIsRadioMicOn] = false;
    PlayerVoiceData[playerid][VoiceModeDistance] = 2;
    PlayerVoiceData[playerid][pRadioFreq] = 0;
    PlayerVoiceData[playerid][pDuringPhoneConvers] = false;
    PlayerVoiceData[playerid][pCallingWithPlayerID] = INVALID_PLAYER_ID;
}

forward _KickPlayerDelayed(playerid);
public _KickPlayerDelayed(playerid)
{
    return Kick(playerid);
}

forward UpdateVoiceMegaStatus(playerid, SV_BOOL:togmeg);
public UpdateVoiceMegaStatus(playerid, SV_BOOL:togmeg)
{
    switch(togmeg)
    {
        case SV_FALSE:
        {
            SvUpdateDistanceForLStream(vdLocalStream[playerid], 15.0);
            SvStreamParameterSet(vdLocalStream[playerid], SV_PARAMETER_VOLUME, 1.0);
        }
        case SV_TRUE:
        {
            SvUpdateDistanceForLStream(vdLocalStream[playerid], 50.0);
            SvStreamParameterSet(vdLocalStream[playerid], SV_PARAMETER_VOLUME, 150.0);
        }
    }
    return 1;
}

forward AssignFreqToFSVoice(playerid, SV_BOOL:hasradio, freq);
public AssignFreqToFSVoice(playerid, SV_BOOL:hasradio, freq)
{
    PlayerVoiceData[playerid][pHasRadio] = hasradio;
    SvDetachListenerFromStream(vdRadioStream[PlayerVoiceData[playerid][pRadioFreq]], playerid); //dikeluarkan dari mendengarkan freq lama
    SvAttachListenerToStream(vdRadioStream[freq], playerid);
    PlayerVoiceData[playerid][pRadioFreq] = freq;
    return 1;
}

forward UpdatePlayerVoiceDistance(playerid, mode, SV_FLOAT:lstreamdistance);
public UpdatePlayerVoiceDistance(playerid, mode, SV_FLOAT:lstreamdistance)
{
    PlayerVoiceData[playerid][VoiceModeDistance] = mode;
    SvUpdateDistanceForLStream(vdLocalStream[playerid], lstreamdistance);
    return 1;
}

forward UpdatePlayerVoiceKeys(playerid, button);
public UpdatePlayerVoiceKeys(playerid, button)
{
    SvRemoveKey(playerid, KeyVoice[playerid]);
    switch(button)
    {
        case 1: KeyVoice[playerid] = KEY_B;
        case 2: KeyVoice[playerid] = KEY_R;
        case 3: KeyVoice[playerid] = KEY_X;
        case 4: KeyVoice[playerid] = KEY_Z;
        case 5: KeyVoice[playerid] = KEY_SHIFT;
    }
    SvAddKey(playerid, KeyVoice[playerid]);
    return 1;
}

forward UpdatePlayerVoiceMicToggle(playerid, SV_BOOL:togglemic);
public UpdatePlayerVoiceMicToggle(playerid, SV_BOOL:togglemic)
{
    PlayerVoiceData[playerid][pIsRadioMicOn] = togglemic;
    return 1;
}

forward UpdatePlayerVoiceRadioToggle(playerid, SV_BOOL:togradio);
public UpdatePlayerVoiceRadioToggle(playerid, SV_BOOL:togradio)
{
    PlayerVoiceData[playerid][pIsRadioOn] = togradio;

    switch(PlayerVoiceData[playerid][pIsRadioOn])
    {
        case SV_FALSE: //posisi mati tidak bisa mendengar percakapan radio
        {
            SvDetachListenerFromStream(vdRadioStream[PlayerVoiceData[playerid][pRadioFreq]], playerid);
        }
        case SV_TRUE: //posisi hidup bisa dengar
        {
            SvAttachListenerToStream(vdRadioStream[PlayerVoiceData[playerid][pRadioFreq]], playerid);
        }
    }
    return 1;
}

forward ConnectPlayerCalling(playerid, inlinewithID);
public ConnectPlayerCalling(playerid, inlinewithID)
{
    // playerid adalah player yang ditelpon, inlinewithid adalah player yang menelpon

    PlayerVoiceData[playerid][pCallingWithPlayerID] = inlinewithID;
    PlayerVoiceData[inlinewithID][pCallingWithPlayerID] = playerid;

    vdPhoneStream[inlinewithID] = SvCreateGStream(0xFFA200FF, "Phone");

    PlayerVoiceData[playerid][pDuringPhoneConvers] = true;
    PlayerVoiceData[inlinewithID][pDuringPhoneConvers] = true;

    if (vdPhoneStream[inlinewithID])
    {
        SvAttachListenerToStream(vdPhoneStream[inlinewithID], inlinewithID);
        SvAttachListenerToStream(vdPhoneStream[inlinewithID], playerid);
    }

    if (vdPhoneStream[inlinewithID] && PlayerVoiceData[playerid][pCallingWithPlayerID] != INVALID_PLAYER_ID) {
        SvAttachSpeakerToStream(vdPhoneStream[inlinewithID], playerid);
    }

    if (vdPhoneStream[inlinewithID] && PlayerVoiceData[inlinewithID][pCallingWithPlayerID] != INVALID_PLAYER_ID) {
        SvAttachSpeakerToStream(vdPhoneStream[inlinewithID], inlinewithID);
    }

    if (DestroyDynamic3DTextLabel(MouthStatusLabel[inlinewithID]))
        MouthStatusLabel[inlinewithID] = STREAMER_TAG_3D_TEXT_LABEL: INVALID_STREAMER_ID;

    MouthStatusLabel[inlinewithID] = CreateDynamic3DTextLabel("Telepon..", 0xff91a4d9, 0.0, 0.0, 0.35, 20.0, inlinewithID, INVALID_VEHICLE_ID, 1, -1, -1, -1, 20.0, -1, 0);

    if (DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
        MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL: INVALID_STREAMER_ID;

    MouthStatusLabel[playerid] = CreateDynamic3DTextLabel("Telepon..", 0xff91a4d9, 0.0, 0.0, 0.35, 20.0, playerid, INVALID_VEHICLE_ID, 1, -1, -1, -1, 20.0, -1, 0);
    return 1;
}

forward DisconnectPlayerCalling(playerid, inlinewithID);
public DisconnectPlayerCalling(playerid, inlinewithID)
{
    // playerid adalah player yang ditelpon, inlinewithid adalah player yang menelpon

    // First make sure both players are properly disconnected
    PlayerVoiceData[playerid][pDuringPhoneConvers] = false;
    PlayerVoiceData[playerid][pCallingWithPlayerID] = INVALID_PLAYER_ID;
    
    if(IsPlayerConnected(inlinewithID))
    {
        PlayerVoiceData[inlinewithID][pDuringPhoneConvers] = false;
        PlayerVoiceData[inlinewithID][pCallingWithPlayerID] = INVALID_PLAYER_ID;
    }
    
    // Handle the voice streams
    if(vdPhoneStream[inlinewithID] != SV_NULL)
    {
        // Detach speakers
        if(IsPlayerConnected(inlinewithID))
        {
            SvDetachSpeakerFromStream(vdPhoneStream[inlinewithID], inlinewithID);
            SvDetachListenerFromStream(vdPhoneStream[inlinewithID], inlinewithID);
        }
        
        if(IsPlayerConnected(playerid))
        {
            SvDetachSpeakerFromStream(vdPhoneStream[inlinewithID], playerid);
            SvDetachListenerFromStream(vdPhoneStream[inlinewithID], playerid);
        }
        
        // Delete the stream
        SvDeleteStream(vdPhoneStream[inlinewithID]);
        vdPhoneStream[inlinewithID] = SV_NULL;
    }
    
    if(vdPhoneStream[playerid] != SV_NULL)
    {
        // Detach speakers
        if(IsPlayerConnected(playerid))
        {
            SvDetachSpeakerFromStream(vdPhoneStream[playerid], playerid);
            SvDetachListenerFromStream(vdPhoneStream[playerid], playerid);
        }
        
        if(IsPlayerConnected(inlinewithID))
        {
            SvDetachSpeakerFromStream(vdPhoneStream[playerid], inlinewithID);
            SvDetachListenerFromStream(vdPhoneStream[playerid], inlinewithID);
        }
        
        // Delete the stream
        SvDeleteStream(vdPhoneStream[playerid]);
        vdPhoneStream[playerid] = SV_NULL;
    }
    
    // Destroy 3D text labels
    if(IsPlayerConnected(playerid))
    {
        if(DestroyDynamic3DTextLabel(MouthStatusLabel[playerid]))
            MouthStatusLabel[playerid] = STREAMER_TAG_3D_TEXT_LABEL: INVALID_STREAMER_ID;
    }
    
    if(IsPlayerConnected(inlinewithID))
    {
        if(DestroyDynamic3DTextLabel(MouthStatusLabel[inlinewithID]))
            MouthStatusLabel[inlinewithID] = STREAMER_TAG_3D_TEXT_LABEL: INVALID_STREAMER_ID;
    }
    
    return 1;
}

stock KickEx(playerid, time = 500)
{
    SetTimerEx("_KickPlayerDelayed", time, false, "d", playerid);
    return 1;
}

SendClientMessageEx(playerid, color, const text[], {Float, _}:...)
{
    static
        args,
            str[265];

    if((args = numargs()) == 3)
    {
            SendClientMessage(playerid, color, text);
    }
    else
    {
        while (--args >= 3)
        {
            #emit LCTRL 5
            #emit LOAD.alt args
            #emit SHL.C.alt 2
            #emit ADD.C 12
            #emit ADD
            #emit LOAD.I
            #emit PUSH.pri
        }
        #emit PUSH.S text
        #emit PUSH.C 144
        #emit PUSH.C str
        #emit PUSH.S 8
        #emit SYSREQ.C format
        #emit LCTRL 5
        #emit SCTRL 4

        SendClientMessage(playerid, color, str);

        #emit RETN
    }
    return 1;
}