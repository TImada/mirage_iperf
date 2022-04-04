open Mirage

let sv4 =
  generic_stackv4 default_network

let packages =
  [ package "rresult"; package "io-page"; package "duration" ]

let main = main ~packages "Unikernel.Main" (stackv4 @-> time @-> mclock @-> job)

(* let tracing = mprof_trace ~size:2000000 () *)

let () =
  (* register "iperf_client" ~tracing [ *)
  register "iperf_client" [
    main $ sv4 $ default_time $ default_monotonic_clock
  ]
