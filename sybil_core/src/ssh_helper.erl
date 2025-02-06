-module(ssh_helper).

-export([connect/3, open_tmux/1, exec_in_tmux/2, capture_tmux/1]).

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
    exec(Connection, "tmux send-keys '" ++ replace_all(Command, "'", "") ++ "' Enter").

%% @doc Returns the entire history of the open tmux session for the provided handle.
capture_tmux(Connection) ->
    exec(Connection, "tmux capture-pane -pS -").

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
            read(State ++ [M])
    after 1000 ->
        State
    end.

%% @doc Helper function to replace characters in a list.
replace_all(String, Find, Replace) ->
    case string:find(String, Find) of
        nomatch -> String;
        _ -> 
            X = string:replace(String, Find, Replace),
            replace_all(X, Find, Replace)
    end.
