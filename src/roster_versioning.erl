%%%----------------------------------------------------------------------
%%% File    : mod_roster.erl
%%% Author  : Pablo Polvorin <pablo.polvorin@process-one.net>
%%% Purpose : Common utility functions for XEP-0237 (Roster Versioning)
%%% Created : 19 Jul 2009 by Pablo Polvorin <pablo.polvorin@process-one.net>
%%%
%%%
%%% ejabberd, Copyright (C) 2009   ProcessOne
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with this program; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%%% 02111-1307 USA
%%%
%%%
%%% @doc The roster versioning follows an all-or-nothing strategy:
%%%            - If the version supplied by the client is the lastest, return an empty response
%%%            - If not, return the entire new roster (with updated version string).
%%%       Roster version is a hash digest of the entire roster.
%%%       No additional data is stored in DB.
%%%----------------------------------------------------------------------
-module(roster_versioning).
-author('pablo.polvorin@process-one.net').

%%API
-export([is_enabled/1, 
	stream_feature/0,
	push_item/5]).


-include("mod_roster.hrl").
-include("jlib.hrl").

%%@doc is roster versioning enabled?
is_enabled(Host) ->
	case gen_mod:is_loaded(Host, mod_roster) of 
		true ->	mod_roster:roster_versioning_enabled(Host);
		false -> mod_roster_odbc:roster_versioning_enabled(Host)
	end.

stream_feature() ->
	{xmlelement, 
		"ver", 
		[{"xmlns", ?NS_ROSTER_VER}], 
		[{xmlelement, "optional", [], []}]}.



   
%% @doc Roster push, calculate and include the version attribute.
%% TODO: don't push to those who didn't load roster
push_item(Server, User, From, Item, RosterVersion)  ->
    	lists:foreach(fun(Resource) ->
			  push_item(User, Server, Resource, From, Item, RosterVersion)
		end, ejabberd_sm:get_user_resources(User, Server)).

push_item(User, Server, Resource, From, Item, RosterVersion) ->
	IQPush = #iq{type = 'set', xmlns = ?NS_ROSTER,
		 id = "push" ++ randoms:get_string(),
		 sub_el = [{xmlelement, "query",
				[{"xmlns", ?NS_ROSTER}, 
				  {"ver", RosterVersion}],
				[mod_roster:item_to_xml(Item)]}]},
	ejabberd_router:route(
		From,
		jlib:make_jid(User, Server, Resource),
		jlib:iq_to_xml(IQPush)).