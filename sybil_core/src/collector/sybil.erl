-module(sybil).

-export([chat/0]).

%% @doc Convenience function for an ollama-esque chat loop.
chat() ->
    %% show prompt
    {ok, Query} = io:read("sybil> "),

    %% send message to sybil
    inference_collector:chat(Query),

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
                    io:fwrite("sybil> ~s~n~n# ~s", [Query, Output]),

                    %% get next query
                    chat()
            end
    end.
