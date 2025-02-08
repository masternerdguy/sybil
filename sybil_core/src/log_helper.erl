-module(log_helper).

-export([write_log/3, flush_log/0]).

%% API

%% @doc Standardized logging function.
write_log(Module, PID, Message) ->
    io:fwrite("~p | [~p] <~p> | ~s~n", [calendar:now_to_universal_time(os:timestamp()), Module, PID, Message]).

%% @doc Convenience function to flush the current (shell) buffer to logging.
flush_log() ->
    receive
        M -> 
            write_log(?MODULE, self(), io_lib:fwrite("~p", [M])),
            flush_log()
    after 0 ->
        ok
    end.
