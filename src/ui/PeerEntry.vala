/*
 *    PeerEntry.vala
 *
 *    Copyright (C) 2018  Venom authors and contributors
 *
 *    This file is part of Venom.
 *
 *    Venom is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    Venom is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with Venom.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Venom {
  [GtkTemplate(ui = "/im/tox/venom/ui/peer_entry.ui")]
  public class PeerEntry : Gtk.ListBoxRow {
    [GtkChild]
    private Gtk.Image peer_image;
    [GtkChild]
    private Gtk.Label peer_name;
    [GtkChild]
    private Gtk.Label peer_key;
    [GtkChild]
    private Gtk.Image peer_known;

    private ILogger logger;

    public PeerEntry(ILogger logger, GroupchatPeer peer) {
      this.logger = logger;
      peer_name.label = peer.name;
      peer_key.label = peer.tox_public_key;
      peer_known.visible = peer.known;
      logger.d("PeerEntry created.");
    }

    ~PeerEntry() {
      logger.d("PeerEntry destroyed.");
    }
  }
}