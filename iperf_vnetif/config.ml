open Mirage

let packages = 
  [ 
    package "rresult";
    package "io-page";
    package "duration";
    package "mirage-vnetif";
    package "ethernet";
    package "arp" ~sublibs:[ "mirage" ];
    package "tcpip" ~sublibs:[ "icmpv4"; "ipv4"; "ipv6"; "stack-direct"; "tcp"; "udp"; ];
  ]

let main = main ~packages "Unikernel" job

let () =
  register "iperf_vnetif" [
    main 
  ]

