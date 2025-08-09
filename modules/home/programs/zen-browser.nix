{
  flakes,
  addons,
  pkgs,
  ...
}: let
  # disable the annoying floating icon with camera and mic when on a call
  disableWebRtcIndicator = ''
    #webrtcIndicator {
      display: none;
    }
  '';
in {
  imports = [flakes.zen-browser.homeModules.beta];

  programs.zen-browser = {
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
      DisableFeedbackCommands = true;
      PasswordManagerEnabled = false;
      CaptivePortal = false;
      NetworkPrediction = false;
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        SkipOnboarding = false;
        MoreFromMozilla = false;
      };
      FirefoxHome = {
        Search = false;
        TopSites = false;
        Highlights = false;
        Pocket = false;
        Snippets = false;
        SponsoredPocket = false;
        SponsoredTopSites = false;
      };
      Homepage = {
        StartPage = "none";
      };
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
    };

    profiles = let
      # UI, interface, and media settings
      uiSettings = {
        # Disable updates (managed by Nix)
        "app.update.channel" = "default";
        "app.normandy.first_run" = false;

        # Don't check if browser is default
        "browser.shell.checkDefaultBrowser" = false;

        # Use blank new tab page
        "browser.newtabpage.enabled" = false;
        "browser.newtab.url" = "about:blank";

        # Never show bookmarks bar
        "browser.toolbars.bookmarks.visibility" = "never";

        # UI tweaks
        "browser.compactmode.show" = true;
        "findbar.highlightAll" = true;
        "browser.tabs.firefox-view" = false;

        # Theme and customization
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layout.css.prefers-color-scheme.content-override" = 2;
        "browser.privateWindowSeparation.enabled" = false;

        # Zen Browser specific settings
        "zen.urlbar.onlyfloatingbar" = true;
        "zen.containers.enable_container_essentials" = true;
        "zen.widget.windows.acrylic" = false;

        # Hardware acceleration (safe settings only)
        "media.ffmpeg.vaapi.enabled" = true;
        "widget.dmabuf.force-enabled" = true;
      };

      # Privacy and search settings
      privacySettings = {
        # Enhanced Tracking Protection (Strict)
        "browser.contentblocking.category" = "strict";

        # Global Privacy Control
        "privacy.globalprivacycontrol.enabled" = true;

        # History and session management
        "privacy.history.custom" = true;
        "browser.privatebrowsing.resetPBM.enabled" = true;
        "browser.privatebrowsing.forceMediaMemoryCache" = true;
        "browser.sessionstore.interval" = 60000; # 1 minute instead of 15 seconds

        # Container Tabs
        "privacy.userContext.ui.enabled" = true;

        # File and temp management
        "browser.download.start_downloads_in_tmp_dir" = true;
        "browser.helperApps.deleteTempFileOnExit" = true;

        # URL Bar Privacy
        "browser.urlbar.trimHttps" = true;
        "browser.urlbar.untrimOnUserInteraction.featureGate" = true;

        # Disable live search suggestions
        "browser.search.suggest.enabled" = false;

        # Disable Firefox Suggest
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.groupLabels.enabled" = false;

        # Disable search and form history
        "browser.formfill.enable" = false;

        # Disable search engine updates
        "browser.search.update" = false;

        # Separate search engine for Private Windows
        "browser.search.separatePrivateDefault.ui.enabled" = true;

        # Enforce Punycode for IDN spoofing protection
        "network.IDN_show_punycode" = true;
      };

      # Security, authentication, and safe browsing
      securitySettings = {
        # OCSP - disable fetching to confirm validity of certificates
        "security.OCSP.enabled" = 0;

        # CRLite for better certificate validation
        "security.pki.crlite_mode" = 2;

        # SSL/TLS Security
        "security.ssl.treat_unsafe_negotiation_as_broken" = true;
        "browser.xul.error_pages.expert_bad_cert" = true;
        "security.tls.enable_0rtt_data" = false;

        # Mixed content protection
        "security.mixed_content.block_display_content" = true;

        # PDF security
        "pdfjs.enableScripting" = false;

        # Extension security
        "extensions.enabledScopes" = 5;

        # Password manager security
        "signon.formlessCapture.enabled" = false;
        "signon.privateBrowsingCapture.enabled" = false;
        "network.auth.subresource-http-auth-allow" = 1;
        "editor.truncate_user_pastes" = false;

        # Safe Browsing - disable remote checks but keep local protection
        "browser.safebrowsing.downloads.remote.enabled" = false;
      };

      # Network and permissions
      networkSettings = {
        # Trim cross-origin referrers
        "network.http.referer.XOriginTrimmingPolicy" = 2;

        # Alternative geolocation service (BeaconDB instead of Google)
        "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";

        # Block notifications and location by default
        "permissions.default.desktop-notification" = 2;
        "permissions.default.geo" = 2;

        # Remove Mozilla domain special permissions
        "permissions.manager.defaultsUrl" = "";
      };

      # Mozilla telemetry and features
      mozillaSettings = {
        # Core telemetry disabling
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.coverage.opt-out" = true;
        "toolkit.coverage.opt-out" = true;
        "toolkit.coverage.endpoint.base" = "";
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "datareporting.usage.uploadEnabled" = false;

        # Disable Studies and Normandy
        "app.shield.optoutstudies.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";

        # Disable crash reports
        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;

        # Disable UITour backend
        "browser.uitour.enabled" = false;

        # Disable Mozilla promotions
        "browser.privatebrowsing.vpnpromourl" = "";
        "browser.preferences.moreFromMozilla" = false;
        "browser.aboutwelcome.enabled" = false;

        # Disable addon metadata caching
        "extensions.getAddons.cache.enabled" = false;

        # Disable Pocket
        "extensions.pocket.enabled" = false;
      };

      # Combine all settings into one object
      commonSettings =
        uiSettings
        // privacySettings
        // securitySettings
        // networkSettings
        // mozillaSettings;

      commonExtensions = with addons; [
        bitwarden
        vimium
        firefox-translations
        refined-github

        leechblock-ng
        ublock-origin
        sponsorblock
        istilldontcareaboutcookies

        libredirect
      ];

      commonSearch = {
        default = "brave";
        force = true;
        privateDefault = "ddg";
        engines = {
          "nix options" = {
            urls = [{template = "https://search.nixos.org/options?type=options&query={searchTerms}";}];
            icon = "https://nixos.org/favicon.ico";
            definedAliases = ["@no"];
          };

          "nix packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "https://nixos.org/favicon.ico";
            definedAliases = ["@np"];
          };

          "nixos wiki" = {
            urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
            icon = "https://nixos.wiki/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = ["@nw"];
          };

          "github" = {
            urls = [{template = "https://github.com/search?q={searchTerms}&type=repositories";}];
            icon = "https://github.com/favicon.ico";
            definedAliases = ["@gh"];
          };

          "home manager" = {
            urls = [{template = "https://home-manager-options.extranix.com/?query={searchTerms}&release=master";}];
            icon = "https://nixos.org/favicon.ico";
            definedAliases = ["@hm"];
          };

          "brave" = {
            urls = [{template = "https://search.brave.com/search?q={searchTerms}";}];
            icon = "https://brave.com/favicon.ico";
            definedAliases = ["@brave"];
          };

          "amazon".metaData.hidden = true;
          "bing".metaData.hidden = true;
          "ebay".metaData.hidden = true;
          "wikipedia".metaData.hidden = true;
          "ecosia".metaData.hidden = true;
        };
      };
    in {
      personal = {
        id = 0;
        name = "personal";
        isDefault = true;

        userChrome = disableWebRtcIndicator;
        extraConfig = "";

        search = commonSearch;
        settings =
          commonSettings
          // {
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
          };
        extensions = commonExtensions;
      };

      work = {
        id = 1;
        name = "work";
        isDefault = false;

        userChrome = disableWebRtcIndicator;
        extraConfig = "";

        search = commonSearch;
        settings = commonSettings;
        extensions = commonExtensions;
      };
    };
  };

  xdg = {
    enable = true;
    mimeApps = let
      associations = builtins.listToAttrs (map (name: {
          inherit name;
          value = let
            zen-browser = flakes.zen-browser.packages.${pkgs.system}.beta;
          in
            zen-browser.meta.desktopFile;
        }) [
          "x-scheme-handler/https"
          "x-scheme-handler/http"
          "text/html"
          "application/xhtml+xml"
          "application/x-extension-html"
          "application/x-extension-htm"
          "application/x-extension-shtml"
          "application/x-extension-xhtml"
          "application/x-extension-xht"
          "application/json"
          "text/plain"
          "x-scheme-handler/about"
          "x-scheme-handler/unknown"
          "x-scheme-handler/mailto"
        ]);
    in {
      associations.added = associations;
      defaultApplications = associations;
    };
  };
}
