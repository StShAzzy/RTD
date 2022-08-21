/**
* Godmode perk.
* Copyright (C) 2018 Filip Tomaszewski
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//remembers players color/alpha settings
//tells recurring rgba functions to skip weapon setting if true

bool g_bGodActive = false;

int cores[6][3] = {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 230, 0}, {255, 162, 0}, {174, 0 ,255}};

void ResetClientColor(int client) {
	SetEntityRenderColor(client, 255, 255, 255, 255);
}

//#define GODMODE_PARTICLE "utaunt_twinkling_goldsilver_parent"
#define GODMODE_PARTICLE "powerup_supernova_ready"
//#define GODMODE_PARTICLE "utaunt_twinkling_rgb_parent"

int g_iInGodmode = 0;

public void Godmode_Call(int client, Perk perk, bool bApply){
	if(bApply) Godmode_ApplyPerk(client, perk);
	else Godmode_RemovePerk(client);
}

void Godmode_ApplyPerk(int client, Perk perk){
	float fParticleOffset[3] = {0.0, 0.0, 12.0};

	SetEntCache(client, CreateParticle(client, GODMODE_PARTICLE, _, _, fParticleOffset));
	/*float clientOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientOrigin);
	float startPosition[] = { 0.0, 0.0, -40.0 };
	TE_SetupTFParticleEffect(GODMODE_PARTICLE, clientOrigin, startPosition, _, client, PATTACH_ABSORIGIN_FOLLOW);
	TE_SendToAll();*/
	

	int iMode = perk.GetPrefCell("mode");
	switch(iMode){
		case -1: // no self damage
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_NoSelf);
		case 0: // pushback only
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Pushback);
		case 1: // deal self damage
			SDKHook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Self);
	}

	int iUber = perk.GetPrefCell("uber");
	SetIntCache(client, iUber);
	if(iUber) TF2_AddCondition(client, TFCond_UberchargedCanteen);
	g_bGodActive = true;
	//CreateTimer(0.01, OneTimer, client, TIMER_REPEAT);
	g_iInGodmode |= client;
}

void Godmode_RemovePerk(int client){
	KillEntCache(client);

	/*TE_SetupTFParticleEffect("nutsnbolts_upgrade", NULL_VECTOR, .entity = client, .bResetParticles = true);
	TE_SendToAll();

	static int ParticleEffectStop = INVALID_STRING_INDEX;
  	if(ParticleEffectStop == INVALID_STRING_INDEX) {
    int EffectDispatch = FindStringTable("EffectDispatch");
    ParticleEffectStop = FindStringIndex(EffectDispatch, "ParticleEffectStop");
  		}

  	TE_Start("EffectDispatch");
	TE_WriteNum("m_iEffectName", ParticleEffectStop);
  	TE_WriteNum("entindex", client);
  	TE_SendToAll();*/

	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_NoSelf);
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Pushback);
	SDKUnhook(client, SDKHook_OnTakeDamage, Godmode_OnTakeDamage_Self);

	ResetClientColor(client);
	if(GetIntCacheBool(client))
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	g_bGodActive = false;
	g_iInGodmode &= ~client;
}

public Action Godmode_OnTakeDamage_NoSelf(int client, int &iAttacker){
	return Plugin_Handled;
}

public Action Godmode_OnTakeDamage_Pushback(int client, int &iAttacker){
	if(client != iAttacker)
		return Plugin_Handled;

	TF2_AddCondition(client, TFCond_Bonked, 0.01);
	return Plugin_Continue;
}

public Action Godmode_OnTakeDamage_Self(int client, int &iAttacker){
	return client == iAttacker ? Plugin_Continue : Plugin_Handled;
}