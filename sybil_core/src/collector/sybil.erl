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

            %% truncate the first output's end
            TruncEnd = reverse_substr(FirstOutput, 1, 512),

            %% pass two, including first truncated output
            Output = chat_take(Query ++ io_lib:format(" | sybil's intermediate thoughts: ~s | ", [TruncEnd]) ++ Query),

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

%% @doc Helper function to get a substring from the end.
reverse_substr(Str, Start, End) ->
    %% reverse string
    RS = lists:reverse(Str),

    %% get substring
    SS = string:substr(RS, Start, End),

    %% reverse and return
    XS = lists:reverse(SS),
    XS.
