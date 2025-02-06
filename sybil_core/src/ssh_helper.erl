-module(ssh_helper).

-export([connect/0]).

connect() ->
    ssh:connect("172.20.128.2", 22,
     [{user, "dubuntu"}, {password, "secret_password"},
      {silently_accept_hosts, true}]).
