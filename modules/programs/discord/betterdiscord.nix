{pkgs, ...}: let
  plugin-repo = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/mwittrien/BetterDiscordAddons/e27e1b5f0a507d57cea34b793dde8e2555acd1fd/Plugins/PluginRepo/PluginRepo.plugin.js";
    sha256 = "sha256:0gh1nlpiw0qi2vzg81brr8yyjhlrw0ksdkvjzy1afibswz7w6y0d";
  };
  free-emojis = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/BetterDiscordPlugins/DiscordFreeEmojis/8d34f3f9fc3dafc364fa3d1a3da27feab6f47a0c/DiscordFreeEmojis64px.plugin.js";
    sha256 = "1f524xc7ih0mzx65rr8wjyfxxh253x2236bxdgrmc4qysdpfggzw";
  };
  hide-disabled-emojis = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/rauenzi/BetterDiscordAddons/45cc2cba6bd0fc4230b918d0599c969a6d141a36/Plugins/HideDisabledEmojis/HideDisabledEmojis.plugin.js";
    sha256 = "0m2sr8wxyzi1zpr19g0s7hr5yixabzjg3c1sv7jfbybqxjy5kvjm";
  };
  typing-indicator = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/l0c4lh057/BetterDiscordStuff/e62ddfbdf090a4dd64946e15f789b0e906615366/Plugins/TypingIndicator/TypingIndicator.plugin.js";
    sha256 = "sha256:13bfmrb4icj2kwsagh028zcjhm8zjz17xhynmvzfiyqb9va7rmz5";
  };
  better-friend-list = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/mwittrien/BetterDiscordAddons/e8f0d42452903cdc3b9487cd1ce22cf900453dbd/Plugins/BetterFriendList/BetterFriendList.plugin.js";
    sha256 = "sha256:0b9zw6g81bh2a72aqq1wd3ic86bdpmv8vf8vi3zj5znnbbbzhdvy";
  };
  better-search-page = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/mwittrien/BetterDiscordAddons/241da8656dc90097924407c5a63fcd54c429dca5/Plugins/BetterSearchPage/BetterSearchPage.plugin.js";
    sha256 = "sha256:1za1rkmfp0260pf21yb966qiidzzkv2b2r2zsm105h6ak0zddry9";
  };
  call-time-counter = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/QWERTxD/BetterDiscordPlugins/fae13fe3b3f96ea0d274dc33343a70948a674ecf/CallTimeCounter/CallTimeCounter.plugin.js";
    sha256 = "sha256:10j6cdi2zy5wns1lg2pm8dwvi2pdwiqchlqq9idg717g59aswyw0";
  };
  invisible-typing = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/Strencher/BetterDiscordStuff/32bd29f8e9a1f02d2310f59853f8e84b92324bda/InvisibleTyping/InvisibleTyping.plugin.js";
    sha256 = "sha256:0p9sqmdkzydw6zaiq0l7jlqn00rb77gb6kcpqf3f99krbhy826wf";
  };
  do-not-track = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/rauenzi/BetterDiscordAddons/7d9067e39ce576edea36d96aab71e9cdfe7ff9f1/Plugins/DoNotTrack/DoNotTrack.plugin.js";
    sha256 = "sha256:0klg5m0b641vrlkajqvw224b7acg2jxgfqaflxf4b14xa8r8ajh2";
  };
  who-reacted = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/jaimeadf/BetterDiscordPlugins/3cdc0aded6130725e9a2996156cd8f072e47be45/dist/WhoReacted/WhoReacted.plugin.js";
    sha256 = "sha256:0kzihnf2axh5pcvpif9l3hzsyn4wrai2dzhnbbfp9ka8344x73lv";
  };
  message-logger = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/1Lighty/BetterDiscordPlugins/b5c2048cb1a563a10959452aa06baba2a301ee1c/Plugins/MessageLoggerV2/MessageLoggerV2.plugin.js";
    sha256 = "sha256:04w4w2y5k5jbr48w2311b5x90y10gj9ymj3gp1p2ibhl6nv5iwnh";
  };
in {
  home.file.".config/BetterDiscord/plugins/plugin-repo.plugin.js".source = plugin-repo;

  home.file.".config/BetterDiscord/plugins/free-emojis.plugin.js".source = free-emojis;
  home.file.".config/BetterDiscord/plugins/hide-disabled-emojis.plugin.js".source = hide-disabled-emojis;
  home.file.".config/BetterDiscord/plugins/typing-indicator.plugin.js".source = typing-indicator;
  home.file.".config/BetterDiscord/plugins/better-friend-list.plugin.js".source = better-friend-list;
  home.file.".config/BetterDiscord/plugins/better-search-page.plugin.js".source = better-search-page;
  home.file.".config/BetterDiscord/plugins/call-time-counter.plugin.js".source = call-time-counter;
  home.file.".config/BetterDiscord/plugins/invisible-typing.plugin.js".source = invisible-typing;
  home.file.".config/BetterDiscord/plugins/do-not-track.plugin.js".source = do-not-track;
  home.file.".config/BetterDiscord/plugins/who-reacted.plugin.js".source = who-reacted;
  home.file.".config/BetterDiscord/plugins/message-logger.plugin.js".source = message-logger;
}
