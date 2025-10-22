:- module(quads, [
    check_file_quads/1,
    check_file_quads/2,
    check_module_quads/1,
    check_module_quads/2,
    op(1200, xfx, '?-')
]).

:- use_module(library(iso_ext)).
:- use_module(library(pio)).
:- use_module(library(lists)).
:- use_module(library(dcgs)).
:- use_module(library(format)).
:- use_module(library(reif)).
:- use_module(library(error)).
:- use_module(library(os), [getenv/2]).
:- use_module(library(files), [working_directory/2]).

check_file_quads(File) :-
    check_file_quads(File, _).

check_file_quads(File, Quads) :-
    must_be(atom, File),
    consult(File),
    read_file_quads(File, Quads),
    check_quads_list(Quads, user, File).

check_module_quads(Module) :-
    check_module_quads(Module, _).

check_module_quads(Module, Quads) :-
    must_be(atom, Module),
    read_module_quads(Module, Quads),
    check_quads_list(Quads, Module, Module).

check_quads_list(Quads, Module, _Label) :-
    check_quads_(Quads, Module).

check_quads_([], _).
check_quads_([Q-QVN, A-AVN|Rest], Module) :-
    Q = (?- _),
    check_qu_ad_in_module(Module, Q-QVN, A-AVN),
    check_quads_(Rest, Module).
check_quads_([T-TVN, A-AVN|Rest], Module) :-
    T = (_Label ?- Query),
    check_binary_quad(Module, Query, A, TVN, AVN),
    check_quads_(Rest, Module).
check_quads_([_|Rest], Module) :-
    check_quads_(Rest, Module).

read_file_quads(File, Quads) :-
    setup_call_cleanup(
        open(File, read, Stream, [type(text)]),
        read_terms(Stream, Terms),
        close(Stream)
    ),
    terms_quads(Terms, Quads).

read_module_quads(Module, Quads) :-
    module_file(Module, File),
    read_file_quads(File, Quads).

module_file(Module, File) :- atom_concat(Module, '.pl', File).

read_terms(Stream, Terms) :-
    read_terms_(Stream, [], Terms).

read_terms_(Stream, Terms0, Terms) :-
    Options = [variable_names(VarNames)],
    read_term(Stream, Term, Options),
    (   Term = end_of_file -> reverse(Terms0, Terms)
    ;   read_terms_(Stream, [Term-VarNames|Terms0], Terms)
    ).

terms_quads([Term1, Term2|Terms], Quads) :-
    Term1 = Q-_,
    (   Q = (?- _) ->
        Quads = [Term1, Term2|Quads_],
        terms_quads(Terms, Quads_)
    ;   Q = (_ ?- _) ->
        Quads = [Term1, Term2|Quads_],
        terms_quads(Terms, Quads_)
    ;   terms_quads([Term2|Terms], Quads)
    ).
terms_quads([_], []).
terms_quads([], []).

term_type(Term-_, Type) :-
    (   Term = (?- _) -> Type = query
    ;   Term = (:- _) -> Type = clause
    ;   Term = (_,_) -> Type = answer_description
    ;   Term = (_;_) -> Type = answer_description
    ;   Term == true -> Type = answer_description
    ;   Term == false -> Type = answer_description
    ;   Type = clause
    ).

zip([X|Xs], [Y|Ys], [X,Y|XYs]) :-
    zip(Xs, Ys, XYs).
zip([], [], []).

check_binary_quad(Module, Query, Answer, QVN, AVN) :-
    (   check_binary_quad_(Module, Query, Answer, QVN, AVN) ->
        format("quad(pass, ~q).~n", [Query])
    ;   format("quad(fail, ~q).~n", [Query]),
        fail
    ).

check_binary_quad_(Module, Query, Answer, QVN, AVN) :-
    unify_var_names(QVN, AVN),
    (   Answer == true -> (Module:call(Query), !)
    ;   Answer == false -> (\+ Module:call(Query), !)
    ;   phrase(unconj(Answer), As) ->
        (   length(As, N),
            n_answers(N, Answer, AVN, ADs),
            n_answers(N, Module:Query, QVN, Answers),
            maplist(contains, ADs, Answers),
            !
        )
    ;   (Module:call(Query), !,
        Module:call(Answer))
    ).

check_qu_ad(Q-QVN, A-AVN) :-
    check_qu_ad_in_module(user, Q-QVN, A-AVN).

check_qu_ad_in_module(Module, Q-QVN, A-AVN) :-
    Q = ?-(G),
    (   check_qu_ad_in_module_(Module, G, A, QVN, AVN) ->
        true
    ;   format("quad(fail, ~q).~n", [A]),
        fail
    ).

check_qu_ad_in_module_(Module, G, A, QVN, AVN) :-
    unify_var_names(QVN, AVN),
    (   A == true -> (Module:call(G), !)
    ;   A == false -> (\+ Module:call(G), !)
    ;   phrase(unconj(A), As) ->
        (   length(As, N),
            n_answers(N, A, AVN, ADs),
            n_answers(N, Module:G, QVN, Answers),
            maplist(contains, ADs, Answers),
            !
        )
    ;   (Module:call(G), !,
        Module:call(A))
    ).

unify_var_names([], _).
unify_var_names([Name=Var1|Rest], VN2) :-
    (   member(Name=Var2, VN2) ->
        Var1 = Var2
    ;   true
    ),
    unify_var_names(Rest, VN2).

contains(AD, Answer) :- append(Answer, _, AD).

unconj(Conj) --> { Conj = (Elt;Conj_) },
                 [Elt],
                 unconj(Conj_).
unconj(...) --> [].

empty_anstack :-
    (   retract('$anstack'(_)), fail
    ;   asserta('$anstack'([]))
    ).

push(VN) :-
    retract('$anstack'(As)),
    asserta('$anstack'([VN|As])).

backtrack(N) :-
    (   '$anstack'(Ans),
        length(Ans, N) -> true
    ;   fail
    ).

n_answers(N, G, VN, ADs) :-
    must_be(integer, N),
    (   N > 0 -> n_answers_(N, G, VN, ADs)
    ;   domain_error(not_less_than_zero, N, n_answers/4)
    ).

n_answers_(N, G, VN, ADs) :-
    empty_anstack,
    call(G), push(VN),
    backtrack(N),
    !,
    retract('$anstack'(As)),
    reverse(As, ADs).
