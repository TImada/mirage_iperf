open Lwt.Infix

type stats = {
  mutable bytes: int64;
  mutable start_time: int64;
  mutable last_time: int64;
}

module Main (S: Tcpip.Stack.V4V6) = struct

  let iperf_port = 5001

  let print_data st ts_now =
    let duration = Int64.sub ts_now st.start_time in
    let rate = (Int64.float_of_bits st.bytes) /. (Int64.float_of_bits duration) *. 1000. *. 1000. *. 1000. in
    Logs.info (fun f -> f  "iperf server: Duration = %.0Lu [ns] (start_t = %.0Lu, end_t = %.0Lu),  Data received = %Ld [bytes], Throughput = %.2f [bytes/sec]" duration st.start_time ts_now st.bytes rate);
    Logs.info (fun f -> f  "iperf server: Throughput = %.2f [MBs/sec]"  (rate /. 1000000.));
    st.last_time <- ts_now;
    st.bytes <- 0L;
    Lwt.return_unit

  let iperf flow =
    Logs.info (fun f -> f  "iperf server: Received connection.");
    let t0 = Mirage_mtime.elapsed_ns () in
    let st = {
      bytes=0L; start_time = t0; last_time = t0
    } in
    let rec iperf_h flow =
      S.TCP.read flow >|= Rresult.R.get_ok >>= function
      | `Eof ->
        let ts_now = Mirage_mtime.elapsed_ns () in
        st.last_time <- st.start_time;
        print_data st ts_now >>= fun () ->
        S.TCP.close flow >>= fun () ->
        Logs.info (fun f -> f  "iperf server: Done - closed connection.");
        Lwt.return_unit
      | `Data data ->
        begin
          let l = Cstruct.length data in
          st.bytes <- (Int64.add st.bytes (Int64.of_int l));
          iperf_h flow
        end
    in
    iperf_h flow >>= fun () ->
    Lwt.return_unit

 let start s =
   let ips = List.map Ipaddr.Prefix.to_string (S.IP.configured_ips (S.ip s)) in
   Logs.info (fun f -> f "iperf server process started:");
   Logs.info (fun f -> f "IP address: %s" (String.concat "," ips));
   Logs.info (fun f -> f "Port number: %d" iperf_port);

   S.TCP.listen (S.tcp s) ~port:iperf_port (fun flow ->
     iperf flow
   );
   S.listen s

end
