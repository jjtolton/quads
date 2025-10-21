my_append([], Ys, Ys).
my_append([X|Xs], Ys, [X|Zs]) :-
    my_append(Xs, Ys, Zs).

my_append([1,2], [3,4], Xs) ?- Xs = [1,2,3,4].

?- my_append([a], [b,c], R).
   R = [a,b,c].

my_length([], 0).
my_length([_|Xs], N) :-
    my_length(Xs, N0),
    N is N0 + 1.

?- my_length([1,2,3], N).
   N = 3.

my_length([5,6,7,8], 4) ?- true.
