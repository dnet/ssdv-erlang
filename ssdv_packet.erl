-module(ssdv_packet).

-define(SYNC_BYTE, 16#55).
-define(PACKET_TYPE_NORMAL, 16#66).

-record(packet, {call_sign, image_id, packet_id, size, subsampling, mcu, payload}).

decode_packet(Packet = <<?SYNC_BYTE, ?PACKET_TYPE_NORMAL, CallSign:32, ImageId,
                PacketId:16, Width, Height, _ReservedFlags:6, SubSampling:2,
                McuOffset, McuIndex:16, Payload:205/binary, CRC:32,
                _FEC:32/binary>>) when Width =/= 0 andalso Height =/= 0 ->
    <<_, CrcSubject:219/binary, _:36/binary>> = Packet,
    case erlang:crc32(CrcSubject) of
        CRC -> #packet{call_sign=base40:decode(CallSign), image_id=ImageId,
                       packet_id=PacketId, size={Width, Height},
                       subsampling=SubSampling, mcu=mcu(McuOffset, McuIndex),
                       payload=Payload};
        _ -> {error, crc}
    end;
decode_packet(_) -> {error, header_format}.

mcu(16#FF, 16#FFFF) -> undefined;
mcu(Offset, Index) -> {Offset, Index}.
