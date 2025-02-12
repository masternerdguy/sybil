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
            FirstOutput = chat_take(Query),

            %% truncate the first output to 128 characters
            Trunc = string:substr(FirstOutput, 1, 128),

            %% pass two, including first truncated output
            Output = chat_take(Query ++ io_lib:format(" | ~s | ", [Trunc])),

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
