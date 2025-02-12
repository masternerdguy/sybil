-module(sybil).

-export([chat/0]).

%% API

%% @doc Convenience function for an ollama-esque chat loop.
chat() ->
    %% show prompt
    Query = io:get_line("sybil> "),

    case Query of
        %% nothing provided - exit prompt
        server_no_data ->
            io:fwrite("no data! exiting chat session.~n");
        %% we got something
        _ ->
            %% pass one
            chat_take(Query),

            %% pass two
            Output = chat_take(Query),

            %% print results
            io:fwrite("~n# ~ts~n~n", [Output]),

            %% get next query
            chat()
    end.

%% Internal API

%% @doc Helper function to send query then block while waiting for output.
chat_take(Query) ->
    %% send query to sybil
    inference_collector:chat(Query),

    %% wait for output from collector
    receive
        {inference_collector_process, query, Output} ->
            %% flush any stray messages
            log_helper:flush_log(),

            %% return result
            Output
    end.
