% collcount.pl
% Solomon Himelbloom
% 2022-04-21
%
% For CS F331 / CSCE A331 Spring 2022
% Programming in Prolog

% collcount/2
% collcount(+n, ?c)
collcount(1, 0).

% Case 1: n is odd.
collcount(N, C) :-
    N > 1,
    N mod 2 =\= 0,
    N1 is (3 * N + 1),
    collcount(N1, C1),
    C is C1 + 1.

% Case 1: n is even.
collcount(N, C) :-
    N > 1,
    N mod 2 =:= 0,
    N1 is N / 2,
    collcount(N1, C1),
    C is C1 + 1.
