open Mirage

let sv4 =
  generic_stackv4 default_network

let packages = [ package "rresult" ]

let main = main ~packages "Unikernel.Main" (stackv4 @-> mclock @-> job)

let () =
  register "iperf_server" [
    main $ sv4 $ default_monotonic_clock
  ]
