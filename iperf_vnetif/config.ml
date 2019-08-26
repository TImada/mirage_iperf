open Mirage

let main =
  let packages = [ package ~sublibs:["ipv4"; "icmpv4"; "tcp"; "udp"; "stack-direct"] "tcpip"; package "ethernet"; package "arp-mirage"; package "duration"; package "mirage-vnetif" ; package "mirage-random-stdlib" ] in
  foreign
    ~packages
    "Unikernel.Main" (time @-> job)

let () =
  register "iperf_vnetif" [
    main $ default_time
  ]

