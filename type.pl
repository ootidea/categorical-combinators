type(id, A, A).
type(o(F, G), A, C) :- type(F, A, B), type(G, B, C).

type(unit, A, unit).

type(fst, p(A, B), A).
type(snd, p(A, B), B).
type(p(F, G), A, p(B, C)) :- type(F, A, B), type(G, A, C).

type(left, A, c(A, B)).
type(right, B, c(A, B)).
type(c(F, G), c(A, B), C) :- type(F, A, C), type(G, B, C).

type(zero, unit, nat).
type(succ, nat, nat).
type(nat(Z, S), nat, A) :- type(Z, unit, A), type(S, A, A).

type(apply, p(func(A, B), A), B).
type(curry(F), A, func(B, C)) :- type(F, p(A, B), C).
