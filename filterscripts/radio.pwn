#include <a_samp>
#include <gvar>
#include <mxINI>

forward RestoreTimer(playerid);

new ArrayID[MAX_PLAYERS] = {-1,...};
new LastVeh[MAX_PLAYERS] = {INVALID_VEHICLE_ID,...};
new RadioNum = 0;
new CurrentRadio[MAX_VEHICLES+1] = {0,...};
new Passengers[MAX_VEHICLES+1][9];
new PlayerText:RadioTD[MAX_PLAYERS];
new bool:CanChangeRadio[MAX_PLAYERS] = {false,...};
new ChangeTimer[MAX_PLAYERS] = {-1,...};
new bool:ScriptLoaded = false;

public OnFilterScriptInit()
{
	new bool:cp = true;
	new file = ini_openFile("radio_settings.ini");
	switch(file)
	{
		case INI_FILE_NOT_FOUND:
		{
			print("Unable to load settings. File 'radio_settings.ini' doesn't exist.");
			cp = false;
		}
		case INI_TOO_LARGE_FILE:
		{
			print("File 'radio_settings.ini' is too large. Try to remove some lines from it.");
			cp = false;
		}
		case INI_READ_ERROR:
		{
			print("File 'radio_settings.ini' reading error.");
			cp = false;
		}
	}
	if(!cp) return 1;
	new str[128],line[32],result;
	result = ini_getInteger(file,"Radios",RadioNum);
	if(result == INI_KEY_NOT_FOUND) return print("Line 'Radios' hasn't been found in file 'radio_settings.ini'.");
	for(new i = 1; i <= RadioNum; i++)
	{
		format(line,32,"Radio_Title%d",i);
		result = ini_getString(file,line,str);
		if(result == INI_KEY_NOT_FOUND) return printf("'%s' hasn't been found in file 'radio_settings.ini'.",line);
		SetGVarString(line,str);
		format(line,32,"Radio_URL%d",i);
		result = ini_getString(file,line,str);
		if(result == INI_KEY_NOT_FOUND) return printf("'%s' hasn't been found in file 'radio_settings.ini'.",line);
		SetGVarString(line,str);
	}
	ini_closeFile(file);
	ScriptLoaded = true;
	for(new i = 1; i <= MAX_VEHICLES; i++)
	{
		for(new j = 0; j < 9; j++) Passengers[i][j] = INVALID_PLAYER_ID;
		CurrentRadio[i] = random(RadioNum+1);
	}
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(!IsPlayerConnected(i)) continue;
		RadioTD[i] = CreatePlayerTextDraw(i, 318.500000, 22.749988, " ");
		PlayerTextDrawLetterSize(i, RadioTD[i], 0.400000, 1.600000);
		PlayerTextDrawAlignment(i, RadioTD[i], 2);
		PlayerTextDrawColor(i, RadioTD[i], -1872752385);
		PlayerTextDrawSetShadow(i, RadioTD[i], 0);
		PlayerTextDrawSetOutline(i, RadioTD[i], 1);
		PlayerTextDrawBackgroundColor(i, RadioTD[i], 255);
		PlayerTextDrawFont(i, RadioTD[i], 2);
		PlayerTextDrawSetProportional(i, RadioTD[i], 1);
		if(IsPlayerInAnyVehicle(i))
		{
			LastVeh[i] = GetPlayerVehicleID(i);
			if(GetPlayerState(i) == PLAYER_STATE_DRIVER || GetPlayerState(i) == PLAYER_STATE_PASSENGER)
			{
				if(GetPlayerState(i) == PLAYER_STATE_DRIVER) ArrayID[i] = -1;
				else
				{
					ArrayID[i] = GetPlayerVehicleSeat(i);
					if(ArrayID[i] == 128) Passengers[LastVeh[i]][8] = i;
					else Passengers[LastVeh[i]][ArrayID[i]-1] = i;
				}
				switch(CurrentRadio[LastVeh[i]])
				{
					case 0: PlayerTextDrawSetString(i,RadioTD[i],"Radio Off");
					default:
					{
						format(line,32,"Radio_Title%d",CurrentRadio[LastVeh[i]]);
						GetGVarString(line,str,128);
						PlayerTextDrawSetString(i,RadioTD[i],str);
						format(line,32,"Radio_URL%d",CurrentRadio[LastVeh[i]]);
						GetGVarString(line,str,128);
						PlayAudioStreamForPlayer(i,str);
					}
				}
				PlayerTextDrawShow(i,RadioTD[i]);
				CanChangeRadio[i] = false;
				ChangeTimer[i] = SetTimerEx("RestoreTimer",3500,false,"d",i);
			}
		}
	}
	print("Filterscript has been successfully loaded.");
	return 1;
}

