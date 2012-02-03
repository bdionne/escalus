%%==============================================================================
%% Copyright 2010 Erlang Solutions Ltd.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%==============================================================================

-module(escalus_new_assert).

%% This module is meant to replace legacy escalus_assert in future versions
%% of Escalus

-export([assert/2, assert/3, assert_many/2, mix_match/2]).

%%==============================================================================
%% API functions
%%==============================================================================

assert(PredSpec, Arg) ->
    Fun = predspec_to_fun(PredSpec),
    StanzaStr = exml:to_list(Arg),
    assert_true(Fun(Arg),
        {assertion_failed, assert, PredSpec, Arg, StanzaStr}).

assert(PredSpec, Params, Arg) ->
    Fun = predspec_to_fun(PredSpec, length(Params) + 1),
    StanzaStr = exml:to_list(Arg),
    assert_true(apply(Fun, Params ++ [Arg]),
        {assertion_failed, assert, PredSpec, Params, Arg, StanzaStr}).

assert_many(Predicates, Stanzas) ->
    AllStanzas = length(Predicates) == length(Stanzas),
    Ok = escalus_utils:mix_match(fun predspec_to_fun/1, Predicates, Stanzas),
    StanzasStr = escalus_utils:pretty_stanza_list(Stanzas),
    case Ok of
        true -> ok;
        false ->
            escalus_utils:log_stanzas("multi-assertion failed on", Stanzas)
    end,
    assert_true(Ok and AllStanzas,
        {assertion_failed, assert_many, AllStanzas, Predicates, Stanzas, StanzasStr}).

mix_match(Predicates, Stanzas) ->
    assert_many(Predicates, Stanzas).

%%==============================================================================
%% Helpers
%%==============================================================================

predspec_to_fun(F) ->
    predspec_to_fun(F, 1).

predspec_to_fun(F, N) when is_atom(F), is_integer(N) ->
    %% Fugly, avert your eyes :-/
    %% R15B complains about {escalus_pred, F} syntax, where
    %% R14B04 doesn't allow fun escalus_pred:F/A yet.
    case N of
        1 -> fun (X) -> escalus_pred:F(X) end;
        2 -> fun (X, Y) -> escalus_pred:F(X, Y) end;
        3 -> fun (X, Y, Z) -> escalus_pred:F(X, Y, Z) end
    end;
predspec_to_fun(Other, _) ->
    Other.

assert_true(true, _) -> ok;
assert_true(false, Fail) ->
    exit(Fail);
assert_true(WTF, Pred) ->
    exit({wtf, bad_predicate_return_value, WTF, Pred}).