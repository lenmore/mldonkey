(* Copyright 2001, 2002 b8_bavard, b8_fee_carabine, INRIA *)
(*
    This file is part of mldonkey.

    mldonkey is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    mldonkey is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with mldonkey; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)

val save_file : DonkeyTypes.file -> string -> unit
val saved_name : DonkeyTypes.file -> string

(*
val query_download : string list -> int32 -> Md4.t -> int option
  -> string option -> (int32 * int32) list option -> unit
(*val save_file: Md4.t -> string -> unit *)
val forget_search : int -> unit
val load_server_met : string -> unit
  
  
val reconnect_all : DonkeyTypes.file -> unit
  
val import_config : string -> unit
val print_file : Buffer.t -> DonkeyTypes.file -> unit
val display_file_list : 
  Buffer.t -> Gui_proto.connection_options -> unit
val aborted_download :
    (string list * int32 * Md4.t * int option * string option *
     (int32 * int32) list option)
    option ref
val really_query_download :
    string list ->
    int32 ->
    Md4.t ->
    int option -> string option -> (int32 * int32) list option -> unit
val print_search :
    Buffer.t ->
    DonkeyTypes.local_search -> Gui_proto.connection_options -> unit
  
val print_connected_servers : Buffer.t -> unit

*)
  
val disconnect_server : DonkeyTypes.server -> unit
  