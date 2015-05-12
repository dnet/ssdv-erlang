-module(base40).
-export([encode/1, decode/1]).

-define(LETTER_SHIFT, 14).
-define(NUMBER_SHIFT, 1).

encode(Value) -> encode(lists:reverse(Value), 0).
encode("", Acc) -> Acc;
encode([Char | Rest], Acc) ->
	NewAcc = Acc * 40 + encode_char(Char),
	encode(Rest, NewAcc).

encode_char(C) when C >= $A andalso C =< $Z -> C - $A + ?LETTER_SHIFT;
encode_char(C) when C >= $a andalso C =< $z -> C - $a + ?LETTER_SHIFT;
encode_char(C) when C >= $0 andalso C =< $9 -> C - $0 + ?NUMBER_SHIFT.

decode(Value) when Value =< 16#F423FFFF -> lists:reverse(decode(Value, "")).
decode(0, Acc) -> Acc;
decode(Value, Acc) ->
	Char = decode_char(Value rem 40),
	decode(Value div 40, [Char | Acc]).

decode_char(0) -> $-;
decode_char(C) when C < 11 -> $0 + C - ?NUMBER_SHIFT;
decode_char(C) when C < ?LETTER_SHIFT -> $-;
decode_char(C) -> $A + C - ?LETTER_SHIFT.
