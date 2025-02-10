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
    sleep(30),

    %% do a clean read on all herdmates
    catch read_herd(),

    %% complete startup
    sybil_core_sup:start_link().

stop(_State) ->
    ok.

%% internal functions

%% @doc Helper function to sleep N seconds.
sleep(Seconds) ->
    timer:sleep(timer:seconds(Seconds)).

%% @doc Helper function to do a smoketest read of all herdmates. 
read_herd() ->
    catch herd_memory:clean_read(),

    sleep(15),
    catch herd_feels:clean_read(),

    sleep(15),
    catch herd_morals:clean_read(),

    sleep(15),
    catch herd_egghead:clean_read(),

    sleep(15),
    catch herd_collector:clean_read().
