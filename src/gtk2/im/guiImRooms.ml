(* Copyright 2004 b8_bavard *)
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

open Options
open ImOptions
open ImAccount
open ImProtocol
open ImEvent
open ImTypes
open ImIdentity
open ImChat
open ImRoom  

module O = GuiOptions
module A = GuiArt
module U = GuiUtf8
module M = GuiMessages

let verbose = !!O.gtk_verbose_im

let lprintf' fmt =
  Printf2.lprintf ("GuiIm: " ^^ fmt)

(*************************************************************************)
(*                                                                       *)
(*                         Templates                                     *)
(*                                                                       *)
(*************************************************************************)

module Identities = GuiTemplates.Gview(struct

  module Column = GuiColumns.IMIdentities

  type item = identity
  type key = int

  let columns = O.identities_columns
  let get_key = (fun c -> identity_num c)
  let module_name = "IM Identities"

end)

class g_identity () =
  let id_cols      = new GTree.column_list in
  let id_name      = id_cols#add Gobject.Data.string in
  object (self)

    inherit Identities.g_list id_cols

(*************************************************************************)
(*                                                                       *)
(*                         from_item                                     *)
(*                                                                       *)
(*************************************************************************)

    method from_item (row : Gtk.tree_iter) (id : identity) =
      store#set ~row ~column:id_name (U.utf8_of (identity_name id))

(*************************************************************************)
(*                                                                       *)
(*                         from_new_item                                 *)
(*                                                                       *)
(*************************************************************************)

    method from_new_item (row : Gtk.tree_iter) (id : identity) (id_new : identity) =
      self#from_item row id_new

(*************************************************************************)
(*                                                                       *)
(*                         content                                       *)
(*                                                                       *)
(*************************************************************************)

    method content col c =
      let renderer = GTree.cell_renderer_text [`XALIGN 0.] in
      col#pack renderer;
      col#add_attribute renderer "text" id_name

(*************************************************************************)
(*                                                                       *)
(*                         sort_items                                    *)
(*                                                                       *)
(*************************************************************************)

    method sort_items c id1 id2 =
      compare (String.lowercase (identity_name id1)) (String.lowercase (identity_name id2))

  end

(*************************************************************************)
(*                                                                       *)
(*                         Types                                         *)
(*                                                                       *)
(*************************************************************************)

type im_room =
  {
    buffer : GuiTemplates.chat_buffer;
    store  : g_identity;
    box    : GObj.widget;
  }

(*************************************************************************)
(*                                                                       *)
(*                         Global tables                                 *)
(*                                                                       *)
(*************************************************************************)

let rooms = Hashtbl.create 13

(*************************************************************************)
(*                                                                       *)
(*                         messages to the core                          *)
(*                                                                       *)
(*************************************************************************)

let on_entry_return room s =
  (if verbose then lprintf' "SEND MESSAGE %s\n" s);
  room_send room s

(*************************************************************************)
(*                                                                       *)
(*                         on_double_click_identity                      *)
(*                                                                       *)
(*************************************************************************)

let on_double_click_identity id =
  identity_open_chat id

(*************************************************************************)
(*                                                                       *)
(*                         room_window                                   *)
(*                                                                       *)
(*************************************************************************)

let room_window room =
  let hbox = GPack.hbox ~homogeneous:false ~border_width:6 () in
  let hpaned_room = GPack.paned `HORIZONTAL ~packing:hbox#add () in
  let my_name = account_name (room_account room) in
  let idstore = new g_identity () in
  let room_buf =
    GuiTemplates.chat_buffer ~smileys:true
      ~on_entry:(on_entry_return room) ()
  in
  let room_chat =
    GuiTemplates.chat_view ~extended:true ~buffer:room_buf
      ~my_name ~packing:hpaned_room#add1 ()
  in
  let vbox_id =
     GPack.vbox ~homogeneous:false ~spacing:6 
      ~packing:hpaned_room#add2 ()
  in
  let idview =
    Identities.treeview ~mode:`MULTIPLE
      ~packing:(vbox_id#pack ~fill:true ~expand:true) ()
  in
  idview#set_model idstore#gmodel;
  idview#set_on_double_click on_double_click_identity;
  let wtool = GuiTools.tool_bar `HORIZONTAL ~layout:`END ~packing:(vbox_id#pack ~fill:true ~expand:false) () in
  let markup = GuiTools.create_markup !M.iM_lb_close in
  let bClose = wtool#add_button
      ~style:`BOTH_HORIZ
      ~icon:(A.get_icon ~icon:M.icon_stock_close ~size:A.SMALL ())
      ~markup
      ~f:(fun _ -> room_quit room) ()
  in
  GuiTools.set_hpaned hpaned_room O.im_room_hpane;
  GuiTools.get_hpaned hpaned_room O.im_room_hpane;
  {buffer = room_buf; store = idstore; box = hbox#coerce}

(*************************************************************************)
(*                                                                       *)
(*                         messages from the core                        *)
(*                                                                       *)
(*************************************************************************)

let update_identity id_new idstore =
  try
    let (row, id) = idstore#find_item (identity_num id_new) in
    idstore#update_item row id id_new
  with _ -> 
    ignore (idstore#add_item id_new)

let remove_identity id idstore = 
  try
    let (_, id) = idstore#find_item (identity_num id) in
    idstore#remove_item id
  with _ -> ()

let h_join_room room (note : GPack.notebook) =
  try
    let ro = Hashtbl.find rooms (room_num room) in
    ()
  with _ ->
    begin
      let ro = room_window room in
      let text =
        U.utf8_of (Printf.sprintf "%s: Room %s"
          (protocol_name (room_protocol room)) (room_name room))
      in
      let label = GMisc.label ~text () in
      note#append_page ~tab_label:label#coerce ro.box;
      Hashtbl.add rooms (room_num room) ro
    end

let h_leave_room room =
  try
    let ro = Hashtbl.find rooms (room_num room) in
    ro.buffer#clear ();
    ro.store#clear ();
    ro.box#destroy ();
    Hashtbl.remove rooms (room_num room)
  with _ -> ()

let h_room_event room event =
  try
    let ro = Hashtbl.find rooms (room_num room) in
    match event with
        Room_message (_, id, msg) ->
          begin
            let nick = identity_name id in
            ro.buffer#insert_text (Printf.sprintf "%s\n" msg) nick ();
          end

      | Room_user_join (_, identity) ->
          update_identity identity ro.store
      
      | Room_user_leave (_, identity) ->
          remove_identity identity ro.store

      | Room_public_message (_, msg) ->
            ro.buffer#insert_text (Printf.sprintf "%s\n\n" msg) (room_name room) ()

      | _ -> 
          (if verbose then lprintf' "unused room event\n")
  with _ -> ()