-module(herd_memory).

-exports([init/0]).

%% API

init() ->
    %% establish ssh connection
    CN = ssh_helper:connect("172.20.128.2", "dubuntu", "secret_password"),

    %% initialize tmux session
    ssh_helper:open_tmux(CN),

    %% initialize ollama
    ssh_helper:exec_in_tmux(CN, "ollama run samantha-mistral").

    %% wait for ollama to initialize


%% Internal API
