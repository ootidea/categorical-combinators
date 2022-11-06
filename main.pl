:- include('type.pl').

reduce(A, Z) :- reduce(A, Z, R).

% 関数合成（結合律は特別扱いする必要があるのでここには書かない
reduce(o(id, F), F, 'id-left').
reduce(o(F, id), F, 'id-right').

% Product
reduce(o(fst, p(F, G)), F, 'fst').
reduce(o(snd, p(F, G)), G, 'snd').
reduce(p(fst, snd), id, 'prod-id').
reduce(o(p(F, G), H), p(o(F, H), o(G, H)), 'prod-grow').

% Coproduct
reduce(o(c(F, G), left), F, 'left').
reduce(o(c(F, G), right), G, 'right').
reduce(c(left, right), id, 'coprod-id').
reduce(o(F, c(G, H)), c(o(F, G), o(F, H)), 'coprod-grow').

% Unit(Terminal object)
reduce(o(unit, F), unit, 'unit').

% Nat
reduce(o(nat(Z, S), zero), Z, 'zero').
reduce(o(nat(Z, S), succ), o(S, nat(Z, S)), 'succ').
reduce(nat(zero, succ), id, 'nat-id').
% equalsをまともに動かすためにもっと高いレイヤーにする必要があるんじゃないか？
% reduce(o(F, nat(Z, S)), nat(o(F, Z), G), 'nat-grow') :- equals(o(F, S), o(G, F)).

% 高階関数型
reduce(o(apply, p(o(curry(F), fst), snd)), F, 'apply').
reduce(curry(apply), id, 'func-id').
reduce(o(apply, p(curry(snd), F)), F, 'apply2').
reduce(o(apply, p(curry(o(G, snd)), F)), o(G, F), 'apply3').
reduce(o(curry(F), G), curry(o(F, p(o(G, fst), snd))), 'func-grow').

% エイリアス
reduce(add, o(apply, p(o(nat(curry(snd), curry(o(apply, p(fst, o(succ, snd))))), fst), snd)), 'add').


% 与えられた簡約述語Pを用いて最左最外戦略で1回簡約する
outerLeft(P, F, Z) :- outerLeft(P, F, Z, R).
outerLeft(P, F, Z, R) :- call(P, F, Z, R), !.
outerLeft(P, o(F, G), o(Z, G), R) :- outerLeft(P, F, Z, R), !.
outerLeft(P, p(F, G), p(Z, G), R) :- outerLeft(P, F, Z, R), !.
outerLeft(P, c(F, G), c(Z, G), R) :- outerLeft(P, F, Z, R), !.
outerLeft(P, nat(F, G), nat(Z, G), R) :- outerLeft(P, F, Z, R), !.
outerLeft(P, curry(F), curry(Z), R) :- outerLeft(P, F, Z, R), !.
outerLeft(P, o(F, G), o(F, Z), R) :- outerLeft(P, G, Z, R), !.
outerLeft(P, p(F, G), p(F, Z), R) :- outerLeft(P, G, Z, R), !.
outerLeft(P, c(F, G), c(F, Z), R) :- outerLeft(P, G, Z, R), !.
outerLeft(P, nat(F, G), nat(F, Z), R) :- outerLeft(P, G, Z, R), !.


% reduceを使って最左最外戦略で正規化する。簡約の途中経過を保持し、同一の項に簡約されるとバックトラックする
weakNormalize(A, Z) :- weakNormalize(A, Z, []).
weakNormalize(A, A, L) :- weakNormal(A), write('END: '), print(A), nl.
weakNormalize(A, Z, L) :- outerLeft(reduce, A, B, R), nonmember(B, L), write(R), write(': '), print(A), write(' => '), print(B), nl, weakNormalize(B, Z, [B | L]).

% 最左最外戦略のreduceでの正規系
weakNormal(A) :- outerLeft(reduce, A, B, R), !, fail.
weakNormal(A).

% 関数合成の結合律
assoc(o(o(F, G), H), o(F, o(G, H))).
assoc(o(F, o(G, H)), o(o(F, G), H)).
assoc(o(F, G), o(Z, G)) :- assoc(F, Z).
assoc(p(F, G), p(Z, G)) :- assoc(F, Z).
assoc(c(F, G), c(Z, G)) :- assoc(F, Z).
assoc(nat(F, G), nat(Z, G)) :- assoc(F, Z).
assoc(curry(F), curry(Z)) :- assoc(F, Z).
assoc(o(F, G), o(F, Z)) :- assoc(G, Z).
assoc(p(F, G), p(F, Z)) :- assoc(G, Z).
assoc(c(F, G), c(F, Z)) :- assoc(G, Z).
assoc(nat(F, G), nat(F, Z)) :- assoc(G, Z).

% assocの推移閉包
transitiveAssoc(A, Z) :- transitiveAssoc(A, Z, []).
transitiveAssoc(A, B, L) :- assoc(A, B), nonmember(B, L).
transitiveAssoc(A, Z, L) :- assoc(A, B), nonmember(B, L), transitiveAssoc(B, Z, [B | L]).

% assocの推移閉包から重複を取り除き、さらに反射閉包にしたもの
fullAssoc(A, A).
fullAssoc(A, Z) :- setof(B, transitiveAssoc(A, B), L), member(Z, L).

% 正規化。reduceで簡約できず、さらに結合律でどのように式変形してもreduceで簡約できない項になるまで簡約する
normalize(A, Z) :- normalize(A, Z, []).
normalize(A, A, L) :- normal(A), write('1: '), nl.
% normalize(A, A, L) :- weakNormal(A), fullAssoc(A, B), weakNormal(B), write('1: '), nl.
normalize(A, Z, L) :- fullAssoc(A, B), outerLeft(reduce, B, C), nonmember(C, L), write('2: '), print(C), nl, normalize(C, Z, [C | L]).
normalize(A, Z, L) :- weakNormalize(A, B), nonmember(B, L), write('3: '), print(B), nl, normalize(B, Z, [B | L]).

% normalizeの計算結果の重複を取り除いたもの
calculate(A, Z) :- setof(B, normalize(A, B), L), member(Z, L).


% 正規系。結合律でどのように変形してもreduceで簡約できない項
normal(A) :- setof(B, fullAssoc(A, B), L), every(weakNormal, L).

% リストの全要素に対して述語Pが成り立つ
every(P, []).
every(P, [A | L]) :- call(P, A), every(P, L).

% nonmember(A, L) :- member(A, L), write('duplicated: '), print(A), write(' in '), print(L), nl, !, fail.
nonmember(A, L) :- member(A, L), !, fail.
nonmember(A, L).


% 項の可読性を高めつつwriteする
print(o(F, G)) :- write('('), print(F), write('.'), print(G), write(')'), !.
print(p(F, G)) :- write('<'), print(F), write(', '), print(G), write('>'), !.
print([A|L]) :- print(A), write(' '), print(L), !.
print([]) :- !.
print(F) :- write(F).

sample :- sample(N).
sample(N) :- sample(N, Z).
sample(0, Z) :- normalize(o(p(fst, snd), f), Z)
sample(1, Z) :- normalize(o(nat(z, s), o(succ, zero)), Z).
sample(2, Z) :- normalize(o(o(nat(z, s), succ), zero), Z).
sample(3, Z) :- normalize(o(o(nat(zero, o(succ, succ)), succ), zero), Z).
sample(4, Z) :- normalize(o(nat(zero, o(succ, succ)), o(succ, zero)), Z).
sample(5, Z) :- normalize(o(p(snd, fst), p(snd, fst)), Z).

