-module(inference_collector).

-export([start/0, chat/1, process_init/0]).

%% API

%% @doc Starts the inference collector which facilitates sybil's conversations.
start() ->
    %% spawn process
    PID = spawn(?MODULE, process_init, []),

    %% register process
    register(inference_collector_process, PID),

    %% return handle
    inference_collector_process.

%% @doc Initialization process which should not be called outside its module.
process_init() ->
    %% start listening
    process().

%% @doc Sends a chat message to sybil - the response will be returned to the calling process.
chat(Query) ->
    inference_collector_process ! {self(), query, Query}.

%% Internal API

%% @doc Worker process which handles chatting with sybil.
process() ->
    catch receive
        %% send sybil a new message and return her eventual response
        {PID, query, Query} ->
            %% get timestamp
            DT = calendar:now_to_universal_time(os:timestamp()),

            %% format query
            FQ = io_lib:format("[datetime: ~p] user query: ~s", [DT, Query]),

            %% dispatch to herd_memory
            query_memory(
                io_lib:format(
                    "please provide relevant information for this user request from known fragments: ~s",
                    [FQ]
                )
            ),

            %% dispatch to herd_feels
            query_feels(FQ),

            %% dispatch to herd_morals
            query_morals(FQ),

            %% dispatch to herd_egghead
            query_egghead(FQ),

            %% dispatch to herd_tasker
            query_tasker(FQ),

            %% collect herd_memory result
            MO = latest_memory(),

            %% collect herd_feels result
            FO = latest_feels(),

            %% collect herd_morals result
            MOO = latest_morals(),

            %% collect herd_egghead result
            CO = latest_egghead(),

            %% collect herd_tasker result
            EO = latest_tasker(),

            %% aggregate upward strings in a list
            UpwardList = [
                format_upwards(herd_morals, MOO),
                format_upwards(herd_feels, FO),
                format_upwards(herd_egghead, CO),
                format_upwards(herd_tasker, EO),
                format_upwards(herd_memory, MO)
            ],

            %% shuffle the upward list
            ShuffledList = shuffle(UpwardList),

            %% format for final consumption
            Upward =
                string:join(ShuffledList, " "),

            log_helper:write_log(
                ?MODULE, self(), io_lib:format("herdmates input collected | ~s", [Upward])
            ),

            %% dispatch to herd_collector
            query_collector(io_lib:format("~s|~s", [FQ, Upward])),

            %% collect final herd_collector result
            HCO = latest_collector(),
            log_helper:write_log(?MODULE, self(), io_lib:format("final output | ~n~s", [HCO])),

            %% back propagate the result to herd_memory
            log_helper:write_log(
                ?MODULE, self(), io_lib:format("sending decision to herd_memory | ~s", [HCO])
            ),

            query_memory(
                io_lib:format(
                    "please remember sybil's decision from this conversation and summarize it as bullet points for future sessions: ~s",
                    [HCO]
                )
            ),

            %% return result from herd_collector
            HCO,
            PID ! {inference_collector_process, query, HCO};
        %% fallback
        M ->
            log_helper:write_log(?MODULE, self(), io_lib:format("got unexpected message ~p", [M]))
    end,
    process().

%% @doc Helper function to format a result for final consumption.
format_upwards(Source, Output) ->
    io_lib:format(" ~n(~p) says -> ~s | ", [Source, Output]).

%% @doc Helper function to cleanly dispatch a query to the memory herdmate and block until it completes.
query_memory(FQ) ->
    %% dispatch to herd_memory
    herd_memory:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for memory herdmate to finish..."),

    %% wait for completion
    receive
        {herd_memory_process, clean_write, done} ->
            log_helper:write_log(?MODULE, self(), "memory herdmate is done!")
    end.

%% @doc Helper function to cleanly dispatch a query to the feels herdmate and block until it completes.
query_feels(FQ) ->
    %% dispatch to herd_feels
    herd_feels:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for feels herdmate to finish..."),

    %% wait for completion
    receive
        {herd_feels_process, clean_write, done} ->
            log_helper:write_log(?MODULE, self(), "feels herdmate is done!")
    end.

%% @doc Helper function to cleanly dispatch a query to the collector herdmate and block until it completes.
query_collector(FQ) ->
    %% dispatch to herd_collector
    herd_collector:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for collector herdmate to finish..."),

    %% wait for completion
    receive
        {herd_collector_process, clean_write, done} ->
            log_helper:write_log(?MODULE, self(), "collector herdmate is done!")
    end.

%% @doc Helper function to cleanly dispatch a query to the morals herdmate and block until it completes.
query_morals(FQ) ->
    %% dispatch to herd_morals
    herd_morals:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for morals herdmate to finish..."),

    %% wait for completion
    receive
        {herd_morals_process, clean_write, done} ->
            log_helper:write_log(?MODULE, self(), "morals herdmate is done!")
    end.

