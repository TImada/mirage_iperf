open Mirage

let sv4v6 =
  generic_stackv4v6 default_network

let packages = 
  [ 
    package "rresult";
  ]

let main = main ~packages "Unikernel.Main" (stackv4v6 @-> job)

let () =
  register "iperf_server" [
    main $ sv4v6
  ]
