open Vnetif_common
open Lwt.Infix

type stats_c = {
  mutable bytes: int64;
  mutable start_time: int64;
  mutable last_time: int64;
}
type stats_s = {
  mutable bytes: int64;
}

module Main (Time : Mirage_types_lwt.TIME) = struct
  module B = Vnetif_backends.Basic
  module V = VNETIF_STACK (B) (Time)
  let backend = V.create_backend ()

  let netmask = 24
  let gw = Some (Ipaddr.V4.of_string_exn "192.168.122.1")
  let client_ip = Ipaddr.V4.of_string_exn "192.168.122.101"
  let server_ip = Ipaddr.V4.of_string_exn "192.168.122.100"
  let server_port = 5001
  let client_port = 5002
  let total_size = 100_000_000
  let blen = 2048

  let msg =
    "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789001234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

  let mlen =
    if blen <= (String.length msg) then blen
    else (String.length msg)

  let print_data st ts_now =
    let duration = Int64.sub ts_now st.start_time in
    let rate = (Int64.float_of_bits st.bytes) /. (Int64.float_of_bits duration) *. 1000. *. 1000. *. 1000. in
    Logs.info (fun f -> f  "iperf client: Duration = %.0Lu [ns] (start_t = %.0Lu, end_t = %.0Lu),  Data received = %Ld [bytes], Throughput = %.2f [bytes/sec]" duration st.start_time ts_now st.bytes rate);
    Logs.info (fun f -> f  "iperf client: Throughput = %.2f [MBs/sec]"  (rate /. 1000000.));
    Lwt.return_unit

  let write_and_check flow buf =
    V.Stackv4.TCPV4.write flow buf >|= Rresult.R.get_ok

  let tcp_connect t (ip, port) =
    V.Stackv4.TCPV4.create_connection t (ip, port) >|= Rresult.R.get_ok

  let iperfclient s amt dest_ip dport clock =
    let iperftx flow =
      Logs.info (fun f -> f  "iperf client: %.0d bytes data transfer initiated." amt);
      let a = Cstruct.sub (Io_page.(to_cstruct (get 1))) 0 mlen in
      Cstruct.blit_from_string msg 0 a 0 mlen;
      let rec loop = function
        | 0 -> Lwt.return_unit
        | n -> write_and_check flow a >>= fun () -> loop (n-1)
      in
      let t0 = Mclock.elapsed_ns clock in
      let st_client = {
        bytes=0L; start_time = t0; last_time = t0
      } in
      loop (amt / mlen) >>= fun () ->
      let a = Cstruct.sub a 0 (amt - (mlen * (amt/mlen))) in
      write_and_check flow a >>= fun () ->
      let tnow = Mclock.elapsed_ns clock in
      st_client.bytes <- Int64.of_int total_size;
      print_data st_client tnow >>= fun () ->
      Logs.info (fun f -> f  "iperf client: Done.");
      V.Stackv4.TCPV4.close flow
    in
    Logs.info (fun f -> f  "Trying to connect to a server at %s:%d, buffer size = %d" (Ipaddr.V4.to_string server_ip) server_port mlen);
    tcp_connect (V.Stackv4.tcpv4 s) (dest_ip, dport) >>= fun flow ->
    iperftx flow >>= fun () ->
    Lwt.return_unit

  let iperf clock flow =
    (* debug is too much for us here *)
    Logs.set_level ~all:true (Some Logs.Info);
    Logs.info (fun f -> f  "iperf server: Received connection.");
    let t0 = Mclock.elapsed_ns clock in
    let st_server = {
      bytes=0L;
    } in
    let rec iperf_h flow =
      V.Stackv4.TCPV4.read flow >|= Rresult.R.get_ok >>= function
      | `Eof ->
        let ts_now = Mclock.elapsed_ns clock in
        V.Stackv4.TCPV4.close flow >>= fun () ->
        Logs.info (fun f -> f  "iperf server: Done - closed connection.");
        Lwt.return_unit
      | `Data data ->
        begin
          let l = Cstruct.len data in
          st_server.bytes <- (Int64.add st_server.bytes (Int64.of_int l));
          iperf_h flow
        end
    in
    iperf_h flow >>= fun () ->
    Lwt.return_unit

  let start _time =
    Time.sleep_ns (Duration.of_sec 1) >>= fun () -> (* Give server 1.0 s to call listen *)
    Mclock.connect () >>= fun clock ->
    Lwt.pick [

    (* client side *)
    (
      Time.sleep_ns (Duration.of_sec 3) >>= fun () -> (* Give server 3.0 s to call listen *)
      V.create_stack backend client_ip netmask gw >>= fun client_s ->
      V.Stackv4.listen_udpv4 client_s ~port:client_port (fun ~src ~dst ~src_port buf ->
        Logs.info (fun f -> f "iperf client: The server side received %.0Lu Bytes" (Int64.of_string (Cstruct.to_string buf)));
        Lwt.return_unit 
      );
      Logs.info (fun f -> f "iperf client: Thread started:");
      Logs.info (fun f -> f "iperf client: IP address: %s" (Ipaddr.V4.to_string client_ip));
      Logs.info (fun f -> f "iperf client: Port number: %d" client_port);

      Lwt.async (fun () -> V.Stackv4.listen client_s);
      iperfclient client_s total_size server_ip server_port clock
    );

    (* server side *)
    (
      Logs.info (fun f -> f "iperf server: Thread started:");
      Logs.info (fun f -> f "iperf server: IP address: %s" (Ipaddr.V4.to_string server_ip));
      Logs.info (fun f -> f "iperf server: Port number: %d" server_port);

      V.create_stack backend server_ip netmask gw >>= fun server_s ->
      V.Stackv4.listen_tcpv4 server_s ~port:server_port (fun flow -> iperf clock flow);
      V.Stackv4.listen server_s
    );

    ]

end

