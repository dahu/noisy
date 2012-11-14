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
# TODO Shouldn't a loop be used to handle the settings here?
weechat::config_set_plugin("highlight", $default_noisy{'highlight'}) if (weechat::config_get_plugin("highlight") eq "");
weechat::config_set_plugin("player", $default_noisy{'player'}) if (weechat::config_get_plugin("player") eq "");
weechat::config_set_plugin("sound_dir", $default_noisy{'sound_dir'}) if (weechat::config_get_plugin("sound_dir") eq "");
weechat::config_set_plugin("pv", $default_noisy{'pv'}) if (weechat::config_get_plugin("pv") eq "");
weechat::config_set_plugin("msg", $default_noisy{'msg'}) if (weechat::config_get_plugin("msg") eq "");
weechat::config_set_plugin("msg_off_channels", $default_noisy{'msg_off_channels'}) if (weechat::config_get_plugin("msg_off_channels") eq "");
weechat::config_set_plugin("msg_soft_channels", $default_noisy{'msg_soft_channels'}) if (weechat::config_get_plugin("msg_soft_channels") eq "");
weechat::config_set_plugin("msg_loud_channels", $default_noisy{'msg_loud_channels'}) if (weechat::config_get_plugin("msg_loud_channels") eq "");
weechat::config_set_plugin("msg_norm_channels", $default_noisy{'msg_norm_channels'}) if (weechat::config_get_plugin("msg_norm_channels") eq "");
weechat::config_set_plugin("msg_priv_channels", $default_noisy{'msg_priv_channels'}) if (weechat::config_get_plugin("msg_priv_channels") eq "");

# TODO Not sure if 'our' is the correct way to fix error from using those vars in the foreach loop.
our $sound_dir = weechat::config_get_plugin("sound_dir");
our %noisy_sounds = ('highlight'      => "",
                    'msg'            => "",
                    'pv'             => "",
                    'soft_highlight' => "",
                    'soft_msg'       => "",
                    'soft_pv'        => "",
                    'loud_highlight' => "",
                    'loud_msg'       => "",
                    'loud_pv'        => "",
                    'norm_highlight' => "",
                    'norm_msg'       => "",
                    'norm_pv'        => "",
                    'priv_highlight' => "",
                    'priv_msg'       => "",
                    'priv_pv'        => "",
                  );
foreach my $key (keys %noisy_sounds) {
  %noisy_sounds->{$key} = "$sound_dir/$key";
}

weechat::hook_signal("weechat_highlight", "noisy", "highlight");
weechat::hook_signal("irc_pv", "noisy", "pv");
weechat::hook_signal("freenode,irc_in_privmsg", "noisy", "msg");
weechat::hook_signal('weechat_pv', 'noisy', "highlight");

sub play {
  my $player = weechat::config_get_plugin("player");
  my $key = $_[0];
  my $noisy = $_[1];
  system("$player $noisy_sounds{$key} 2>/dev/null &") if ($noisy eq "on");
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
  #weechat::print("", $message);
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

