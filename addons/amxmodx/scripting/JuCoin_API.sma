/**
 * Official plugin by Berk
 * 
 * This is a fork of official JuCoin API
 */

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <nvault>

#define PLUGIN "JuCoin API"
#define VERSION "1.1-d"
#define AUTHOR "bariscodefx"

new JuCoin[33]
new Coin_Vault

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_natives()
{
	register_native("get_user_jucoin", "native_get_user_jucoin", 1)
	register_native("set_user_jucoin", "native_set_user_jucoin", 1)
}


// Save & Load & JuCoin
public client_connect(id)
{
	JuCoinLoad(id)
}

public client_putinserver(id)
{
	set_task(2.0, "JuCoinAuto", id, _, _, "b")
}

public client_disconnected( id )
{
	remove_task( id );
}

public JuCoinAuto(id)
{
	JuCoinSave(id)
}


// JuCoin Natives

// Get User JuCoin
public native_get_user_jucoin(id)
{
	return JuCoin[id]
}

// Set User JuCoin
public native_set_user_jucoin(id, amount)
{
	JuCoin[id] = amount
}

// End of JuCoin Natives


public plugin_cfg()
{
	Coin_Vault = nvault_open("JuCoin")

	if ( Coin_Vault == INVALID_HANDLE )
		set_fail_state( "Error opening JuCoin nVault, file does not exist!" )
}

// Save & Load | JuCoin's

JuCoinSave(id)
{
	if( is_user_connected( id ) ) return;

	new szAuth[33];
	new szKey[64];
	
	get_user_authid(id , szAuth , charsmax(szAuth))
	formatex(szKey , 63 , "%s-ID" , szAuth)
	
	new szData[256]
		
	formatex(szData , 255 , "%i#", JuCoin[id])
	
	nvault_set(Coin_Vault, szKey, szData)
}

JuCoinLoad(id)
{
	if( is_user_connected( id ) ) return;

	new szAuth[33];
	new szKey[40];
	
	get_user_authid(id , szAuth , charsmax(szAuth))
	formatex(szKey , 63 , "%s-ID" , szAuth)
	
	new szData[256];
	
	formatex(szData , 255 , "%i#", JuCoin[id])
	
	nvault_get(Coin_Vault, szKey, szData, 255)
	
	replace_all(szData , 255, "#", " ")
	new JC[32]
	parse(szData, JC, 31)
	JuCoin[id] = str_to_num(JC)
	
	client_cmd(id, "echo ^"JuCoin API - Loaded Your JuCoin's: %i^" ", JuCoin[id] )
}
