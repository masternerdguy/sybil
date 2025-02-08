-module(herd_memory).

-export([start/0, process_init/0]).

%% API

start() ->
    %% spawn process
    PID = spawn(?MODULE, process_init, []),

    %% register process
    register(herd_memory_process, PID).

process_init() ->
    %% establish ssh connection
    log_helper:write_log(?MODULE, self(), "Connecting..."),
    CN = ssh_helper:connect("172.20.128.2", "dubuntu", "secret_password"),

    %% initialize tmux session
    ssh_helper:open_tmux(CN),

    %% initialize ollama
    ssh_helper:exec_in_tmux(CN, "ollama run samantha-mistral"),

    %% wait for ollama to initialize
    ssh_helper:wait_for_prompt(CN),
    log_helper:write_log(?MODULE, self(), "Ready!"),

    %% start listening
    process(CN).

%% Internal API

process(CN) ->
    catch receive
        %% perform a quick dump of the current session
        {PID, dirty_read} ->
            PID ! {herd_memory_process, ssh_helper:capture_tmux(CN)};
        %% perform a clean dump of the current session when the prompt is ready
        {PID, clean_read} ->
            ssh_helper:wait_for_prompt(CN),
            PID ! {herd_memory_process, ssh_helper:capture_tmux(CN)};
        %% performs a quick write to the current session
        {PID, dirty_write, Query} ->
            ssh_helper:exec_in_tmux(CN, Query),
            PID ! {herd_memory_process, dirty_write, done};
        %% perform a clean write to the current session
        {PID, clean_write, Query} ->
            ssh_helper:exec_in_tmux(CN, Query),
            ssh_helper:wait_for_prompt(CN),
            PID ! {herd_memory_process, clean_write, done};
        %% fallback
        M ->
            log_helper:write_log(?MODULE, self(), io_lib:fwrite("got unexpected message ~p", [M]))
    end,
    process(CN).
