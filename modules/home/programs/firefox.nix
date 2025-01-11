# https://github.com/hlissner/dotfiles/blob/master/modules/desktop/browsers/firefox.nix
# settings taken from here:
# https://github.com/gvolpe/nix-config/blob/master/home/programs/firefox/default.nix
# https://github.com/brainfucksec/brainfucksec.github.io/blob/f98e18da8a393d3c4cd2f7da123368eb5a936ff6/_posts/2022-03-21-firefox-hardening-guide.md?plain=1#L378
# TODO:
# https://github.com/pyllyukko/user.js/
# TODO: Set search engine in Firefox:
# - https://mozilla.github.io/policy-templates/
# - https://mozilla.github.io/policy-templates/#searchengines--add
# - https://mozilla.github.io/policy-templates/#searchengines--default
#
{
  unstable,
  addons,
  ...
}: let
  # disable the annoying floating icon with camera and mic when on a call
  disableWebRtcIndicator = ''
    #webrtcIndicator {
      display: none;
    }
  '';
in {
  programs.firefox = {
    package = unstable.firefox-wayland;
    policies = {
      NoDefaultBookmarks = true;
      DisableAppUpdate = true;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      DisableFirefoxStudies = true;
      DisableMasterPasswordCreation = true;
      DisablePocket = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        SkipOnboarding = false;
        MoreFromMozilla = false;
      };
      ExtensionSettings = {
        # TODO: https://github.com/kivikakk/vyxos/blob/43bbb767fc6a6a8eecf6e81a71bd5a10553df7fe/modules/desktop/firefox.nix#L39C1-L39C32
      };
      FirefoxHome = {
        Highlights = false;
        Pocket = false;
        Snippets = false;
        SponsporedPocket = false;
        SponsporedTopSites = false;
      };

      SearchEngines = {
        Add = [
          {
            Name = "Brave";
            URLTemplate = "https://search.brave.com/search?q={searchTerms}";
            Method = "GET";
            Alias = "brave";
          }
        ];
        Default = "Brave";
        Remove = [
          "Bing"
          "eBay"
          "Google"
        ];
      };
    };

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      userChrome = disableWebRtcIndicator;
      extraConfig = "";

      settings = {
        # disable updates (pretty pointless with nix)
        "app.update.channel" = "default";

        #####################################
        # Settings from hlissner (see link) #
        #####################################
        # https://github.com/hlissner/dotfiles/blob/master/modules/desktop/browsers/firefox.nix#L65

        # No translations popup
        "browser.translations.automaticallyPopup" = false;

        # Enable ETP for decent security (makes firefox containers and many
        # common security/privacy add-ons redundant).
        "browser.contentblocking.category" = "strict";
        "privacy.donottrackheader.enabled" = true;
        "privacy.donottrackheader.value" = 1;
        "privacy.purge_trackers.enabled" = true;

        # Do not check if Firefox is the default browser
        "browser.shell.checkDefaultBrowser" = false;

        # Disable the "new tab page" feature and show a blank tab instead
        # https://wiki.mozilla.org/Privacy/Reviews/New_Tab
        # https://support.mozilla.org/en-US/kb/new-tab-page-show-hide-and-customize-top-sites#w_how-do-i-turn-the-new-tab-page-off
        "browser.newtabpage.enabled" = false;
        "browser.newtab.url" = "about:blank";

        # Disable Activity Stream
        # https://wiki.mozilla.org/Firefox/Activity_Stream
        "browser.newtabpage.activity-stream.enabled" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;

        # Disable new tab tile ads & preload
        # http://www.thewindowsclub.com/disable-remove-ad-tiles-from-firefox
        # http://forums.mozillazine.org/viewtopic.php?p=13876331#p13876331
        # https://wiki.mozilla.org/Tiles/Technical_Documentation#Ping
        # https://gecko.readthedocs.org/en/latest/browser/browser/DirectoryLinksProvider.html#browser-newtabpage-directory-source
        # https://gecko.readthedocs.org/en/latest/browser/browser/DirectoryLinksProvider.html#browser-newtabpage-directory-ping
        "browser.newtabpage.enhanced" = false;
        "browser.newtabpage.introShown" = true;
        "browser.newtabpage.directory.ping" = "";
        "browser.newtabpage.directory.source" = "data:text/plain,{}";

        # Reduce search engine noise in the urlbar's completion window. The
        # shortcuts and suggestions will still work, but Firefox won't clutter
        # its UI with reminders that they exist.
        "browser.urlbar.shortcuts.bookmarks" = false;
        "browser.urlbar.shortcuts.history" = false;
        "browser.urlbar.shortcuts.tabs" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.urlbar.speculativeConnect.enabled" = false;

        # disable all the annoying quick actions
        "browser.urlbar.quickactions.enabled" = false;
        "browser.urlbar.quickactions.showPrefs" = false;
        "browser.urlbar.shortcuts.quickactions" = false;
        "browser.urlbar.suggest.quickactions" = false;
        "browser.urlbar.suggest.trending" = false;
        "browser.search.suggest.enabled" = false;

        # Disable suggestions in urlbar
        "browser.urlbar.suggest.history" = false;
        "browser.urlbar.suggest.bookmark" = false;
        "browser.urlbar.suggest.clipboard" = false;
        "browser.urlbar.suggest.openpage" = false;
        "browser.urlbar.suggest.engines" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.weather" = false;
        "browser.urlbar.suggest.topsites" = false;

        # https://blog.mozilla.org/data/2021/09/15/data-and-firefox-suggest/
        "browser.urlbar.suggest.quicksuggest" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;

        # Disable some not so useful functionality.
        "browser.disableResetPrompt" = true; # "Looks like you haven't started Firefox in a while."
        "browser.onboarding.enabled" = false; # "New to Firefox? Let's get started!" tour
        "browser.aboutConfig.showWarning" = false; # Warning when opening about:config
        "extensions.unifiedExtensions.enabled" = false;
        "extensions.shield-recipe-client.enabled" = false;
        "reader.parse-on-load.enabled" = false; # "reader view"

        # Show whole URL in address bar TODO: ???
        "browser.urlbar.trimURLs" = false;

        ##############################
        # Security-oriented defaults #
        ##############################

        "security.family_safety.mode" = 0;

        # https://blog.mozilla.org/security/2016/10/18/phasing-out-sha-1-on-the-public-web/
        "security.pki.sha1_enforcement_level" = 1;

        # Use Mozilla geolocation service instead of Google if given permission
        "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
        "geo.provider.use_gpsd" = false;

        # https://support.mozilla.org/en-US/kb/extension-recommendations
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "extensions.htmlaboutaddons.discover.enabled" = false;
        "extensions.getAddons.showPane" = false; # uses Google Analytics
        "browser.discovery.enabled" = false;

        # Reduce File IO / SSD abuse
        # Otherwise, Firefox bombards the HD with writes. Not so nice for SSDs.
        # This forces it to write every 30 minutes, rather than 15 seconds.
        "browser.sessionstore.interval" = "1800000";

        # Disable battery API
        # https://developer.mozilla.org/en-US/docs/Web/API/BatteryManager
        # https://bugzilla.mozilla.org/show_bug.cgi?id=1313580
        "dom.battery.enabled" = false;

        # Disable "beacon" asynchronous HTTP transfers (used for analytics)
        # https://developer.mozilla.org/en-US/docs/Web/API/navigator.sendBeacon
        "beacon.enabled" = false;

        # Disable pinging URIs specified in HTML <a> ping= attributes
        # http://kb.mozillazine.org/Browser.send_pings
        "browser.send_pings" = false;

        # Disable gamepad API to prevent USB device enumeration
        # https://www.w3.org/TR/gamepad/
        # https://trac.torproject.org/projects/tor/ticket/13023
        "dom.gamepad.enabled" = false;

        # Don't try to guess domain names when entering an invalid domain name in URL bar
        # http://www-archive.mozilla.org/docs/end-user/domain-guessing.html
        "browser.fixup.alternate.enabled" = false;

        # Disable telemetry
        # https://wiki.mozilla.org/Platform/Features/Telemetry
        # https://wiki.mozilla.org/Privacy/Reviews/Telemetry
        # https://wiki.mozilla.org/Telemetry
        # https://www.mozilla.org/en-US/legal/privacy/firefox.html#telemetry
        # https://support.mozilla.org/t5/Firefox-crashes/Mozilla-Crash-Reporter/ta-p/1715
        # https://wiki.mozilla.org/Security/Reviews/Firefox6/ReviewNotes/telemetry
        # https://gecko.readthedocs.io/en/latest/browser/experiments/experiments/manifest.html
        # https://wiki.mozilla.org/Telemetry/Experiments
        # https://support.mozilla.org/en-US/questions/1197144
        # https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/internals/preferences.html#id1
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.coverage.opt-out" = true;
        "toolkit.coverage.opt-out" = true;
        "toolkit.coverage.endpoint.base" = "";
        "experiments.supported" = false;
        "experiments.enabled" = false;
        "experiments.manifest.uri" = "";
        "browser.ping-centre.telemetry" = false;

        # https://mozilla.github.io/normandy/
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "app.shield.optoutstudies.enabled" = false;

        # Disable health reports (basically more telemetry)
        # https://support.mozilla.org/en-US/kb/firefox-health-report-understand-your-browser-perf
        # https://gecko.readthedocs.org/en/latest/toolkit/components/telemetry/telemetry/preferences.html
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.healthreport.service.enabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;

        # Disable crash reports
        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false; # don't submit backlogged reports

        # Disable Form autofill
        # https://wiki.mozilla.org/Firefox/Features/Form_Autofill
        "browser.formfill.enable" = false;
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.available" = "off";
        "extensions.formautofill.creditCards.available" = false;
        "extensions.formautofill.creditCards.enabled" = false;
        "extensions.formautofill.heuristics.enabled" = false;

        ##################
        # Other settings #
        ##################

        # Disable disk cache entirely
        "browser.cache.disk.enable" = false;

        # Never show bookmarks bar
        "browser.toolbars.bookmarks.visibility" = "never";

        # integrated calculator
        "browser.urlbar.suggest.calculator" = true;
        "browser.urlbar.unitConversion.enabled" = true;
        "browser.urlbar.trending.featureGate" = true;

        "browser.newtabpage.pinned" = [
          {
            title = "Miniflux";
            url = "http://localhost:4242";
          }
          {
            title = "OpenWebUI";
            url = "http://localhost:11435";
          }
        ];

        "browser.compactmode.show" = true;
        "signon.firefoxRegalay.feature" = "disabled";

        # "media.eme.enabled" = true;
        # "network.cookie.cookieBehavior" = 1;

        # DNS-over-HTTPS
        # "network.trr.mode" = 5;

        # "privacy.donottrackheader.enabled" = true;
        # "privacy.globalprivacycontrol.enabled" = true;
        # "privacy.globalprivacycontrol.was_ever_enabled" = true;

        "signon.autofillForms" = false;
        "signon.generation.enabled" = false;
        "signon.management.page.breach-alerts.enabled" = false;
        "signon.rememberSignons" = false; # Don't use the built-in password manager.

        "findbar.highlightAll" = true;

        # Remove 'Firefox View' tab
        "browser.tabs.firefox-view" = false;

        ####################
        # FastFox settings #
        ####################

        "nglayout.initialpaint.delay" = 5; # default: 250

        # PREF: new tab preload
        # [WARNING] Disabling this may cause a delay when opening a new tab in Firefox.
        # [1] https://wiki.mozilla.org/Tiles/Technical_Documentation#Ping
        # [2] https://github.com/arkenfox/user.js/issues/1556
        "browser.newtab.preload" = true;

        # PREF: lazy load iframes
        "dom.iframe_lazy_loading.enabled" = true; # DEFAULT [FF121+]

        # PREF: Webrender tweaks
        # [1] https://searchfox.org/mozilla-central/rev/6e6332bbd3dd6926acce3ce6d32664eab4f837e5/modules/libpref/init/StaticPrefList.yaml#6202-6219
        # [2] https://hacks.mozilla.org/2017/10/the-whole-web-at-maximum-fps-how-webrender-gets-rid-of-jank/
        # [3] https://www.reddit.com/r/firefox/comments/tbphok/is_setting_gfxwebrenderprecacheshaders_to_true/i0bxs2r/
        # [4] https://www.reddit.com/r/firefox/comments/z5auzi/comment/ixw65gb?context=3
        # [5] https://gist.github.com/RubenKelevra/fd66c2f856d703260ecdf0379c4f59db?permalink_comment_id=4532937#gistcomment-4532937
        "gfx.webrender.all" = true; # enables WR + additional features
        "gfx.webrender.precache-shaders" = true; # longer initial startup time
        "gfx.webrender.compositor.force-enabled" = true; # enforce

        # PREF: compression level for cached JavaScript bytecode [FF102+]
        # [1] https://github.com/yokoffing/Betterfox/issues/247
        # 0 = do not compress (default)
        # 1 = minimal compression
        # 9 = maximal compression
        "browser.cache.jsbc_compression_level" = 3;

        # Fully disable Pocket. See
        # https://www.reddit.com/r/linux/comments/zabm2a.
        "extensions.pocket.enabled" = false;
        "extensions.pocket.api" = "0.0.0.0";
        "extensions.pocket.loggedOutVariant" = "";
        "extensions.pocket.oAuthConsumerKey" = "";
        "extensions.pocket.onSaveRecs" = false;
        "extensions.pocket.onSaveRecs.locales" = "";
        "extensions.pocket.showHome" = false;
        "extensions.pocket.site" = "0.0.0.0";
        "browser.newtabpage.activity-stream.pocketCta" = "";
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstorie" = false;

        # Set to false if you use sync
        "services.sync.prefs.sync.browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "services.sync.prefs.sync-seen.services.sync.prefs.sync.browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "services.sync.prefs.sync.browser.newtabpage.activity-stream.feeds.section.topstories" = false;
      };
      extensions = with addons; [
        bitwarden
        vimium
        firefox-translations
        refined-github

        leechblock-ng
        ublock-origin
        sponsorblock
        istilldontcareaboutcookies

        privacy-badger
        clearurls
        libredirect
        old-reddit-redirect

        # TODO:
        # modern for hacker news
        # modern for twitter
        # modern for wikipedia
        # zotero
        # unhook.app
      ];
    };

    # https://github.com/hlissner/dotfiles/blob/master/modules/desktop/browsers/firefox.nix
    # https://github.com/yokoffing/Betterfox/wiki/Common-Overrides
    # https://github.com/yokoffing/Betterfox/blob/main/user.js
  };
}
