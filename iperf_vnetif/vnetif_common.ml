(*
 * Copyright (c) 2015 Magnus Skjegstad <magnus@skjegstad.com>
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
open Lwt.Infix

let fail fmt = Printf.ksprintf fmt

module type VNETIF_STACK =
sig
  type backend
  type buffer
  type 'a io
  type id
  module Stackv4 : Mirage_stack_lwt.V4
  (** Create a new backend *)
  val create_backend : unit -> backend
  (** Create a new stack connected to an existing backend *)
  val create_stack : backend -> Ipaddr.V4.t -> int -> Ipaddr.V4.t option -> Stackv4.t Lwt.t
  (** Add a listener function to the backend *)
  val create_backend_listener : backend -> (buffer -> unit io) -> id
  (** Disable a listener function *)
  val disable_backend_listener : backend -> id -> unit io
end

module VNETIF_STACK ( B : Vnetif_backends.Backend) (Time : Mirage_types_lwt.TIME) : (VNETIF_STACK with type backend = B.t) = struct
  type backend = B.t
  type buffer = B.buffer
  type 'a io = 'a B.io
  type id = B.id

  module V = Vnetif.Make(B)
  module E = Ethernet.Make(V)
  module A = Arp.Make(E)(Time)
  module Ip = Static_ipv4.Make(Mirage_random_stdlib)(Mclock)(E)(A)
  module Icmp = Icmpv4.Make(Ip)
  module U = Udp.Make(Ip)(Mirage_random_stdlib)
  module T = Tcp.Flow.Make(Ip)(Time)(Mclock)(Mirage_random_stdlib)
  module Stackv4 = Tcpip_stack_direct.Make(Time)(Mirage_random_stdlib)(V)(E)(A)(Ip)(Icmp)(U)(T)

  let create_backend () =
    B.create ()

  let create_stack backend ip netmask gw =
    let network = Ipaddr.V4.Prefix.make netmask ip in
    Mclock.connect () >>= fun clock ->
    V.connect backend >>= fun netif ->
    E.connect netif >>= fun ethif ->
    A.connect ethif >>= fun arpv4 ->
    Ip.connect ~ip ~network ~gateway:gw clock ethif arpv4 >>= fun ipv4 ->
    Icmp.connect ipv4 >>= fun icmpv4 ->
    U.connect ipv4 >>= fun udpv4 ->
    T.connect ipv4 clock >>= fun tcpv4 ->
    Stackv4.connect netif ethif arpv4 ipv4 icmpv4 udpv4 tcpv4

  let create_backend_listener backend listenf =
    match (B.register backend) with
    | Ok id -> (B.set_listen_fn backend id listenf); id

  let disable_backend_listener backend id =
    B.unregister_and_flush backend id

end
