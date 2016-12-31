(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
 * Copyright (c) 2012 Balraj Singh <balraj.singh@cl.cam.ac.uk>
 * Copyright (c) 2015 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2017 Takayuki Imada <takayuki.imada@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

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

let () =
  register "iperf_client" [
    main $ sv4 $ default_time
  ]

