#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define ADMFLAG_NEEDED ADMFLAG_CUSTOM6

public Plugin:myinfo =
{
	name = "SM Franug Vip Features",
	author = "Franc1sco franug",
	description = "Features for vips",
	version = "2.0",
	url = "http://claninspired.com/"
};

new Handle:trie_armas;

new Handle:timers[MAXPLAYERS+1];

new ACCOUNT_OFFSET;

public OnPluginStart()
{
	trie_armas = CreateTrie();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", RoundEnd);
	
	ACCOUNT_OFFSET = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			OnClientPostAdminCheck(i);
		}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, EventItemPickup2);
}

public OnClientPostAdminCheck(client)
{
	if(GetUserFlagBits(client) & ADMFLAG_NEEDED) timers[client] = CreateTimer(3.0, Darm, client, TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	if(timers[client] != INVALID_HANDLE)
	{
		KillTimer(timers[client]);
		timers[client] = INVALID_HANDLE;
	}
}

public Action:Darm(Handle:timer, any:client)
{
	if(IsPlayerAlive(client))
	{
		new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if(weapon > 0 && (weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)))
		{
			new warray;
			decl String:classname[4];
			//GetEdictClassname(weapon, classname, sizeof(classname));
			Format(classname, 4, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			
			if(GetTrieValue(trie_armas, classname, warray))
			{
				//PrintToChat(client, "municion fijado a %i",warray[1]);
				if(GetReserveAmmo(weapon) != warray) SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", warray);
			}
		}
	}
}

stock GetReserveAmmo(weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
}

public Action:EventItemPickup2(client, weapon)
{
	if(weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY))
	{
		new warray;
		decl String:classname[4];
		//GetEdictClassname(weapon, classname, sizeof(classname));
		Format(classname, 4, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
	
		if(!GetTrieValue(trie_armas, classname, warray))
		{
			warray = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
		
			SetTrieValue(trie_armas, classname, warray);
		}
		else
		{
			if(GetUserFlagBits(client) & ADMFLAG_NEEDED) SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", warray);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetClientTeam(client) < 2) return;
	
	if(!(GetUserFlagBits(client) & ADMFLAG_NEEDED)) return;

	new iEnt;
	
	while ((iEnt = GetPlayerWeaponSlot(client, 3)) != -1)
	{
		RemovePlayerItem(client, iEnt);
		AcceptEntityInput(iEnt, "Kill");
	}
	
	GivePlayerItem(client, "weapon_hegrenade");
	GivePlayerItem(client, "weapon_flashbang");
	GivePlayerItem(client, "weapon_smokegrenade");
	GivePlayerItem(client, "weapon_molotov");
	if(GetClientTeam(client) == CS_TEAM_CT) SetEntProp(client, Prop_Send, "m_bHasDefuser", 1);
	
	while ((iEnt = GetPlayerWeaponSlot(client, 2)) != -1)
	{
		RemovePlayerItem(client, iEnt);
		AcceptEntityInput(iEnt, "Kill");
	}
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_taser");
	
	FakeClientCommand(client,"use weapon_knife");
	
	SetEntData(client, ACCOUNT_OFFSET, GetEntData(client, ACCOUNT_OFFSET)+300);
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CheckMapEnd())
	{
		Pasar();
    }
}

Pasar()
{
	for(new i=1;i<=MaxClients;++i)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) > 1) continue;
		
		if(!(GetUserFlagBits(i) & ADMFLAG_NEEDED)) continue;
		
		ChangeClientTeam(i, GetRandomInt(2, 3));

	}
}


bool:CheckMapEnd()
{
	new win = GetConVarInt(FindConVar("mp_maxrounds"));
	
	if(win > 0)
	{
		win = RoundToNearest(win/2.0);
		
		if(GetTeamScore(CS_TEAM_CT) == win || GetTeamScore(CS_TEAM_T) == win) return true;
		
		return false;
	}
		
	new timeleft;
	GetMapTimeLeft(timeleft);
	if (timeleft <= 0) return true;
	
	return false;
}