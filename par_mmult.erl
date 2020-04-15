-module(par_mmult).
-export([
    advance/2,
    create_square/1,
    dot_product/2,
    main/0,
    multiply_elements/2,
    mult/2,
    take/2,
    transpose/1,
    split/2, 
    worker/3, 
    work/3]).

% generate sample square matrix with dimension N
create_square(N) -> split(lists:seq(1,N*N), N).
    
% transpose matrix M over itself
transpose([[] | _]) -> [];
transpose(M) -> [[hd(Row) || Row <- M] | transpose([tl(Row) || Row <- M])].

% fold function for multiply and accumulate
multiply_elements(Pair, Sum) ->
    {X, Y} = Pair,          % Destructure pair
	X * Y + Sum.            % Accumulate

% dot product of two vectors
dot_product(A, B) ->
	lists:foldl(fun(X,Y)->multiply_elements(X,Y) end, 0, lists:zip(A, B)).

% multiplies rows of M1 by M2
mult([[] | _], _) -> [];
mult(M1, M2) -> [[dot_product(R1, R2) || R1 <- M1] || R2 <- M2].

% unbounded advance
advance([], _) -> [];
advance(L, 0) -> L;
advance([_|Xs], N) -> advance(Xs, N-1).

% unbounded take from list
take([], _) -> [];
take(_, 0) -> [];
take([H|T], N) when N > 0 -> [H|take(T, N-1)].

% bins the work for the threads
split([], _) -> [];
split(L, 0) -> L;
split(L, N) -> [take(L, N) | split(advance(L, N), N)].

% worker thread function, sends mult back to parent pid
worker(M1, M2, Parent_PID) -> Parent_PID ! {mult(M1, M2), self()}.

% forks then collects work from children
work(Nthreads, M1, M2) ->
    process_flag(trap_exit, true),
    DividedWork = split(M1, trunc(math:ceil(length(M1) / Nthreads))),
    StartTime = erlang:monotonic_time(microsecond),
    Workers = [spawn(par_mmult, worker, [Rows, M2, self()]) || Rows <- DividedWork],
    Result = [ receive {Result, Pid} -> Result end || Pid <- Workers],
    EndTime = erlang:monotonic_time(microsecond),
    TotalTime = EndTime - StartTime,
	io:fwrite("Time: ~w~n", [TotalTime]),
    [].

main() -> [].
