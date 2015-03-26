# Copyright (c) 2010 by Barry Arthur <barry.arthur@gmail.com>:
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# Use alsa's aplay to play a sound on channel activity, highlights and private
# messages.
#
# History:
# 2011-01-04, bairui <barry.arthur@gmail.com>:
#     version 0.2: limited msg beeps to certain channels
# 2010-07-03, bairui <barry.arthur@gmail.com>:
#     version 0.1: initial release (modified from FlashCode's beep.pl)
#

use strict;

my $version = "0.2";

# default values in setup file (~/.weechat/plugins.conf)
my %default_noisy = ('player'            => "/usr/bin/aplay",
                     'sound_dir'         => "~/.weechat/sounds",
                     'highlight'         => "on",
                     'pv'                => "on",
                     'msg'               => "off",
                     'msg_off_channels'  => "",
                     'msg_soft_channels' => "",
                     'msg_loud_channels' => "",
                     'msg_norm_channels' => "",
                     'msg_priv_channels' => ""
                     );

weechat::register("noisy", "bairui <barry.arthur\@gmail.com>", $version,
                  "GPL3", "Play a sound on channel activity/highlight/private message", "", "");

foreach my $key (keys %default_noisy) {
  weechat::config_set_plugin($key, $default_noisy{$key}) if (weechat::config_get_plugin($key) eq "");
}

weechat::hook_signal("weechat_highlight", "noisy", "highlight");
weechat::hook_signal("irc_pv", "noisy", "pv");
weechat::hook_signal("freenode,irc_in_privmsg", "noisy", "msg");
weechat::hook_signal('weechat_pv', 'noisy', "highlight");

sub play {
  my $player = weechat::config_get_plugin("player");
  my $dir = weechat::config_get_plugin("sound_dir");
  my $key = $_[0];
  my $noisy = $_[1];
  system("$player $dir/$key 2>/dev/null &") if ($noisy eq "on");
}

sub match {
  return (weechat::config_get_plugin($_[1]) ne "" && $_[0] =~ weechat::config_get_plugin($_[1]))
}

sub noisy {
  my $action = $_[0];
  my $server = $_[1];
  my $message = $_[2]; # including #channel name
  my $noisy = weechat::config_get_plugin("$action");
  my $player = weechat::config_get_plugin("player");
  my $option = weechat::config_get("plugins.var.perl.badnick.bad_nicks");
  my @bad_nicks = split(/\s*,\s*/, weechat::config_string($option));
  if( $message =~ /^:([^!]+)/ ) {
    my $nick = $1;
    return weechat::WEECHAT_RC_OK if grep {$_ eq $nick} @bad_nicks;
  }
  if (match($message, "msg_off_channels")) {
    # do nothing
  } elsif (match($message, "msg_soft_channels")) {
    play('soft_'.$action, $noisy);
  } elsif (match($message, "msg_loud_channels")) {
    play('loud_'.$action, $noisy);
  } elsif (match($message, "msg_norm_channels")) {
    play('norm_'.$action, $noisy);
  } elsif (match($message, "msg_priv_channels")) {
    play('priv_'.$action, $noisy);
  } elsif (($action =~ /(highlight|pv)/i) || (match($message, "msg_channels")) || ($noisy eq "on")) {
    play($action, $noisy);
  }
  return weechat::WEECHAT_RC_OK;
}

