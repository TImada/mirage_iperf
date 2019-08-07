open Mirage

let sv4 =
  generic_stackv4 default_network

let main = foreign "Unikernel.Main" (stackv4 @-> time @-> job)

(* let tracing = mprof_trace ~size:2000000 () *)

let () =
  (* register "iperf_client" ~tracing [ *)
  register "iperf_client" [
    main $ sv4 $ default_time
  ]
