(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
 * Copyright (c) 2012 Balraj Singh <balraj.singh@cl.cam.ac.uk>
 * Copyright (c) 2015 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2017 Takayuki Imada <takayuki.imada@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt.Infix

type stats = {
  mutable bytes: int64;
  mutable start_time: int64;
  mutable end_time: int64
}

module Main (S: Tcpip.Stack.V4) (Mclock : Mirage_clock.MCLOCK) = struct

  let server_port = 5001

  let start_id = Int32.of_int 0

  (* packet sending *)
  let write_and_check ip port udp buf =
    S.UDPV4.write ~src_port:server_port ~dst:ip ~dst_port:port udp buf >|= Rresult.R.get_ok

  (* main server function *)
  let iperf clock s src_ip src_port st buf =
    let l = Cstruct.length buf in
    let id = EndianBigstring.BigEndian.get_int32 buf.Cstruct.buffer 42 in

    (* Received a packet to start a measurement *)
    if (Int32.compare id start_id) = 0 then
    begin
      Logs.info (fun f -> f "iperf_udp_server: Started");
      st.start_time <- Mclock.elapsed_ns clock;
      Lwt.return_unit
    end
    (* Received a packet to close the measurement *)
    else if (Int32.compare id start_id) < 0 then
    begin
      st.end_time <- Mclock.elapsed_ns clock;
      st.bytes <- (Int64.add st.bytes (Int64.of_int l));
      let elapsed = Int64.sub st.end_time st.start_time in
      let time_sec = Int64.div elapsed 1000000000L in
      let time_usec = Int64.div (Int64.sub elapsed time_sec) 1000000L in
      Logs.info (fun f -> f "iperf_udp_server: Stopped. %.0Lu bytes received." st.bytes);
      Logs.info (fun f -> f "iperf_udp_server: %.0Lu [ns] elapsed" elapsed);

      (* C-based iperf compatibility *)
      let response = Cstruct.create 1470 in
      Cstruct.blit buf 0 response 0 12;
      Cstruct.set_uint8 response 12 128;
      Cstruct.BE.set_uint64 response 16 st.bytes;
      Cstruct.BE.set_uint32 response 24 (Int64.to_int32 time_sec);
      Cstruct.BE.set_uint32 response 28 (Int64.to_int32 time_usec);

      let udp = S.udpv4 s in
      write_and_check src_ip src_port udp response >>= fun () ->
      st.bytes <- 0L;
      Lwt.return_unit
    end
    (* usual packet receiving *)
    else 
    begin
      st.bytes <- (Int64.add st.bytes (Int64.of_int l));
      Lwt.return_unit
    end

  let start s _clock =
    let ips = List.map Ipaddr.V4.to_string (S.IPV4.get_ip (S.ipv4 s)) in
    (* debug is too much for us here *)
    Logs.set_level ~all:true (Some Logs.Info);
    Logs.info (fun f -> f "iperf_udp_server: process started:");
    Logs.info (fun f -> f "iperf_udp_server: IP address: %s" (String.concat "," ips));
    Logs.info (fun f -> f "iperf_udp_server: Port number: %d" server_port);

    let st = {
      bytes=0L; start_time=0L; end_time=0L
    } in

    S.UDPV4.listen (S.udpv4 s) ~port:server_port (fun ~src ~dst:_ ~src_port buf ->
      iperf _clock s src src_port st buf
    );
    S.listen s

end
