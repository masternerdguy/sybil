-module(sybil).

-export([chat/0]).

%% @doc Convenience function for an ollama-esque chat loop.
chat() ->
    %% show prompt
    Query = io:get_line("sybil> "),

    case Query of
        %% nothing provided - exit prompt
        server_no_data ->
            io:fwrite("no data! exiting chat session.~n");
        %% send message to sybil
        _ ->
            inference_collector:chat(Query)
    end,

    %% wait for output from collector
    receive
        {inference_collector_process, query, Output} ->
            %% flush any stray messages
            log_helper:flush_log(),

            %% print results
            io:fwrite("~n# ~ts~n~n", [Output]),

            %% get next query
            chat()
    end.
