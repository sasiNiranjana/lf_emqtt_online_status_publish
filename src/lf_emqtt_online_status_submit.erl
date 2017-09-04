%%--------------------------------------------------------------------
%% Copyright (c) 2013-2017 EMQ Enterprise, Inc. (http://emqtt.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(lf_emqtt_online_status_submit).

-include_lib("emqttd/include/emqttd.hrl").

-export([load/1, unload/0]).

%% Hooks functions

-export([on_client_connected/3, on_client_disconnected/3]).

%% Called when the plugin application start
load(Env) ->
    emqttd:hook('client.connected', fun ?MODULE:on_client_connected/3, [Env]),
    emqttd:hook('client.disconnected', fun ?MODULE:on_client_disconnected/3, [Env]).

on_client_connected(ConnAck, Client = #mqtt_client{client_id = ClientId}, _Env) ->
    A = binary_part(ClientId,{0,6}),B = <<"Nimbus">>,C = <<"nimbus">>,D = A/=B,E = A/=C,
    if
        D and E ->
            Server=proplists:get_value(server,_Env,"http://localhost:8080/lfservices/api/asset_online_status/emqtt_update_status"),
            ContentType="application/json",
            Message = "{\"bodySerial\":\"" ++ binary_to_list(ClientId) ++ "\",\"status\":true}",
            inets:start(),
            httpc:request(post,{Server,[],ContentType,Message},[],[]),
            io:format("client ~s connected,api is called. connack: ~w~n", [ClientId, ConnAck]);
        true ->
            io:format("client ~s connected, connack: ~w~n", [ClientId, ConnAck])
    end,
    {ok, Client}.

on_client_disconnected(Reason, _Client = #mqtt_client{client_id = ClientId}, _Env) ->
    A = binary_part(ClientId,{0,6}),B = <<"Nimbus">>,C = <<"nimbus">>,D = A/=B,E = A/=C,
    if
        D and E ->
            Server=proplists:get_value(server,_Env,"http://localhost:8080/lfservices/api/asset_online_status/emqtt_update_status"),
            ContentType="application/json",
            Message = "{\"bodySerial\":\"" ++ binary_to_list(ClientId) ++ "\",\"status\":false}",
            inets:start(),
            httpc:request(post,{Server,[],ContentType,Message},[],[]),
            io:format("client ~s disconnected,api is called, reason: ~w~n", [ClientId, Reason]);
        true ->
            io:format("client ~s disconnected, reason: ~w~n", [ClientId, Reason])
    end,
    ok.

%% Called when the plugin application stop
unload() ->
    emqttd:unhook('client.connected', fun ?MODULE:on_client_connected/3),
    emqttd:unhook('client.disconnected', fun ?MODULE:on_client_disconnected/3).
