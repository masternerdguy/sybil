-module(herd_collector).

-export([dispatch_query/1]).

%% API

dispatch_query(Query) ->
    %% format query
    FQ = io_lib:format("user query: ~s", [Query]),

    %% dispatch to herd_memory
    herd_memory:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for memory herdmate to finish..."),

    %% wait for completion
    receive
        {herd_memory_process, clean_write, done} -> log_helper:write_log(?MODULE, self(), "memory herdmate is done!")
    end,

    %% dispatch to herd_feels
    herd_feels:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for feels herdmate to finish..."),

    %% wait for completion
    receive
        {herd_feels_process, clean_write, done} -> log_helper:write_log(?MODULE, self(), "feels herdmate is done!")
    end.

%% Internal API
