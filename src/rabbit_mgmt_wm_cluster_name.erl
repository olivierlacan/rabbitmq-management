%%   The contents of this file are subject to the Mozilla Public License
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%   The Original Code is RabbitMQ Management Plugin.
%%
%%   The Initial Developer of the Original Code is GoPivotal, Inc.
%%   Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.
%%

-module(rabbit_mgmt_wm_cluster_name).

-export([init/1, resource_exists/2, to_json/2,
         content_types_provided/2, content_types_accepted/2,
         is_authorized/2, allowed_methods/2, accept_content/2]).
-export([finish_request/2]).
-export([encodings_provided/2]).

-include("rabbit_mgmt.hrl").
-include_lib("webmachine/include/webmachine.hrl").
-include_lib("amqp_client/include/amqp_client.hrl").

%%--------------------------------------------------------------------
init(_Config) -> {ok, #context{}}.

finish_request(ReqData, Context) ->
    {ok, rabbit_mgmt_cors:set_headers(ReqData, ?MODULE), Context}.

content_types_provided(ReqData, Context) ->
   {[{"application/json", to_json}], ReqData, Context}.

encodings_provided(ReqData, Context) ->
    {[{"identity", fun(X) -> X end},
     {"gzip", fun(X) -> zlib:gzip(X) end}], ReqData, Context}.

content_types_accepted(ReqData, Context) ->
   {[{"application/json", accept_content}], ReqData, Context}.

allowed_methods(ReqData, Context) ->
    {['HEAD', 'GET', 'PUT', 'OPTIONS'], ReqData, Context}.

resource_exists(ReqData, Context) ->
    {true, ReqData, Context}.

to_json(ReqData, Context) ->
    rabbit_mgmt_util:reply(
      [{name, rabbit_nodes:cluster_name()}], ReqData, Context).

accept_content(ReqData, Context) ->
    rabbit_mgmt_util:with_decode(
      [name], ReqData, Context, fun([Name], _) ->
                                        rabbit_nodes:set_cluster_name(
                                          as_binary(Name)),
                                        {true, ReqData, Context}
                                end).

is_authorized(ReqData, Context) ->
    case wrq:method(ReqData) of
        'PUT' -> rabbit_mgmt_util:is_authorized_admin(ReqData, Context);
        _     -> rabbit_mgmt_util:is_authorized(ReqData, Context)
    end.

as_binary(Val) when is_binary(Val) ->
    Val;
as_binary(Val) when is_list(Val) ->
    list_to_binary(Val).
