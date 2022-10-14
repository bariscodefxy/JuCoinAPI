/**
 * Official plugin by Berk
 * 
 * This is a fork of official JuCoin API
 */

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <sqlx>

#define PLUGIN "JuCoin API"
#define VERSION "1.1-d"
#define AUTHOR "bariscodefx"

#define MYSQL_HOST "127.0.0.1"
#define MYSQL_USER "root"
#define MYSQL_PASS ""
#define MYSQL_NAME "JuCoinDB"

new JuCoin[33]
new Handle:g_SqlTuple
new g_SqlErrCode;
new g_SqlError[128];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_SqlTuple = SQL_MakeDbTuple( MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_NAME );
	if( SQL_Connect( g_SqlTuple, g_SqlErrCode, g_SqlError, charsmax(g_SqlError) ) == Empty_Handle )
	{
		server_print( "JuCoin API: Unable connected to database server." );
		server_cmd( "amx pause JuCoin_API" );
	}
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
	

}

public QueryHandler(failstate, Handle:query, error[], errnum, data[], size, Float:queuetime)
{
	if(failstate){
        log_amx("SQL Error: %s (%d)", error, errnum)
        return PLUGIN_HANDLED
    }

    new cache[512];
    while(SQL_MoreResults(query)){
        new coins = SQL_ReadResult(query, SQL_FieldNameToNum( query, "coins" ));

        JuCoin[data[0]] = coins;

        JuCoinLoaded( data[0] );

        SQL_NextRow(query)
    }

	return PLUGIN_HANDLED;
}

JuCoinLoaded(id)
{
	client_cmd(id, "echo ^"JuCoin API - Loaded Your JuCoin's: %i^" ", JuCoin[id] )
}

JuCoinLoad(id)
{
	if( is_user_connected( id ) ) return;
	new szAuth[128];
	new cache[512];
	new data[1];
	data[0] = id;
	get_user_authid(id , szAuth , charsmax(szAuth))
	server_print("%s", szAuth)
	formatex(cache, 511,"SELECT * FROM %s WHERE ( steamid='%s' );", "user", szAuth );
	SQL_ThreadQuery(g_SqlTuple, "QueryHandler", cache, data, sizeof(data) );
}
