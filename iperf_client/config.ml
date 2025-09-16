open Mirage

let sv4v6 =
  generic_stackv4v6 default_network

let packages =
  [ 
    package "rresult";
    package "io-page";
    package "duration";
  ]

let main = main ~packages "Unikernel.Main" (stackv4v6 @-> job)

let () =
  register "iperf_client" [
    main $ sv4v6
  ]
