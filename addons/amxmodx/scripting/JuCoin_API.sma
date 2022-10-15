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
new JuTokens[33][128];
new Handle:g_SqlTuple
new Handle:g_SqlConnection
new g_SqlErrCode;
new g_SqlError[128];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("say /jutoken", "cmd_jutoken");

	g_SqlTuple = SQL_MakeDbTuple( MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_NAME );
	g_SqlConnection = SQL_Connect( g_SqlTuple, g_SqlErrCode, g_SqlError, charsmax(g_SqlError) )
	if( g_SqlConnection == Empty_Handle )
	{
		server_print( "JuCoin API: Unable connected to database server." );
		server_cmd( "amxx pause JuCoin_API" );
	}
}

public plugin_natives()
{
	register_native("get_user_jucoin", "native_get_user_jucoin", 1)
	register_native("set_user_jucoin", "native_set_user_jucoin", 1)
}

public cmd_jutoken(id)
{
	client_print(id, print_chat, "Your JuToken is: %s", JuTokens[id]);

	return PLUGIN_HANDLED;
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
	JuCoinSave( id );
	remove_task( id );
}

public JuCoinAuto(id)
{
	JuCoinLoad(id)
	JuCoinHud(id)
}

public JuCoinHud(id)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED
	set_hudmessage(_, _, _, _, 0.75);
	show_hudmessage(id, "JuCoins: %i", JuCoin[id])
	return PLUGIN_HANDLED;
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
	JuCoinSave(id);
}

// End of JuCoin Natives

// Save & Load | JuCoin's

JuCoinSave(id)
{
	new szAuth[128];
	new cache[512];
	get_user_authid(id , szAuth , charsmax(szAuth))
	if( JuCoin[id] )
	{
		formatex( cache, 511, "UPDATE %s SET coins='%i' WHERE steamid='%s'", "user", JuCoin[id], szAuth )
		SQL_ThreadQuery( g_SqlTuple, "QueryHandler_f", cache );
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public QueryHandler(failstate, Handle:query, error[], errnum, data[], size, Float:queuetime)
{
	if(failstate){
        log_amx("SQL Error: %s (%d)", error, errnum)
        return PLUGIN_HANDLED
    }

    while(SQL_MoreResults(query)){
    	new token[128];
        new coins = SQL_ReadResult(query, SQL_FieldNameToNum( query, "coins" ));
        SQL_ReadResult(query, SQL_FieldNameToNum( query, "token" ), token, charsmax(token));

        if ( coins != JuCoin[data[0]] )
        {
	        JuCoin[data[0]] = coins;

	        JuCoinLoaded( data[0] );
	    }
	    formatex( JuTokens[data[0]], 127, "%s", token );

        SQL_NextRow(query)
        return PLUGIN_HANDLED;
    }

    // user not found so create it
    new cache[512];
    new szAuth[128];
	get_user_authid(data[0] , szAuth , charsmax(szAuth))
	formatex(cache, 511, "INSERT INTO %s (steamid,password,token,coins,registertime) VALUES('%s','%s','%s','%i','%i');", "user", szAuth, "", generateToken(), 0, get_systime() );
    SQL_ThreadQuery( g_SqlTuple, "QueryHandler_f", cache );

	return PLUGIN_HANDLED;
}

public QueryHandler_f(failstate, Handle:query, error[], errnum, data[], size, Float:queuetime)
{
	if(failstate){
        log_amx("SQL Error: %s (%d)", error, errnum)
        return PLUGIN_HANDLED
    }
	return PLUGIN_HANDLED;
}

public generateToken()
{
	new chars[] = {
		"x", "h", "t", "y", "!", "x", "u"
	};
	new text[128];
	new writed;
	for( new i = 0; i < 3; i++ )
	{
		writed += formatex(text, charsmax(text) - writed, "%s%s", text, chars[random(sizeof(chars))]);
	}
	writed += formatex(text, charsmax(text) - writed, "%s%i", text, get_systime());
	return text;
}

JuCoinLoaded(id)
{
	client_cmd(id, "echo ^"JuCoin API - Loaded Your JuCoin's: %i^" ", JuCoin[id] )
}

JuCoinLoad(id)
{
	new szAuth[128];
	new cache[512];
	new data[1];
	data[0] = id;
	get_user_authid(id , szAuth , charsmax(szAuth))
	formatex(cache, 511,"SELECT * FROM %s WHERE ( steamid='%s' );", "user", szAuth );
	SQL_ThreadQuery(g_SqlTuple, "QueryHandler", cache, data, sizeof(data) );
}
