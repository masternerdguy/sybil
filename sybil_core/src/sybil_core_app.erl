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
    sleep(15),

    %% initialize herdmates
    setup_herd(),

    %% wait for herdmates
    wait_awake(),

    %% complete startup
    sybil_core_sup:start_link().

stop(_State) ->
    ok.

%% internal functions

%% @doc Helper function to sleep N seconds.
sleep(Seconds) ->
    timer:sleep(timer:seconds(Seconds)).

%% @doc Helper function to initialize th herd.
setup_herd() ->
    %% start herd_memory with a delay
    herd_memory:start(),
    sleep(30),

    %% start herd_feels with a delay
    herd_feels:start(),
    sleep(30),

    %% start herd_morals with a delay
    herd_morals:start(),
    sleep(30),

    %% start herd_egghead with a delay
    herd_egghead:start(),
    sleep(30),

    %% start herd_collector with a delay
    herd_collector:start(),
    sleep(30).

%% @doc Helper function to block until all herdmates are awake.
wait_awake() ->
    %% send awake signals
    herd_memory:awake(),
    herd_feels:awake(),
    herd_morals:awake(),
    herd_egghead:awake(),
    herd_collector:awake(),

    %% wait for herd_memory
    receive
        {herd_memory_process, indeed} -> done
    end,

    %% wait for herd_feels
    receive
        {herd_feels_process, indeed} -> done
    end,

    %% wait for herd_morals
    receive
        {herd_morals_process, indeed} -> done
    end,

    %% wait for herd_egghead
    receive
        {herd_egghead_process, indeed} -> done
    end,

    %% wait for herd_collector
    receive
        {herd_collector_process, indeed} -> done
    end.
