open Lwt.Infix
open Cmdliner

type stats = {
  mutable bytes: int64;
  mutable start_time: int64;
  mutable last_time: int64;
}

let dest_port =
  let doc =
    Arg.info ~doc:"The destination TCP port of a target iperf server."
      [ "dest_port" ]
  in
  Mirage_runtime.register_arg Arg.(value & opt int 5001 doc)

let dest_ip =
  let doc =
    Arg.info ~doc:"The destination IP address of a target iperf server."
      [ "dest_ip" ]
  in
  Mirage_runtime.register_arg Arg.(value & opt string "192.168.122.10" doc)

let total_bytes =
  let doc =
    Arg.info ~doc:"The total bytes of data to be sent to a target iperf server. (int)"
      [ "total_bytes" ]
  in
  Mirage_runtime.register_arg Arg.(value & opt int 100_000_000 doc)

let payload_size =
  let doc =
    Arg.info ~doc:"The payload size of each packet for transmission. (int, up to 1460)"
      [ "payload_size" ]
  in
  Mirage_runtime.register_arg Arg.(value & opt int 1024 doc)

module Main (S: Tcpip.Stack.V4V6) = struct

  (* 1460-byte message template *)
  let msg =
    "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

  let print_data st ts_now =
    let duration = Int64.sub ts_now st.start_time in
    let rate = (Int64.float_of_bits st.bytes) /. (Int64.float_of_bits duration) *. 1000. *. 1000. *. 1000. in
    Logs.info (fun f -> f  "iperf client: Duration = %.0Lu [ns] (start_t = %.0Lu, end_t = %.0Lu),  Data received = %Ld [bytes], Throughput = %.2f [bytes/sec]" duration st.start_time ts_now st.bytes rate);
    Logs.info (fun f -> f  "iperf client: Throughput = %.2f [MBs/sec]"  (rate /. 1000000.));
    Lwt.return_unit

  let err_connect ip port () =
    let ip  = Ipaddr.to_string ip in
    Logs.info (fun f -> f "Unable to connect to %s:%d" ip port);
    Lwt.return_unit

  let write_and_check flow buf =
    S.TCP.write flow buf >|= Rresult.R.get_ok

  let tcp_connect t (ip, port) =
    S.TCP.create_connection t (ip, port) >|= Rresult.R.get_ok

  let iperfclient s amt len dest_ip dport =
    let iperftx flow =
      Logs.info (fun f -> f  "iperf client: %.0d bytes data transfer initiated." amt);
      let a = Cstruct.sub (Io_page.(to_cstruct (get 1))) 0 len in
      Cstruct.blit_from_string msg 0 a 0 len;
      let rec loop = function
        | 0 -> Lwt.return_unit
        | n -> write_and_check flow a >>= fun () -> loop (n-1)
      in
      let t0 = Mirage_mtime.elapsed_ns () in
      let st = {
        bytes=0L; start_time = t0; last_time = t0
      } in
      loop (amt / len) >>= fun () ->
      let a = Cstruct.sub a 0 (amt - (len * (amt/len))) in
      write_and_check flow a >>= fun () ->
      let tnow = Mirage_mtime.elapsed_ns () in
      st.bytes <- Int64.of_int amt;
      print_data st tnow >>= fun () ->
      Logs.info (fun f -> f  "iperf client: Done.");
      S.TCP.close flow
    in
    Logs.info (fun f -> f  "Trying to connect to a server at %s:%d, buffer size = %d, protocol = tcp" (Ipaddr.to_string dest_ip) dport len);
    tcp_connect (S.tcp s) (dest_ip, dport) >>= fun flow ->
    iperftx flow >>= fun () ->
    Lwt.return_unit

  let start s =
    let server_ip = Ipaddr.of_string_exn (dest_ip ()) in
    let server_port = (dest_port ()) in
    let total_size = (total_bytes ()) in
    let blen = (payload_size ()) in
    let mlen =
      if blen <= (String.length msg) then blen
      else (String.length msg) in

    Mirage_sleep.ns (Duration.of_sec 1) >>= fun () -> (* Give server 1.0 s to call listen *)
    Lwt.async (fun () -> S.listen s);
    iperfclient s total_size mlen server_ip server_port

end

