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

    %% delay 15 seconds so containers can initialize properly
    timer:sleep(timer:seconds(15)),

    %% start herd_memory with a delay
    herd_memory:start(),
    timer:sleep(timer:seconds(15)),

    %% start herd_feels with a delay
    herd_feels:start(),
    timer:sleep(timer:seconds(15)),

    %% start herd_morals with a delay
    herd_morals:start(),
    timer:sleep(timer:seconds(15)),

    %% start herd_coder with a delay
    herd_coder:start(),
    timer:sleep(timer:seconds(15)),

    %% start herd_collector with a delay
    herd_collector:start(),
    timer:sleep(timer:seconds(15)),

    %% complete startup
    sybil_core_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
