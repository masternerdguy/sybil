-module(herd_feels).

-export([
    start/0, process_init/0, dirty_read/0, clean_read/0, dirty_write/1, clean_write/1
]).

%% API

%% @doc Starts the ollama instance and listener for this module.
start() ->
    %% spawn process
    PID = spawn(?MODULE, process_init, []),

    %% register process
    register(herd_feels_process, PID),

    %% return handle
    herd_feels_process.

%% @doc Requests a dirty read of the session.
dirty_read() ->
    herd_feels_process ! {self(), dirty_read}.

%% @doc Requests a clean read of the session.
clean_read() ->
    herd_feels_process ! {self(), clean_read}.

%% @doc Requests a dirty write to the session.
dirty_write(Query) ->
    herd_feels_process ! {self(), dirty_write, Query}.

%% @doc Requests a clean write to the session.
clean_write(Query) ->
    herd_feels_process ! {self(), clean_write, Query}.

%% @doc Initialization process which should not be called outside its module.
process_init() ->
    %% establish ssh connection
    log_helper:write_log(?MODULE, self(), "Connecting..."),
    CN = ssh_helper:connect("172.20.128.3", "dubuntu", "secret_password"),

    %% initialize tmux session
    ssh_helper:open_tmux(CN),

    %% initialize ollama
    ssh_helper:exec_in_tmux(CN, run_cmd()),

    %% wait for ollama to initialize
    ssh_helper:wait_for_prompt(CN),
    log_helper:write_log(?MODULE, self(), "Ready for preparation query."),

    %% send preparation query
    ssh_helper:exec_in_tmux(CN, setup_query()),

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
            PID ! {herd_feels_process, dirty_read, ssh_helper:capture_tmux(CN)};
        %% perform a clean dump of the current session when the prompt is ready
        {PID, clean_read} ->
            ssh_helper:wait_for_prompt(CN),
            PID ! {herd_feels_process, clean_read, ssh_helper:capture_tmux(CN)};
        %% performs a quick write to the current session
        {PID, dirty_write, Query} ->
            ssh_helper:exec_in_tmux(CN, Query),
            PID ! {herd_feels_process, dirty_write, done};
        %% perform a clean write to the current session
        {PID, clean_write, Query} ->
            ssh_helper:exec_in_tmux(CN, Query),
            ssh_helper:wait_for_prompt(CN),
            PID ! {herd_feels_process, clean_write, done};
        %% fallback
        M ->
            log_helper:write_log(?MODULE, self(), io_lib:format("got unexpected message ~p", [M]))
    end,
    process(CN).

%% @doc Query to prepare the model for its summarization tasks.
setup_query() ->
    "your feelings are important and should be shared openly. ".

%% @doc Command to start the model.
run_cmd() ->
    "ollama run samantha-mistral".
