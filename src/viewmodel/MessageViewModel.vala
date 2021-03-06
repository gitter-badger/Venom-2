/*
 *    MessageViewModel.vala
 *
 *    Copyright (C) 2018 Venom authors and contributors
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
  public class MessageViewModel : GLib.Object {
    public bool   additional_info_visible { get; set; }
    public string sender { get; set; }
    public bool   sender_sensitive { get; set; }
    public Gdk.Pixbuf sender_image { get; set; }
    public string timestamp { get; set; }
    public string timestamp_tooltip { get; set; }
    public string message { get; set; }
    public bool   sent_visible { get; set; }
    public bool   received_visible { get; set; }
    public string sender_color { get; set; default = ""; }
    public bool   sender_bold { get; set; default = true; }

    private ILogger logger;
    private IMessage message_content;
    private ISettingsDatabase settings;

    private const string[] colors_light = {"#F44336", "#E91E63", "#9C27B0", "#673AB7", "#2196F3", "#03A9F4", "#00BCD4", "#009688", "#4CAF50", "#FFEB3B"};
    private const string[] colors_dark = {"#8BC34A", "#3F51B5", "#CDDC39", "#FFC107", "#FF9800", "#FF5722", "#795548", "#9E9E9E", "#607D8B"};

    public MessageViewModel(ILogger logger, IMessage message_content, ISettingsDatabase settings) {
      logger.d("MessageViewModel created.");
      this.logger = logger;
      this.message_content = message_content;
      this.settings = settings;

      settings.notify["enable-dark-theme"].connect(on_theme_changed);
      update_sender_color();

      message_content.message_changed.connect(on_message_changed);
      on_message_changed();
    }

    private void on_theme_changed() {
      update_sender_color();
      notify_property("sender");
    }

    private void update_sender_color() {
      if (message_content.message_direction == MessageDirection.OUTGOING) {
        return;
      }
      var hash = message_content.get_sender_id().hash();
      if (settings.enable_dark_theme) {
        sender_color = colors_light[hash % colors_light.length];
      } else {
        sender_color = colors_dark[hash % colors_dark.length];
      }
    }

    private string get_pretty_timestamp() {
      var timestamp = message_content.timestamp;
      var now = new DateTime.now_local();
      var just_now = now.add_minutes(-1);
      if (timestamp.compare(just_now) > 0) {
        return _("Just now");
      }
      var minutes_ago = now.add_minutes(-59);
      if (timestamp.compare(minutes_ago) > 0) {
        var minutes = (uint) (now.difference(timestamp) / TimeSpan.MINUTE);
        return ngettext("%u minute ago", "%u minutes ago", minutes).printf(minutes);
      }
      var hours_ago = now.add_hours(-6);
      if (timestamp.compare(hours_ago) > 0) {
        var hours = (uint) (now.difference(timestamp) / TimeSpan.HOUR);
        return ngettext("%u hour ago", "%u hours ago", hours).printf(hours);
      }
      var midnight = new DateTime.local(now.get_year(), now.get_month(), now.get_day_of_month(), 0, 0, 0);
      if (timestamp.compare(midnight) > 0) {
        return _("Today at %s").printf(timestamp.format("%X"));
      }
      var yesterday = midnight.add_days(-1);
      if (timestamp.compare(yesterday) > 0) {
        return _("Yesterday at %s").printf(timestamp.format("%X"));
      }
      return timestamp.format("%c");
    }

    public void on_state_flags_changed(Gtk.StateFlags flag) {
      additional_info_visible = Gtk.StateFlags.PRELIGHT in flag || Gtk.StateFlags.SELECTED in flag;
      if (additional_info_visible) {
        timestamp = get_pretty_timestamp();
      }
    }

    private void on_message_changed() {
      var outoing = message_content.message_direction == MessageDirection.OUTGOING;
      sender_sensitive = !outoing;
      if (outoing) {
        received_visible = message_content.received;
        sent_visible = !message_content.received;
        sender = _("me");
      } else {
        sender = message_content.get_sender_plain();
      }

      message = message_content.get_message_plain();
      var pixbuf = message_content.get_sender_image();
      if (pixbuf != null) {
        sender_image = pixbuf.scale_simple(44, 44, Gdk.InterpType.BILINEAR);
      }
      timestamp = get_pretty_timestamp();
      timestamp_tooltip = message_content.timestamp.format("%c");
    }

    ~MessageViewModel() {
      logger.d("MessageViewModel destroyed.");
    }
  }

  public class PangoTransform : GLib.Object {
    public string color { get; set; default = ""; }
    public bool bold { get; set; }

    public bool transform(GLib.Binding binding, GLib.Value source, ref GLib.Value dest) {
      var source_string = source.get_string();
      if (bold || color != "") {
        var builder = new StringBuilder();
        builder.append("<span ");
        if (bold) {
          builder.append("font_weight=\"bold\" ");
        }
        if (color != "") {
          builder.append(@"color=\"$color\"");
        }
        builder.append(">");
        builder.append(Markup.escape_text(source_string));
        builder.append("</span>");
        dest.set_string(builder.str);
      } else {
        dest.set_string(Markup.escape_text(source_string));
      }
      return true;
    }
  }

  public class UriTransform {
    private ILogger logger;
    public UriTransform(ILogger logger) {
      this.logger = logger;
    }

    public bool transform(GLib.Binding binding, GLib.Value source, ref GLib.Value dest) {
      var source_string = source.get_string();
      try {
        dest.set_string(uri_regex().replace(Markup.escape_text(source_string), -1, 0, "<a href=\"\\g<u>\">\\g<u></a>"));
      } catch (RegexError e) {
        logger.e("Error transforming text: " + e.message);
        return false;
      }
      return true;
    }

    private static GLib.Regex _uri_regex;
    private static GLib.Regex uri_regex() throws RegexError {
      if (_uri_regex == null) {
        _uri_regex = new GLib.Regex("(?<u>[a-z]+://\\S*)");
      }
      return _uri_regex;
    }
  }
}
