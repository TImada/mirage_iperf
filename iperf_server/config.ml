open Mirage

let sv4 =
  generic_stackv4 default_network

let main = foreign "Unikernel.Main" (stackv4 @-> job)

let () =
  register "iperf_server" [
    main $ sv4
  ]
