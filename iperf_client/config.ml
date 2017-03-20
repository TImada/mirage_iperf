open Mirage

let client_ipconfig =
  let nw = Ipaddr.V4.Prefix.of_address_string_exn "192.168.122.101/24" in
  let gw = Some (Ipaddr.V4.of_string_exn "192.168.122.1") in
  { network = nw; gateway = gw }

let sv4 =
  generic_stackv4 ~config:client_ipconfig default_network

let main =
  let packages = [ package ~sublibs:["ethif"; "arpv4"; "ipv4"; "icmpv4"; "tcp"; "udp"] "tcpip"; package "duration" ] in
  foreign
    ~packages
    "Unikernel.Main" (stackv4 @-> time @-> job)

(* let tracing = mprof_trace ~size:2000000 () *)

let () =
  (* register "iperf_client" ~tracing [ *)
  register "iperf_client" [
    main $ sv4 $ default_time
  ]

