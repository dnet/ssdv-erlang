-module(ssdv_packet).

-define(SYNC_BYTE, 16#55).
-define(PACKET_TYPE_NORMAL, 16#66).

-record(packet, {call_sign, image_id, packet_id, size, subsampling, mcu, payload}).

find_packets(Data) -> find_packets(Data, []).
find_packets(Frame = <<?SYNC_BYTE, Packet:255/binary, Rest/binary>>, Acc) ->
	case rs8:decode(Packet) of
		{ok, ErrorCount, Data} ->
			case decode_packet(Data) of
				P when is_record(P, packet) -> find_packets(Rest, [P | Acc]);
				{error, _} -> find_packets(binary:part(Frame, 1, byte_size(Frame) - 1), Acc)
			end;
		_ -> find_packets(binary:part(Frame, 1, byte_size(Frame) - 1), Acc)
	end;
find_packets(<<_, Rest/binary>>, Acc) -> find_packets(Rest, Acc);
find_packets(_, Acc) -> Acc.

decode_packet(Packet = <<?PACKET_TYPE_NORMAL, CallSign:32, ImageId,
                PacketId:16, Width, Height, _ReservedFlags:6, SubSampling:2,
                McuOffset, McuIndex:16, Payload:205/binary, CRC:32,
                _FEC:32/binary>>) when Width =/= 0 andalso Height =/= 0 ->
    case erlang:crc32(binary:part(Packet, 0, 219)) of
        CRC -> #packet{call_sign=base40:decode(CallSign), image_id=ImageId,
                       packet_id=PacketId, size={Width, Height},
                       subsampling=SubSampling, mcu=mcu(McuOffset, McuIndex),
                       payload=Payload};
        _ -> {error, crc}
    end;
decode_packet(_) -> {error, header_format}.

mcu(16#FF, 16#FFFF) -> undefined;
mcu(Offset, Index) -> {Offset, Index}.
