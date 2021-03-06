%%%----------------------------------------------------------------
%%% @author Antonio Garrote Hernandez <antoniogarrote@gmail.com>
%%% @doc
%%%
%%% @end
%%% @copyright 2009 Antonio Garrote Hernandez
%%%----------------------------------------------------------------,
-module(plaza_applications_controller) .

-author("Antonio Garrote Hernandez") .

-behaviour(gen_server) .

-include_lib("states.hrl").
-include_lib("eunit/include/eunit.hrl").

-export([start_link/0, start_plaza_application/1, get_application_configurations/0]) .
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% Public API


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


start_plaza_application(Options) ->
    gen_server:call(?MODULE, {start_plaza_application, Options}) .

get_application_configurations() ->
    gen_server:call(?MODULE, {get_application_configurations}) .

%% Callbacks


init(_State) ->
    %% seed the random number generator
    {ok, #app_controller{ } } .


handle_call({start_plaza_application, Options}, _From, #app_controller{ apps=Apps } = State) ->
    error_logger:info_msg("Plaza application controller, starting plaza_application",[]),
    {NewState, Result} = case proplists:lookup(name,Options) of

                             none         -> {State, {error, "no name for application to start"}} ;

                             {name, Name} -> error_logger:info_msg("Plaza application controller, application_proxy:start_link",[]),
                                             Pid = plaza_application_proxy:start_link(Options),
                                             error_logger:info_msg("Plaza application controller, result ~p",[Pid]),
                                             {State#app_controller{ apps=[{list_to_atom(Name), Pid} | Apps] }, ok}
                         end,
    error_logger:info_msg("Plaza application started by controller",[]),
    {reply, Result, NewState} ;

handle_call({get_application_configurations}, _From, #app_controller{ apps=Apps } = State) ->
    error_logger:info_msg("Plaza application controller, retrieving configurations"),
    Result = lists:map(fun({N,_Pid}) ->
                               plaza_application_proxy:get_configuration(N)
                       end,
                       Apps),
    {reply, Result, State} .


%% dummy callbacks so no warning are shown at compile time
handle_cast(_Msg, State) ->
    {noreply, State} .


handle_info(_Msg, State) ->
    {noreply, State}.


code_change(_OldVsn, State, _Extra) ->
    {ok, State} .


terminate(shutdown, _State) ->
    ok.


%% Private methods
