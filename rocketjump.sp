#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Bagout"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

char g_sShotguns[4][32] =  {"xm1014", "sawedoff", "nova", "mag7"};

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Rocket Jump",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("weapon_fire", OnPlayerShot);
}

public Action OnPlayerShot(Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char pname[32];
	GetClientName(client, pname, sizeof(pname));
	char weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (IsShotgun(weapon))
	{
		FindWall(client);
	}
}

public void FindWall(int client)
{
	float EyePos[3];
	float EyeAngles[3];
	float PlayerPos[3];
	
	GetClientEyePosition(client, EyePos);
	GetClientEyeAngles(client, EyeAngles);
	GetClientAbsOrigin(client, PlayerPos);
	
	float fwd[3];
	GetAngleVectors(EyeAngles, fwd, NULL_VECTOR, NULL_VECTOR);
	//Test(client, fwd);
	TR_TraceRayFilter(EyePos, EyeAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);
	if (TR_DidHit())
	{
		float EndPos[3];
		TR_GetEndPosition(EndPos);
		float dist = GetVectorDistance(PlayerPos, EndPos);
		if (dist <= 100.0)
		{
			TryLaunchPlayer(client, dist, PlayerPos, EndPos, fwd);
		}
	}
}

public void TryLaunchPlayer(int client, float distance, float PlayerPosition[3], float ImpactLocation[3], float fwd[3])
{
	float vec[3];
	MakeVectorFromPoints(PlayerPosition, ImpactLocation, vec);
	NormalizeVector(vec, vec);
	
	ScaleVector(fwd, -300.0);
	
	float PlayerVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", PlayerVel);
	
	float NewVel[3];
	AddVectors(PlayerVel, fwd, NewVel);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NewVel);
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity != data && !(0 <= entity <= MaxClients);
}

bool IsShotgun(const char[] weapon)
{
	for (int i; i <= 3; i++)
	{	
		if (StrEqual(weapon[7], g_sShotguns[i]))
		{
			return true;
		}
	}
	return false;
}		