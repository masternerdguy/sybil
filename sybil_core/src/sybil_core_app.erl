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

    %% flush the buffer
    log_helper:flush_log(),

    %% start inference collector
    inference_collector:start(),

    %% send an awakening message to sybil
    io:fwrite("asking sybil to awake... then you can chat!~n"),
    inference_collector:chat("hello sybil - do you know who you are?"),

    %% complete startup
    sybil_core_sup:start_link(),

    %% flush the buffer
    log_helper:flush_log(),

    %% enter chat loop
    sybil:chat().

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
    sleep(20),

    %% start herd_feels with a delay
    herd_feels:start(),
    sleep(20),

    %% start herd_morals with a delay
    herd_morals:start(),
    sleep(20),

    %% start herd_egghead with a delay
    herd_egghead:start(),
    sleep(20),

    %% start herd_tasker with a delay
    herd_tasker:start(),
    sleep(20),

    %% start herd_collector with a delay
    herd_collector:start(),
    sleep(30).

%% @doc Helper function to block until all herdmates are awake.
wait_awake() ->
    %% there is a real chance this could fail for long running initializations, and that is fine
    catch try
        io:fwrite("sending wake signals...~n"),

        %% send awake signals
        herd_memory:awake(),
        herd_feels:awake(),
        herd_morals:awake(),
        herd_egghead:awake(),
        herd_tasker:awake(),
        herd_collector:awake(),

        Timeout = 15000,

        %% wait for herd_memory
        receive
            {herd_memory_process, indeed} -> io:fwrite("got signal from herd_memory!~n")
        after Timeout ->
            %% try again
            throw("no wake response for herd_memory yet...")
        end,

        %% wait for herd_feels
        receive
            {herd_feels_process, indeed} -> io:fwrite("got signal from herd_feels!~n")
        after Timeout ->
            %% try again
            throw("no wake response for herd_feels yet...")
        end,

        %% wait for herd_morals
        receive
            {herd_morals_process, indeed} -> io:fwrite("got signal from herd_morals!~n")
        after Timeout ->
            %% try again
            throw("no wake response for herd_morals yet...")
        end,

        %% wait for herd_egghead
        receive
            {herd_egghead_process, indeed} -> io:fwrite("got signal from herd_egghead!~n")
        after Timeout ->
            %% try again
            throw("no wake response for herd_egghead yet...")
        end,

        %% wait for herd_tasker
        receive
            {herd_tasker_process, indeed} -> io:fwrite("got signal from herd_tasker!~n")
        after Timeout ->
            %% try again
            throw("no wake response for herd_tasker yet...")
        end,

        %% wait for herd_collector
        receive
            {herd_collector_process, indeed} -> io:fwrite("got signal from herd_collector!~n")
        after Timeout ->
            %% try again
            throw("no wake response for herd_collector yet...")
        end
    of
        %% success!
        _ -> io:fwrite("got all signals from herdmates!~n")
    catch
        %% wait longer
        _ -> wait_awake();
        %% wait longer
        _:_ -> wait_awake()
    end.
