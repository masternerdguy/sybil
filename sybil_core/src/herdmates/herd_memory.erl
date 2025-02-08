-module(herd_memory).

-export([start/0, process_init/0]).

%% API

%% @doc Starts the ollama instance and listener for this module.
start() ->
    %% spawn process
    PID = spawn(?MODULE, process_init, []),

    %% register process
    register(herd_memory_process, PID).

%% @doc Initialization process which should not be called outside its module.
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
    log_helper:write_log(?MODULE, self(), "Ready for preparation query."),

    %% send preparation query
    ssh_helper:exec_in_tmux(CN, "you are tasked with being the memory for a larger entity. you will receive fragments of information and conversation. you will need to summarize them if asked."),

    %% wait for ollama to initialize
    ssh_helper:wait_for_prompt(CN),
    log_helper:write_log(?MODULE, self(), "Ready for use!"),

    %% start listening
    process(CN).

%% Internal API

%% @doc Worker process that handles incoming messages and responds to the caller.
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
