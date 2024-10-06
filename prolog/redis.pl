:- use_module(library(redis)).
:- use_module(library(redis_streams)).

% Подключение к Redis и сохранение соединения
connect_to_redis(Connection) :-
        redis_connect(redis:6379, Connection, []).

% Запись данных в Redis Stream
write_message_to_stream(Stream, Message) :-
    sleep(3),
    % Подключаемся к Redis, если еще не подключались
    connect_to_redis(Connection),
    % Отправляем сообщение в Stream
    redis(Connection, publish(Stream, Message)).
