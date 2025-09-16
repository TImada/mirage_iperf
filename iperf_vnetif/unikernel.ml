open Lwt.Infix

type stats_c = {
  mutable bytes: int64;
  mutable start_time: int64;
  mutable last_time: int64;
}

type stats_s = {
  mutable bytes: int64;
}

module Vstack(B: Vnetif.BACKEND) = struct
  module V = Vnetif_stack.Vnetif_stack(B)
  include V
end

module Backend = Basic_backend.Make
module Stack = Vstack(Backend)
let backend = Backend.create ~use_async_readers:true ~yield:(fun () -> Mirage_sleep.ns (Duration.of_sec 0)) ()

let c_cidr = Ipaddr.of_string_exn "192.168.122.101"
let s_cidr = Ipaddr.of_string_exn "192.168.122.100"
let server_port = 5001
let client_port = 5002
let total_size = 100_000_000
let blen = 2048

let msg =
  "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789001234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

let mlen =
  if blen <= (String.length msg) then blen
  else (String.length msg)

let print_data (st:stats_c) ts_now =
  let duration = Int64.sub ts_now st.start_time in
  let rate = (Int64.to_float st.bytes) /. (Int64.to_float duration) *. 1000. *. 1000. *. 1000. in
  Logs.info (fun f -> f  "iperf client: Duration = %.0Lu [ns] (start_t = %.0Lu, end_t = %.0Lu),  Data received = %Ld [bytes], Throughput = %.2f [bytes/sec]" duration st.start_time ts_now st.bytes rate);
  Logs.info (fun f -> f  "iperf client: Throughput = %.2f [MBs/sec]"  (rate /. 1000000.));
  Lwt.return_unit

let write_and_check flow buf =
  Stack.V4V6.TCP.write flow buf >|= Rresult.R.get_ok

let tcp_connect t (ip, port) =
  Stack.V4V6.TCP.create_connection t (ip, port) >|= Rresult.R.get_ok

let iperfclient flow amt =
  let iperftx flow =
    Logs.info (fun f -> f  "iperf client: %.0d bytes data transfer initiated." amt);
    let a = Cstruct.sub (Io_page.(to_cstruct (get 1))) 0 mlen in
    Cstruct.blit_from_string msg 0 a 0 mlen;
    let rec loop = function
      | 0 -> Lwt.return_unit
      | n -> write_and_check flow a >>= fun () -> loop (n-1)
    in
    let t0 = Mirage_mtime.elapsed_ns () in
    let st_client = {
      bytes=0L; start_time = t0; last_time = t0
    } in
    loop (amt / mlen) >>= fun () ->
    let a = Cstruct.sub a 0 (amt - (mlen * (amt/mlen))) in
    write_and_check flow a >>= fun () ->
    let tnow = Mirage_mtime.elapsed_ns () in
    st_client.bytes <- Int64.of_int total_size;
    print_data st_client tnow >>= fun () ->
    Logs.info (fun f -> f  "iperf client: Done.");
    Stack.V4V6.TCP.close flow
  in
  Logs.info (fun f -> f  "Trying to connect to a server at %s:%d, buffer size = %d" (Ipaddr.to_string s_cidr) server_port mlen);
  iperftx flow >>= fun () ->
  Lwt.return_unit

let iperf flow =
  (* debug is too much for us here *)
  Logs.set_level ~all:true (Some Logs.Info);
  Logs.info (fun f -> f  "iperf server: Received connection.");
  let st_server = {
    bytes=0L;
  } in
  let rec iperf_h flow =
    Stack.V4V6.TCP.read flow >|= Rresult.R.get_ok >>= function
    | `Eof ->
      Stack.V4V6.TCP.close flow >>= fun () ->
      Logs.info (fun f -> f  "iperf server: Done - closed connection.");
      Lwt.return_unit
    | `Data data ->
      begin
        let l = Cstruct.length data in
        st_server.bytes <- (Int64.add st_server.bytes (Int64.of_int l));
        iperf_h flow
      end
  in
  iperf_h flow >>= fun () ->
  Lwt.return_unit

let start () =
  Lwt.pick [

  (* client side *)
  (
    let client_ipv4 = Ipaddr.V4.Prefix.make 24 (Option.get (Ipaddr.to_v4 c_cidr)) in
    Mirage_sleep.ns (Duration.of_sec 3) >>= fun () -> (* Give server 3.0 s to call listen *)

    Stack.create_stack_ipv4 ~cidr:client_ipv4 backend >>= fun client_s ->
    tcp_connect (Stack.V4V6.tcp client_s) (s_cidr, server_port) >>= fun flow ->
    Logs.info (fun f -> f "iperf client: Thread started:");
    Logs.info (fun f -> f "iperf client: IP address: %s" (Ipaddr.to_string c_cidr));
    Logs.info (fun f -> f "iperf client: Port number: %d" client_port);

    iperfclient flow total_size
  );

  (* server side *)
  (
    let server_ipv4 = Ipaddr.V4.Prefix.make 24 (Option.get (Ipaddr.to_v4 s_cidr)) in
    Logs.info (fun f -> f "iperf server: Thread started:");
    Logs.info (fun f -> f "iperf server: IP address: %s" (Ipaddr.to_string s_cidr));
    Logs.info (fun f -> f "iperf server: Port number: %d" server_port);

    Stack.create_stack_ipv4 ~cidr:server_ipv4 backend >>= fun server_s ->
    Stack.V4V6.TCP.listen (Stack.V4V6.tcp server_s) ~port:server_port (fun flow -> iperf flow);
    Stack.V4V6.listen server_s
  );

  ]