public OnFilterScriptExit()
{
	if(RadioNum != 0)
	{
		new str[32];
		for(new i = 1; i <= RadioNum; i++)
		{
			format(str,32,"Radio_Title%d",i);
			DeleteGVar(str);
			format(str,32,"Radio_URL%d",i);
			DeleteGVar(str);
		}
	}
	if(ScriptLoaded)
	{
		for(new i = 0; i < MAX_PLAYERS; i++)
		{
			if(!IsPlayerConnected(i)) continue;
			if(IsPlayerInAnyVehicle(i)) if(CurrentRadio[GetPlayerVehicleID(i)] != 0) StopAudioStreamForPlayer(i);
		}
	}
	return 0;
}

public OnPlayerConnect(playerid)
{
	if(!ScriptLoaded) return 0;
	RadioTD[playerid] = CreatePlayerTextDraw(playerid, 318.500000, 22.749988, "killllll meeee");
	PlayerTextDrawLetterSize(playerid, RadioTD[playerid], 0.400000, 1.600000);
	PlayerTextDrawAlignment(playerid, RadioTD[playerid], 2);
	PlayerTextDrawColor(playerid, RadioTD[playerid], -1872752385);
	PlayerTextDrawSetShadow(playerid, RadioTD[playerid], 0);
	PlayerTextDrawSetOutline(playerid, RadioTD[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, RadioTD[playerid], 255);
	PlayerTextDrawFont(playerid, RadioTD[playerid], 2);
	PlayerTextDrawSetProportional(playerid, RadioTD[playerid], 1);
	ArrayID[playerid] = -1;
	LastVeh[playerid] = INVALID_VEHICLE_ID;
	CanChangeRadio[playerid] = true;
	return 0;
}

public OnPlayerDisconnect(playerid)
{
	if(!ScriptLoaded) return 0;
	if(ArrayID[playerid] != -1)
	{
		if(ArrayID[playerid] == 128) Passengers[LastVeh[playerid]][8] = INVALID_PLAYER_ID;
		else Passengers[LastVeh[playerid]][ArrayID[playerid]-1] = INVALID_PLAYER_ID;
	}
	if(ChangeTimer[playerid] != -1) KillTimer(ChangeTimer[playerid]);
	return 0;
}

public OnPlayerStateChange(playerid,newstate,oldstate)
{
	if(!ScriptLoaded) return 0;
	if(newstate == PLAYER_STATE_DRIVER)
	{
		LastVeh[playerid] = GetPlayerVehicleID(playerid);
		switch(CurrentRadio[LastVeh[playerid]])
		{
			case 0: PlayerTextDrawSetString(playerid,RadioTD[playerid],"Radio Off");
			default:
			{
				new line[32],str[128];
				format(line,32,"Radio_Title%d",CurrentRadio[LastVeh[playerid]]);
				GetGVarString(line,str,128);
				PlayerTextDrawSetString(playerid,RadioTD[playerid],str);
				format(line,32,"Radio_URL%d",CurrentRadio[LastVeh[playerid]]);
				GetGVarString(line,str,128);
				PlayAudioStreamForPlayer(playerid,str);
			}
		}
		PlayerTextDrawShow(playerid,RadioTD[playerid]);
		CanChangeRadio[playerid] = false;
		ChangeTimer[playerid] = SetTimerEx("RestoreTimer",3500,false,"d",playerid);
	}
	if(oldstate == PLAYER_STATE_DRIVER)
	{
		StopAudioStreamForPlayer(playerid);
		if(ChangeTimer[playerid] != -1)
		{
			KillTimer(ChangeTimer[playerid]);
			ChangeTimer[playerid] = -1;
			PlayerTextDrawHide(playerid,RadioTD[playerid]);
		}
		LastVeh[playerid] = INVALID_VEHICLE_ID;
	}
	if(newstate == PLAYER_STATE_PASSENGER)
	{
		LastVeh[playerid] = GetPlayerVehicleID(playerid);
		ArrayID[playerid] = GetPlayerVehicleSeat(playerid);
		if(ArrayID[playerid] == 128) Passengers[LastVeh[playerid]][8] = playerid;
		else Passengers[LastVeh[playerid]][ArrayID[playerid]-1] = playerid;
		switch(CurrentRadio[LastVeh[playerid]])
		{
			case 0: PlayerTextDrawSetString(playerid,RadioTD[playerid],"Radio Off");
			default:
			{
				new line[32],str[128];
				format(line,32,"Radio_Title%d",CurrentRadio[LastVeh[playerid]]);
				GetGVarString(line,str,128);
				PlayerTextDrawSetString(playerid,RadioTD[playerid],str);
				format(line,32,"Radio_URL%d",CurrentRadio[LastVeh[playerid]]);
				GetGVarString(line,str,128);
				PlayAudioStreamForPlayer(playerid,str);
			}
		}
		PlayerTextDrawShow(playerid,RadioTD[playerid]);
		CanChangeRadio[playerid] = false;
		ChangeTimer[playerid] = SetTimerEx("RestoreTimer",3500,false,"d",playerid);
	}
	if(oldstate == PLAYER_STATE_PASSENGER)
	{
		StopAudioStreamForPlayer(playerid);
		if(ChangeTimer[playerid] != -1)
		{
			KillTimer(ChangeTimer[playerid]);
			ChangeTimer[playerid] = -1;
			PlayerTextDrawHide(playerid,RadioTD[playerid]);
		}
		if(ArrayID[playerid] == 128) Passengers[LastVeh[playerid]][8] = INVALID_PLAYER_ID;
		else Passengers[LastVeh[playerid]][ArrayID[playerid]-1] = INVALID_PLAYER_ID;
		ArrayID[playerid] = -1;
		LastVeh[playerid] = INVALID_VEHICLE_ID;
	}
	return 0;
}

public OnPlayerKeyStateChange(playerid,newkeys,oldkeys)
{
	if(!ScriptLoaded) return 0;
	if(!IsPlayerInAnyVehicle(playerid)) return 0;
	if(newkeys & KEY_YES || newkeys & KEY_NO)
	{
		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
		{
			if(!CanChangeRadio[playerid]) return 0;
			new bool:rf = false;
			if(newkeys & KEY_YES)
			{
				CurrentRadio[LastVeh[playerid]]++;
				if(CurrentRadio[LastVeh[playerid]] > RadioNum)
				{
					CurrentRadio[LastVeh[playerid]] = 0;
					rf = true;
				}
			}
			if(newkeys & KEY_NO)
			{
				CurrentRadio[LastVeh[playerid]]--;
				if(CurrentRadio[LastVeh[playerid]] < 0) CurrentRadio[LastVeh[playerid]] = RadioNum;
				if(CurrentRadio[LastVeh[playerid]] == 0) rf = true;
			}
			if(rf)
			{
				PlayerTextDrawSetString(playerid,RadioTD[playerid],"Radio Off");
				StopAudioStreamForPlayer(playerid);
				for(new i = 0; i < 9; i++)
				{
					if(Passengers[LastVeh[playerid]][i] == INVALID_PLAYER_ID) continue;
					if(!CanChangeRadio[Passengers[LastVeh[playerid]][i]]) continue;
					PlayerTextDrawSetString(Passengers[LastVeh[playerid]][i],RadioTD[Passengers[LastVeh[playerid]][i]],"Radio Off");
					CanChangeRadio[Passengers[LastVeh[playerid]][i]] = false;
					StopAudioStreamForPlayer(Passengers[LastVeh[playerid]][i]);
					PlayerTextDrawShow(Passengers[LastVeh[playerid]][i],RadioTD[Passengers[LastVeh[playerid]][i]]);
					ChangeTimer[Passengers[LastVeh[playerid]][i]] = SetTimerEx("RestoreTimer",3500,false,"d",Passengers[LastVeh[playerid]][i]);
				}
			}
			else
			{
				new line[32],name[32],str[128];
				format(line,32,"Radio_Title%d",CurrentRadio[LastVeh[playerid]]);
				GetGVarString(line,name,32);
				format(line,32,"Radio_URL%d",CurrentRadio[LastVeh[playerid]]);
				GetGVarString(line,str,128);
				CanChangeRadio[playerid] = false;
				StopAudioStreamForPlayer(playerid);
				PlayerTextDrawSetString(playerid,RadioTD[playerid],name);
				PlayAudioStreamForPlayer(playerid,str);
				for(new i = 0; i < 9; i++)
				{
					if(Passengers[LastVeh[playerid]][i] == INVALID_PLAYER_ID) continue;
					if(!CanChangeRadio[Passengers[LastVeh[playerid]][i]]) continue;
					PlayerTextDrawSetString(Passengers[LastVeh[playerid]][i],RadioTD[Passengers[LastVeh[playerid]][i]],name);
					CanChangeRadio[Passengers[LastVeh[playerid]][i]] = false;
					StopAudioStreamForPlayer(Passengers[LastVeh[playerid]][i]);
					PlayAudioStreamForPlayer(Passengers[LastVeh[playerid]][i],str);
					PlayerTextDrawShow(Passengers[LastVeh[playerid]][i],RadioTD[Passengers[LastVeh[playerid]][i]]);
					ChangeTimer[Passengers[LastVeh[playerid]][i]] = SetTimerEx("RestoreTimer",3500,false,"d",Passengers[LastVeh[playerid]][i]);
				}
			}
			PlayerTextDrawShow(playerid,RadioTD[playerid]);
			ChangeTimer[playerid] = SetTimerEx("RestoreTimer",3500,false,"d",playerid);
		}
	}
	return 0;
}

public RestoreTimer(playerid)
{
	CanChangeRadio[playerid] = true;
	PlayerTextDrawHide(playerid,RadioTD[playerid]);
	return 1;
}