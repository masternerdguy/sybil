-module(ssh_helper).

-export([connect/0, new_tmux/1, exec_in_tmux/2, capture_tmux/1, exec/2]).

connect() ->
    %% open connection
    {ok, CN} = ssh:connect("172.20.128.2", 22,
     [{user, "dubuntu"}, {password, "secret_password"},
      {silently_accept_hosts, true}]),
    
    %% return connection
    CN.

new_tmux(Connection) ->
    ssh_helper:exec(Connection, "tmux new-session -s ollama -d").

exec_in_tmux(Connection, Command) ->
    ssh_helper:exec(Connection, "tmux send-keys '" ++ replace_all(Command, "'", "") ++ "' Enter").

capture_tmux(Connection) ->
    ssh_helper:exec(Connection, "tmux capture-pane -pS -").

exec(Connection, Command) ->
    %% get channel
    {ok, CR} = ssh_connection:session_channel(Connection, 1000),
    
    %% send message
    ssh_connection:exec(Connection, CR, Command, 1000),

    %% read result
    read([]).

%% Internal API

read(State) ->
    receive
        M -> 
            read(State ++ [M])
    after 1000 ->
        State
    end.

replace_all(String, Find, Replace) ->
    case string:find(String, Find) of
        nomatch -> String;
        _ -> 
            X = string:replace(String, Find, Replace),
            replace_all(X, Find, Replace)
    end.
