-module(log_helper).

-export([write_log/3]).

%% API

%% @doc Standardized logging function.
write_log(Module, PID, Message) ->
    io:fwrite("~p | [~p] <~p> | ~s~n", [calendar:now_to_universal_time(os:timestamp()), Module, PID, Message]).
