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
        {inference_collector_process, query, HCO} ->
            %% grab just sybil's output without the herdmate outputs
            Output = string:find(HCO, "\n"),

            case Output of
                %% something went wrong
                nomatch ->
                    chat();
                _ ->
                    %% print results
                    io:fwrite("~n# ~s~n~n", [Output]),

                    %% get next query
                    chat()
            end
    end.
