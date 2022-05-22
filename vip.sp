#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Bagout"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma newdecls required

float g_fSavedLocation[MAXPLAYERS + 1][3];
float g_fSavedAngles[MAXPLAYERS + 1][3];

char g_sColour[12][32] =  {"default", "red", "purple", "green", "lime", "lightred", "grey", "yellow", "lightgrey", "lightblue", "blue", "pink"};
char g_sColourID[12][32] =  {"\x01", "\x02", "\x03", "\x04", "\x06", "\x07", "\x08", "\x09", "\x0A", "\x0B", "\x0C", "\x0E"};
int g_iCurrentColour[MAXPLAYERS + 1] = 0;

public Plugin myinfo = 
{
	name = "VIP",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_vip", Command_VIP);
	for (int i = 1; i <= MaxClients; i++)
	{
		g_fSavedLocation[i][0] = 123456.0; 
		g_fSavedLocation[i][1] = 123456.0;
		g_fSavedLocation[i][2] = 123456.0;
		//dont judge me, no player will ever be located at these coordinates on a map by chance and happen to have the code run in that instant.
	}
	
	AddCommandListener(WSCheckVip, "sm_ws"); //intercept weapon skins plugin, to only let vip players use.
	AddCommandListener(ChcekKnife, "sm_knife");
}

public Action ChcekKnife(int client, const char[] command, int args)
{
	if (!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 == ADMFLAG_CUSTOM1))
	{
		PrintToChat(client, "[\x06hotwheels.vip\x01] You need vip to use this feature!");
		PrintToChat(client, "Buy at \x04https://hotwheels.vip");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action WSCheckVip(int client, const char[] command, int args)
{
	if (!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 == ADMFLAG_CUSTOM1))
	{
		PrintToChat(client, "[\x06hotwheels.vip\x01] You need vip to use this feature!");
		PrintToChat(client, "Buy at \x04https://hotwheels.vip");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_VIP(int client, int args)
{
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		SendVIPMenu(client);
	}
	else
	{
		PrintToChat(client, "[\x06hotwheels.vip\x01] You need vip to use this feature!");
		PrintToChat(client, "Buy at \x04https://hotwheels.vip");
	}

}

public Action SendVIPMenu(int client)
{
	Menu menu = new Menu(VIPMenuHandler, MenuAction_Select | MenuAction_Select | MenuAction_End);
	
	menu.SetTitle("VIP MENU");
	
	menu.AddItem("TELEPORTS", "TELEPORTS");
	menu.AddItem("WEAPON SKINS", "WEAPON SKINS");
	menu.AddItem("CHAT COLOURS", "CHAT COLOURS");
	
	SetMenuExitButton(menu, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
	
}

public int VIPMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				SendTeleportMenu(param1);
			}
			case 1:
			{
				FakeClientCommandEx(param1, "sm_ws");
			}
			case 2:
			{
				SendChatColourMenu(param1);
			}

		}
	}

}



public Action SendTeleportMenu(int client)
{
	Menu menu = new Menu(TeleportMenuHandler, MenuAction_Select | MenuAction_End | MenuAction_Cancel);
	
	menu.SetTitle("TELEPORT");
	
	menu.AddItem("Save Location", "Save Location");
	menu.AddItem("Return To Location", "Teleport");
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
	
}

public int  TeleportMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				SaveLocation(param1);
				SendTeleportMenu(param1);
			}
			case 1:
			{
				TryTeleport(param1);
				SendTeleportMenu(param1);
			}			
		}
	}
	if(action == MenuAction_Cancel)
	{
		SendVIPMenu(param1);
	}
}

public Action SaveLocation(int client)
{
	GetClientAbsOrigin(client, g_fSavedLocation[client]);
	GetClientEyeAngles(client, g_fSavedAngles[client]);
	PrintToChat(client, "[\x06hotwheels.vip\x01] Your location has been saved.");
}

public Action TryTeleport(int client)
{
	if (g_fSavedLocation[client][2] == 123456.0 && g_fSavedLocation[client][1] == 123456.0 && g_fSavedLocation[client][0] == 123456.0)
	{
		PrintToChat(client, "[\x06hotwheels.vip\x01] You must save a location first to use this feature");
		return Plugin_Handled;
	}
	if (StuckClient(client))
	{
		PrintToChat(client, "[\x06hotwheels.vip\x01] This location is occupied by another player at the moment");
		return Plugin_Handled;
	}
	float emptyvec[3];
	TeleportEntity(client, g_fSavedLocation[client], g_fSavedAngles[client], emptyvec);
	return Plugin_Handled;
}

bool StuckClient(int client)
{
    float vOrigin[3];
    float vMins[3];
    float vMaxs[3];

    GetClientAbsOrigin(client, vOrigin);
    GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
    GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);

    TR_TraceHullFilter(vOrigin, vOrigin, vMins, vMaxs, MASK_ALL, OnlyPlayers, client);

    return TR_DidHit();
}

public bool OnlyPlayers(int entity, int contentsMask, any data)
{
    if (entity != data && entity > 0 && entity <= MaxClients)
    {
        return true;
    }
    return false;
}


public Action SendChatColourMenu(int client)
{
	Menu menu = new Menu(ChatColourHandler, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
	
	menu.SetTitle("CHAT COLOURS");
	for (int i = 0; i <= 11; i++)
	{
		menu.AddItem(g_sColourID[i], g_sColour[i]);
	}
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ChatColourHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		//char info[8];
		//menu.GetItem(param2, info ,sizeof(info));
		g_iCurrentColour[param1] = param2;
		
	}
	if (action == MenuAction_Cancel)
	{
		SendVIPMenu(param1);
	}

}


public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if (client != 0)
	{
		
		if (StrContains(args, "@") != -1)return Plugin_Handled;
		if (StrContains(args, "/") != -1)return Plugin_Handled;
	
		if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			if (g_iCurrentColour[client] == 0)return Plugin_Continue;
			char Message[256];
			Format(Message, sizeof(Message), "%s %s", g_sColourID[g_iCurrentColour[client]], args);
	
			CPrintToChatAllEx(client, "{teamcolor}%N :{default}%s", client, Message);
			return Plugin_Handled;
		}	
		return Plugin_Continue;
	}
	return Plugin_Continue;
}