%% @doc Helper function to cleanly dispatch a query to the egghead herdmate and block until it completes.
query_egghead(FQ) ->
    %% dispatch to herd_egghead
    herd_egghead:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for egghead herdmate to finish..."),

    %% wait for completion
    receive
        {herd_egghead_process, clean_write, done} ->
            log_helper:write_log(?MODULE, self(), "egghead herdmate is done!")
    end.

%% @doc Helper function to cleanly dispatch a query to the tasker herdmate and block until it completes.
query_tasker(FQ) ->
    %% dispatch to herd_tasker
    herd_tasker:clean_write(FQ),
    log_helper:write_log(?MODULE, self(), "waiting for tasker herdmate to finish..."),

    %% wait for completion
    receive
        {herd_tasker_process, clean_write, done} ->
            log_helper:write_log(?MODULE, self(), "tasker herdmate is done!")
    end.

%% @doc Helper function to get the latest query result from the memory herdmate.
latest_memory() ->
    %% read herd_memory
    HM = read_memory(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to get the latest query result from the feels herdmate.
latest_feels() ->
    %% read herd_feels
    HM = read_feels(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to get the latest query result from the collector herdmate.
latest_collector() ->
    %% read herd_collector
    HM = read_collector(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to get the latest query result from the morals herdmate.
latest_morals() ->
    %% read herd_morals
    HM = read_morals(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to get the latest query result from the egghead herdmate.
latest_egghead() ->
    %% read herd_egghead
    HM = read_egghead(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to get the latest query result from the tasker herdmate.
latest_tasker() ->
    %% read herd_tasker
    HM = read_tasker(),

    %% split and reverse to get output sections
    HX = lists:reverse(string:split(HM, "\n\n>>>", all)),

    %% check length
    case length(HX) >= 2 of
        %% no output yet
        false -> none;
        %% return last output
        _ -> lists:nth(2, HX)
    end.

%% @doc Helper function to read the entire output of the memory herdmate's session.
read_memory() ->
    %% request clean read of herd_memory
    herd_memory:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for memory herdmate to dump..."),

    %% wait for completion
    receive
        {herd_memory_process, clean_read, Dump} ->
            log_helper:write_log(?MODULE, self(), "memory herdmate is done!"),
            Dump
    end.

%% @doc Helper function to read the entire output of the feels herdmate's session.
read_feels() ->
    %% request clean read of herd_feels
    herd_feels:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for feels herdmate to dump..."),

    %% wait for completion
    receive
        {herd_feels_process, clean_read, Dump} ->
            log_helper:write_log(?MODULE, self(), "feels herdmate is done!"),
            Dump
    end.

%% @doc Helper function to read the entire output of the collector herdmate's session.
read_collector() ->
    %% request clean read of herd_collector
    herd_collector:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for collector herdmate to dump..."),

    %% wait for completion
    receive
        {herd_collector_process, clean_read, Dump} ->
            log_helper:write_log(?MODULE, self(), "collector herdmate is done!"),
            Dump
    end.

%% @doc Helper function to read the entire output of the morals herdmate's session.
read_morals() ->
    %% request clean read of herd_morals
    herd_morals:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for morals herdmate to dump..."),

    %% wait for completion
    receive
        {herd_morals_process, clean_read, Dump} ->
            log_helper:write_log(?MODULE, self(), "morals herdmate is done!"),
            Dump
    end.

%% @doc Helper function to read the entire output of the egghead herdmate's session.
read_egghead() ->
    %% request clean read of herd_egghead
    herd_egghead:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for egghead herdmate to dump..."),

    %% wait for completion
    receive
        {herd_egghead_process, clean_read, Dump} ->
            log_helper:write_log(?MODULE, self(), "egghead herdmate is done!"),
            Dump
    end.

%% @doc Helper function to read the entire output of the tasker herdmate's session.
read_tasker() ->
    %% request clean read of herd_tasker
    herd_tasker:clean_read(),
    log_helper:write_log(?MODULE, self(), "waiting for tasker herdmate to dump..."),

    %% wait for completion
    receive
        {herd_tasker_process, clean_read, Dump} ->
            log_helper:write_log(?MODULE, self(), "tasker herdmate is done!"),
            Dump
    end.

%% @doc Helper function to shuffle a list.
shuffle(List) ->
    %% Determine the log n portion then randomize the list.
    randomize(round(math:log(length(List)) + 0.5), List).

randomize(1, List) ->
    randomize(List);
randomize(T, List) ->
    lists:foldl(
        fun(_E, Acc) ->
            randomize(Acc)
        end,
        randomize(List),
        lists:seq(1, (T - 1))
    ).

randomize(List) ->
    D = lists:map(
        fun(A) ->
            {rand:uniform(), A}
        end,
        List
    ),

    {_, D1} = lists:unzip(lists:keysort(1, D)),
    D1.
