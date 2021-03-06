%%%----------------------------------------------------------------
%%% @author  Antonio Garrote Hernandez <antoniogarrote@gmail.com>
%%% @doc
%%% @end
%%% @copyright 2009 Antonio Garrote Hernandez
%%%----------------------------------------------------------------
-module(console) .

-author("Antonio Garrote Hernandez") .

-behaviour(gen_server) .

-include_lib("definitions.hrl").

-export([start_link/1]) .
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).
-export([repository_connect/0, repository_add_encoded_triples/3, repository_sparql_query/1, repository_full_graph/0]) .
-export([repository_delete_graph/1]) .
-export([tbox_create/2, tbox_update/2, tbox_clear/1]) .


%% Public API


start_link(ApplicationOptions) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [ApplicationOptions], []) .


%% TBoxes


%% console:tbox_create(plaza_admin_app,[{file, "/Users/antonio.garrote/ontologies/blogs/blogs.owl"},{format, "rdfxml"}]) .
tbox_create(Application, Options) ->
    plaza_admin_app:create_tbox(Application, Options) .

tbox_update(Application, Options) ->
    plaza_admin_app:update_tbox(Application, Options) .

tbox_clear(Application) ->
    plaza_admin_app:clear_tbox(Application) .


%% Repository


repository_connect() ->
    gen_server:call(?MODULE, repository_connect) .


repository_add_encoded_triples(BaseUrl, Triples, Format) ->
    gen_server:call(?MODULE, {repository_add_encoded_triples, BaseUrl, Triples, Format}) .


repository_sparql_query(Query) ->
    gen_server:call(?MODULE, {sparql_query, Query}) .


repository_delete_graph(GraphName) ->
    gen_server:call(?MODULE, {delete_graph, GraphName}) .


repository_full_graph() ->
    gen_server:call(?MODULE, {sparql_query, <<"SELECT ?s ?p ?o WHERE { ?s ?p ?o }">>}) .


%% Callbacks


init([ApplicationOptions]) ->
    error_logger:info_msg("Console process starting",[]),
    Result = plaza_applications_controller:start_plaza_application(ApplicationOptions),
    error_logger:info_msg("Console process 1",[]),
    case Result of
        {error, Reason} -> erlang:error("Impossible to start the console for application: " ++ Reason, ApplicationOptions) ;
        Other           -> error_logger:info_msg("Console process started: ~p",[Other])
    end,
    ApplicationName = list_to_atom(plaza_utils:proplist_find(name,ApplicationOptions)),
    Config = plaza_application_proxy:get_configuration(ApplicationName),
    {ok, {ApplicationName, Config}} .


handle_call(repository_connect, _From, {_AppName, Config} = State) ->
    Result = plaza_repository:connect(Config),
    {reply, Result, State} ;

handle_call({repository_add_encoded_triples, BaseUrl, Triples, Format}, _From, {_AppName, Config} = State) ->
    Result = plaza_repository:add_encoded_triples(Config, BaseUrl, Triples, Format),
    {reply, Result, State} ;

handle_call({delete_graph, GraphName}, _From, {_AppName, Config} = State) ->
    Result = plaza_repository:delete_graph(Config, GraphName),
    {reply, Result, State} ;

handle_call({sparql_query, Query}, _From, {_AppName, Config} = State) ->
    Result = plaza_repository:sparql_query(Config, Query),
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
