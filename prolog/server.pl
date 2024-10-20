:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- consult('redis.pl').
:- use_module(library(http/json)).

:- dynamic watched/2.
:- dynamic genre/2.

% Rule for recommendations
recommend(User, Movie) :-
    watched(User, WatchedMovie),
    genre(WatchedMovie, Genre),
    genre(Movie, Genre),
    \+ watched(User, Movie).

% Route definitions
:- http_handler(root(get_recommendation), recommendation_handler, [method(get)]).
:- http_handler(root(add_data), add_data_handler, [method(post)]).
:- http_handler(/, hello, [method(get)]).

% Starting the HTTP server
server(Port) :-
    http_server(http_dispatch, [port(Port)]).

% GET request handler for getting recommendations
recommendation_handler(Request) :-
    http_parameters(Request, [user(User, [atom])]),
    findall(Recommendation, recommend(User, Recommendation), Recommendations),
    reply_json(json([recommendations=Recommendations])).

% Greeting handler
hello(_Request) :-
    thread_create(write_message_to_stream(my_channel, "Hello, world!"), _, [detached(true)]),
    reply_json(json([message='Hello, world!'])).

% Start server on port 8090
:- initialization(start_server).

start_server :-
    server(8090),
    write('Server started on port 8090'), nl,
    assertz(watched('user', 'movie')),
    assertz(genre('movie', 'Sci-Fi')),
    wait_forever.

% Infinite loop to keep the main process alive
wait_forever :-
    repeat,
    sleep(10000),
    fail.

% POST request handler for adding facts
add_data_handler(Request) :-
    http_read_json_dict(Request, Dict),
    add_facts(Dict),
    findall(json([user=User, movie=Movie]), watched(User, Movie), UsersFacts),
    findall(json([movie=Movie, genre=Genre]), genre(Movie, Genre), FilmsFacts),
    thread_create(findAndWrite, _, [detached(true)]),
    reply_json(json([status='facts added', users=UsersFacts, films=FilmsFacts])).

% Adding facts without duplication
add_facts(Dict) :-
    forall(member(UserDict, Dict.users),
           (atom_string(User, UserDict.user),
            atom_string(Movie, UserDict.movie),
            ( \+ watched(User, Movie) -> assertz(watched(User, Movie)) ; true ))),
    forall(member(FilmDict, Dict.films),
           (atom_string(Movie, FilmDict.movie),
            atom_string(Genre, FilmDict.genre),
            ( \+ genre(Movie, Genre) -> assertz(genre(Movie, Genre)) ; true ))).

% Function to find recommendations and write to Redis
findAndWrite :-
    findall(json([user=User, recomendation=Recommendation]), recommend(User, Recommendation), Recommendations),
    atom_json_dict(RecommendationsAtom, Recommendations, []),
    write_message_to_stream(recommendations, RecommendationsAtom),
    retract(watched(_)),
    retract(genre(_)).
