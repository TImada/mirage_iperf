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
  mutable last_time: int64;
}

module Main (S: Tcpip.Stack.V4V6) = struct

  let server_ip = Ipaddr.of_string_exn "192.168.122.10"
  let server_port = 5001
  let client_port = 50001
  let total_size = 300_000_000
  let blen = 1460

  let msg =
    "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789001234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

  let mlen =
    if blen <= (String.length msg) then blen
    else (String.length msg)

  let print_data st =
    let duration = Int64.sub st.last_time st.start_time in
    let rate = (Int64.float_of_bits st.bytes) /. (Int64.float_of_bits duration) *. 1000. *. 1000. *. 1000. in
    Logs.info (fun f -> f  "iperf client: Duration = %.0Lu [ns] (start_t = %.0Lu, end_t = %.0Lu),  Data sent = %Ld [bytes], Throughput = %.2f [bytes/sec]" duration st.start_time st.last_time st.bytes rate);
    Logs.info (fun f -> f  "iperf client: Throughput = %.2f [MBs/sec]"  (rate /. 1000000.));
    Lwt.return_unit

  let write_and_check ip port udp buf =
    S.UDP.write ~src_port:client_port ~dst:ip ~dst_port:port udp buf >|= Rresult.R.get_ok

  (* set a UDP diagram ID for the C-based iperf *)
  let set_id buf num =
    if (Cstruct.length buf) = 0 then
      Lwt.return_unit 
    else
      begin
        Cstruct.BE.set_uint32 buf 0 (Int32.of_int num);
        Lwt.return_unit
      end

  (* client function *)
  let iperfclient amt dest_ip dport udp =
    Logs.info (fun f -> f  "iperf client: Trying to connect to a server at %s:%d, buffer size = %d, protocol = udp" (Ipaddr.to_string server_ip) server_port mlen);
    Logs.info (fun f -> f  "iperf client: %.0d bytes data transfer initiated." amt);
    let zeros = Cstruct.create 40 in
    let body = amt / mlen in
    let reminder = amt - (mlen * body) in

    (* Create data to be sent *)
    let a = Cstruct.sub (Io_page.(to_cstruct (get 1))) 0 mlen in
    Cstruct.blit_from_string msg 0 a 0 mlen;
    Cstruct.blit zeros 0 a 0 (Cstruct.length zeros);

    (* Loop function for packet sending *)
    let rec loop num body st = 
      match num with
      (* Send the first packet to notify the start of a measurement *)
      | 0 -> 
        set_id a 0 >>= fun () ->
        write_and_check dest_ip dport udp a >>= fun () ->
        st.start_time <- Mirage_mtime.elapsed_ns (); 
        loop (num + 1) body st
      (* Send a closing packet(s) to complete the measurement *)
      | -1 -> if reminder = 0 then
        begin
          set_id a (-1 * body) >>= fun () ->
          write_and_check dest_ip dport udp a >>= fun () ->
          st.last_time <- Mirage_mtime.elapsed_ns (); 
          st.bytes <- (Int64.add st.bytes (Int64.of_int (Cstruct.length a)));
          Lwt.return_unit
        end
        else
        begin
          set_id a body >>= fun () ->
          write_and_check dest_ip dport udp a >>= fun () ->
          st.bytes <- (Int64.add st.bytes (Int64.of_int (Cstruct.length a)));
          let a = Cstruct.sub a 0 reminder in
          set_id a (-1 * (body + 1)) >>= fun () ->
          write_and_check dest_ip dport udp a >>= fun () ->
          st.last_time <- Mirage_mtime.elapsed_ns (); 
          st.bytes <- (Int64.add st.bytes (Int64.of_int (Cstruct.length a)));
          Lwt.return_unit
        end
      (* Usual packet sending *)
      | n ->
        if num = body then
          loop (-1) body st
        else begin
          set_id a n >>= fun () ->
          write_and_check dest_ip dport udp a >>= fun () ->
          st.bytes <- (Int64.add st.bytes (Int64.of_int (Cstruct.length a)));
          loop (num + 1) body st
        end
    in

    (* Measurement *)
    let t0 = Mirage_mtime.elapsed_ns () in
    let st = {
      bytes=0L; start_time = t0; last_time = t0
    } in
    loop 0 body st >>= fun () ->

    (* Print the obtained result *)
    print_data st >>= fun () ->
    Logs.info (fun f -> f  "iperf client: Done.");
    Mirage_sleep.ns (Duration.of_sec 3) >>= fun () ->
    Lwt.return_unit

  let start s =
    Mirage_sleep.ns (Duration.of_sec 1) >>= fun () -> (* Give server 1.0 s to call listen *)
    S.UDP.listen (S.udp s) ~port:server_port (fun ~src:_ ~dst:_ ~src_port:_ buf ->
      Logs.info (fun f -> f "iperf client: %.0Lu bytes received on the server side." (Cstruct.BE.get_uint64 buf 16));
      Lwt.return_unit
    );
    Lwt.async (fun () -> S.listen s);
    let udp = S.udp s in
    iperfclient total_size server_ip server_port udp

end
