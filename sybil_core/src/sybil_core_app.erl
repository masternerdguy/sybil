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

    %% enable crypto and ssh
    crypto:start(),
    ssh:start(),

    %% delay 30 seconds
    timer:sleep(timer:seconds(30)),

    %% start herdmates
    herd_memory:start(),
    herd_feels:start(),
    herd_collector:start(),

    %% complete startup
    sybil_core_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
