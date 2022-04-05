open Mirage

let packages = 
  [ package "rresult"; package "io-page"; package "duration"; package "mirage-vnetif"; package "mirage-vnetif-stack" ]

let main = main ~packages "Unikernel.Main" (time @-> mclock @-> random @-> job)

let () =
  register "iperf_vnetif" [
    main $ default_time $ default_monotonic_clock $ default_random
  ]

