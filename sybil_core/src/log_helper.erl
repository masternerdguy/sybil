-module(log_helper).

-export([write_log/3, flush_log/0]).

%% API

%% @doc Standardized logging function.
write_log(Module, PID, Message) ->
    %% buld log string
    LS = io_lib:fwrite("~p | [~p] <~p> | ~s~n", [calendar:now_to_universal_time(os:timestamp()), Module, PID, Message]),

    %% write to log file
    file:write_file("sybil.log", LS, [append]).

%% @doc Convenience function to flush the current (shell) buffer to logging.
flush_log() ->
    receive
        M -> 
            write_log(?MODULE, self(), io_lib:format("~p", [M])),
            flush_log()
    after 0 ->
        ok
    end.
