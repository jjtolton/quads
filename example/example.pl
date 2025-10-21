my_append([], Ys, Ys).
my_append([X|Xs], Ys, [X|Zs]) :-
    my_append(Xs, Ys, Zs).

?- my_append([1,2], [3,4], Xs).
   Xs = [1,2,3,4].

?- my_append([a], [b,c], R).
   R = [a,b,c].

?- my_append(Xs, Ys, [1,2,3]).
   Xs = [], Ys = [1,2,3]
;  Xs = [1], Ys = [2,3]
;  Xs = [1,2], Ys = [3]
;  Xs = [1,2,3], Ys = [].

my_length([], 0).
my_length([_|Xs], N) :-
    my_length(Xs, N0),
    N is N0 + 1.

?- my_length([a,b,c], N).
   N = 3.

?- my_length([1,2,3,4], 4).
   true.

?- my_length([1,2], 3).
   false.
