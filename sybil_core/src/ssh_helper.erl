-module(ssh_helper).

-export([connect/3, open_tmux/1, exec_in_tmux/2, capture_tmux/1, wait_for_prompt/1]).

%% @doc Establishes an SSH connection to the target, returning its handle.
connect(IP, User, Password) ->
    %% open connection
    {ok, CN} = ssh:connect(IP, 22,
     [{user, User}, {password, Password},
      {silently_accept_hosts, true}]),
    
    %% return connection
    CN.

%% @doc Opens a tmux session using the provided connection handle.
open_tmux(Connection) ->
    exec(Connection, "tmux new-session -s ollama -d").

%% @doc Executes a command in the open tmux session for the provided handle.
exec_in_tmux(Connection, Command) ->
    exec(Connection, "tmux send-keys '" ++ replace_unsafe(Command) ++ "' Enter").

%% @doc Returns the entire history of the open tmux session for the provided handle.
capture_tmux(Connection) ->
    %% get dump from tmux
    Dump = exec(Connection, "tmux capture-pane -pS -"),

    %% return concatenated string
    tmux_join(Dump).

%% @doc Blocks until the ollama prompt is available for input.
wait_for_prompt(Connection) ->
    %% get tmux output
    TX = capture_tmux(Connection),

    %% reverse output
    TXR = lists:reverse(TX),

    %% get termination sequence
    TSX = reversed_terminator(),

    %% get substring of reversed output
    SS = string:substr(TXR, 1, length(TSX)),

    %% check value
    case SS of
        TSX -> done;
        _ -> wait_for_prompt(Connection)
    end.

%% Internal API

%% @doc Executes a raw shell command in the provided connection handle.
exec(Connection, Command) ->
    %% get channel
    {ok, CR} = ssh_connection:session_channel(Connection, 1000),
    
    %% send message
    ssh_connection:exec(Connection, CR, Command, 1000),

    %% read result
    read([]).

%% @doc Reads the raw result buffer line by line.
read(State) ->
    receive
        M ->
            %% make sure this is an ssh message
            case element(1, M) of
                %% use message
                ssh_cm ->
                    read(State ++ [M]);
                %% discard message
                _ -> read(State)
            end
    after 1000 ->
        State
    end.

%% @doc Helper function to replace unsafe characters in a list.
replace_unsafe(String) ->
    %% remove single quotes
    NQ = replace_all(String, "'", ""),

    %% remove carriage returns
    NC = replace_all(NQ, "\r", ""),

    %% replace line feed with space
    NL = replace_all(NC, "\n", " "),

    %% return result
    NL.

%% @doc Helper function to replace characters in a list.
replace_all(String, Find, Replace) ->
    case string:find(String, Find) of
        nomatch -> String;
        _ -> 
            X = string:replace(String, Find, Replace),
            replace_all(X, Find, Replace)
    end.

%% @doc Returns the joined text from a tmux dump.
tmux_join(Dump) ->
    %% get rid of unwanted parts
    LX = lists:map(fun (X) -> {_, _, Q} = X, Q end, Dump),

    %% keep data parts
    DX = lists:filter(fun (X) -> element(1, X) == data end, LX),

    %% convert to trimmed strings
    SX = lists:map(fun(X) -> {_, _, _, Q} = X, binary_to_list(Q) end, DX),
    TX = lists:map(fun(X) -> string:trim(X) end, SX),

    %% concat strings
    lists:concat(TX).

%% @doc Returns the reversed ready prompt sequence.
reversed_terminator() ->
    ")pleh rof ?/( egassem a dneS >>>".
