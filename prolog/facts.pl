:- module(facts, [просмотрел/2, жанр/2, recommend/2]).  % Экспортируем необходимые предикаты

:- dynamic просмотрел/2.
:- dynamic жанр/2.

% Правило для рекомендаций
recommend(Пользователь, Фильм) :-
    просмотрел(Пользователь, Фильм_1),
    жанр(Фильм_1, Жанр),
    жанр(Фильм, Жанр),
    \+ просмотрел(Пользователь, Фильм).

жанр('фильм', 'Sci-Fi').
просмотрел('чел', 'фильм').

