%%%-------------------------------------------------------------------
%% @doc sybil_core public API
%% @end
%%%-------------------------------------------------------------------

-module(sybil_core_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    %% enable hot reloading
    sync:go(),

    %% complete startup
    sybil_core_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
