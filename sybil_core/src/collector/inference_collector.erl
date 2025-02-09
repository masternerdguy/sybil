-module(inference_collector).

-export([dispatch_query/1]).

%% API

dispatch_query(Query) ->
    %% format query
    FQ = io_lib:format("user query: ~s", [Query]),

    %% dispatch to herd_memory
    query_memory(FQ),

    %% dispatch to herd_feels
    query_feels(FQ),

    %% collect herd_memory result
    MO = latest_memory(),

    %% collect herd_feels result
    FO = latest_feels(),

    %% format for final consumption
    Upward = format_upwards(herd_memory, MO) ++ format_upwards(herd_feels, FO),
    log_helper:write_log(?MODULE, self(), io_lib:format("herdmates input collected | ~s", [Upward])),

    %% dispatch to herd_collector
    query_collector(io_lib:format("~s ~n~n~n ~s", [FQ, Upward])),

    %% collect final herd_collector result
    HCO = latest_collector(),
    log_helper:write_log(?MODULE, self(), io_lib:format("final output | ~s", [HCO])).

%% Internal API

%% @doc Helper function to format a result for final consumption.
format_upwards(Source, Output) ->
    io_lib:format("~n(~p) says -> ~s", [Source, Output]).

%% @doc Helper function to cleanly dispatch a query to the memory herdmate and block until it completes.
query_memory(FQ) ->
    %% dispatch to herd_memory
    herd_memory:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for memory herdmate to finish..."),

    %% wait for completion
    receive
        {herd_memory_process, clean_write, done} -> log_helper:write_log(?MODULE, self(), "memory herdmate is done!")
    end.

%% @doc Helper function to cleanly dispatch a query to the feels herdmate and block until it completes.
query_feels(FQ) ->
    %% dispatch to herd_feels
    herd_feels:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for feels herdmate to finish..."),

    %% wait for completion
    receive
        {herd_feels_process, clean_write, done} -> log_helper:write_log(?MODULE, self(), "feels herdmate is done!")
    end.

%% @doc Helper function to cleanly dispatch a query to the collector herdmate and block until it completes.
query_collector(FQ) ->
    %% dispatch to herd_collector
    herd_collector:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for collector herdmate to finish..."),

    %% wait for completion
    receive
        {herd_collector_process, clean_write, done} -> log_helper:write_log(?MODULE, self(), "collector herdmate is done!")
    end.

%% @doc Helper function to get the latest query result from the memory herdmate.
latest_memory() ->
    %% read herd_memory
    HM = read_memory(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to get the latest query result from the feels herdmate.
latest_feels() ->
    %% read herd_feels
    HM = read_feels(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to get the latest query result from the collector herdmate.
latest_collector() ->
    %% read herd_collector
    HM = read_collector(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to read the entire output of the memory herdmate's session.
read_memory() ->
    %% request clean read of herd_memory
    herd_memory:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for memory herdmate to dump..."),

    %% wait for completion
    receive
        {herd_memory_process, clean_read, Dump} -> 
            log_helper:write_log(?MODULE, self(), "memory herdmate is done!"),
            Dump
    end.

%% @doc Helper function to read the entire output of the feels herdmate's session.
read_feels() ->
    %% request clean read of herd_feels
    herd_feels:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for feels herdmate to dump..."),

    %% wait for completion
    receive
        {herd_feels_process, clean_read, Dump} -> 
            log_helper:write_log(?MODULE, self(), "feels herdmate is done!"),
            Dump
    end.

%% @doc Helper function to read the entire output of the collector herdmate's session.
read_collector() ->
    %% request clean read of herd_collector
    herd_collector:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for collector herdmate to dump..."),

    %% wait for completion
    receive
        {herd_collector_process, clean_read, Dump} -> 
            log_helper:write_log(?MODULE, self(), "collector herdmate is done!"),
            Dump
    end.
