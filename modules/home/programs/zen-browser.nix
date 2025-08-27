/**
  ZEN BROWSER CONFIGURATION
*
* A comprehensive privacy and security configuration based on LibreWolf settings. This configuration includes similar categories and settings from LibreWolf's librewolf.cfg to provide enhanced privacy, security, and performance for Zen Browser.
*/
{
  flakes,
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
  imports = [flakes.zen-browser.homeModules.default];

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
      # ================================
      # [CATEGORY] PRIVACY
      # ================================
      # [SECTION] ISOLATION - Default to strict mode with enhanced partitioning
      isolationSettings = {
        # Content blocking strict mode
        "browser.contentblocking.category" = "strict";

        # Always Partition Storage (APS)
        "privacy.partition.always_partition_third_party_non_cookie_storage" = true;
        "privacy.partition.always_partition_third_party_non_cookie_storage.exempt_sessionstorage" = false;

        # CHIPS / third party cookie deprecation
        "network.cookie.cookieBehavior.optInPartitioning" = true;
        "network.cookie.CHIPS.enabled" = true;
      };

      # [SECTION] SANITIZING - Enhanced cleaning preferences for privacy
      sanitizingSettings = {
        # Don't sanitize on shutdown to preserve login sessions
        "privacy.sanitize.sanitizeOnShutdown" = false;
        "privacy.sanitize.timeSpan" = 0;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
        "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
        "privacy.clearOnShutdown_v2.cookies" = false;
        "privacy.clearOnShutdown_v2.cache" = false;
        "privacy.clearOnShutdown_v2.sessions" = false;
        "privacy.sanitize.clearOnShutdown.hasMigratedToNewPrefs3" = true;

        # Prevent media cache from being written to disk in private browsing
        "browser.privatebrowsing.forceMediaMemoryCache" = true;
        "media.memory_cache_max_size" = 65536;
      };

      # [SECTION] CACHE AND STORAGE
      cacheSettings = {
        "browser.cache.disk.enable" = false;
        "browser.cache.disk.capacity" = 0;

        "browser.cache.disk.smart_size.enabled" = false;

        "browser.cache.memory.enable" = true;
        "browser.cache.memory.capacity" = 524288; # 512MB RAM cache
        "browser.cache.memory.max_entry_size" = 32768; # 32MB max per entry
        "browser.shell.shortcutFavicons" = false; # Disable favicons in profile folder
        "browser.helperApps.deleteTempFileOnExit" = true;
      };

      # [SECTION] HISTORY AND SESSION RESTORE
      historySettings = {
        "privacy.history.custom" = true;
        "browser.privatebrowsing.autostart" = false;
        "browser.formfill.enable" = false; # Disable form history
        "browser.sessionstore.privacy_level" = 2; # Prevent session data storage
        "browser.sessionstore.interval" = 300000; # 5 minutes instead of 15 seconds
      };

      # [SECTION] PRIVACY SETTINGS - Query stripping and logging
      privacySettings = {
        # Query stripping
        "privacy.query_stripping.strip_list" = "__hsfp __hssc __hstc __s _hsenc _openstat dclid fbclid gbraid gclid hsCtaTracking igshid mc_eid ml_subscriber ml_subscriber_hash msclkid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id rb_clickid s_cid twclid vero_conv vero_id wbraid wickedid yclid";

        # Logging
        "browser.dom.window.dump.enabled" = false;
        "devtools.console.stdout.chrome" = false;
      };

      # ================================
      # [CATEGORY] NETWORKING
      # ================================

      # [SECTION] DNS OVER HTTPS (DoH)
      dohSettings = {
        "network.trr.mode" = 5; # DoH turned off by default
        "network.trr.uri" = "https://dns10.quad9.net/dns-query"; # Default DoH server
        "network.trr.strict_native_fallback" = false; # Allow native fallback
        "network.trr.retry_on_recoverable_errors" = true; # Retry on errors
        "network.trr.disable-heuristics" = true; # Disable canary detection
        "network.trr.default_provider_uri" = "https://doh.dns4all.eu/dns-query"; # Fallback DoH
        "network.trr.allow-rfc1918" = true; # Allow private IP addresses
      };

      # [SECTION] NETWORKING - HTTPS, WebRTC, Proxy, DNS, Prefetching
      networkingSettings = {
        # HTTPS and security
        "dom.security.https_only_mode" = true; # HTTPS-only mode
        "network.auth.subresource-http-auth-allow" = 1; # Block HTTP auth dialogs

        # WebRTC
        "media.peerconnection.ice.default_address_only" = true; # Single interface for ICE
        "media.peerconnection.ice.proxy_only_if_behind_proxy" = true; # Force WebRTC through proxy

        # Proxy settings
        "network.gio.supported-protocols" = ""; # Disable gio to prevent proxy bypass
        "network.file.disable_unc_paths" = true; # Disable UNC paths
        "network.proxy.socks_remote_dns" = true; # Force DNS through proxy

        # DNS and prefetching
        "network.dns.disablePrefetch" = true; # Disable DNS prefetching
        "network.predictor.enabled" = false;
        "network.prefetch-next" = false;
        "network.http.speculative-parallel-limit" = 0;
        "browser.places.speculativeConnect.enabled" = false;
        "browser.urlbar.speculativeConnect.enabled" = false;

        # Referers
        "network.http.referer.XOriginTrimmingPolicy" = 2; # Trim cross-origin referers
      };

      # ================================
      # [CATEGORY] FINGERPRINTING
      # ================================

      # [SECTION] FINGERPRINTING - RFP and WebGL settings
      fingerprintingSettings = {
        # Resist Fingerprinting (RFP)
        "privacy.resistFingerprinting" = true;
        "privacy.resistFingerprinting.block_mozAddonManager" = true; # Prevent RFP from breaking AMO
        "browser.display.use_system_colors" = false;
        "privacy.window.maxInnerWidth" = 1600;
        "privacy.window.maxInnerHeight" = 900;
        "privacy.resistFingerprinting.letterboxing" = false;
        "browser.toolbars.bookmarks.visibility" = "never"; # Hide bookmarks bar
        "privacy.globalprivacycontrol.enabled" = true; # Global Privacy Control
        "privacy.globalprivacycontrol.pbmode.enabled" = true;
        "privacy.globalprivacycontrol.functionality.enabled" = true;

        # Exceptions:
        "webgl.disabled" = false; # Enable WebGL for proper icon rendering
        "dom.webgpu.enabled" = true; # WebGPU can be used for fingerprinting but speeds up rendering
      };

      # ================================
      # [CATEGORY] UI AND PERFORMANCE
      # ================================

      # [SECTION] UI SETTINGS
      uiSettings = {
        # Disable updates (managed by Nix)
        "app.update.channel" = "default";
        "app.normandy.first_run" = false;

        # Don't check if browser is default
        "browser.shell.checkDefaultBrowser" = false;

        # Use blank new tab page
        "browser.newtabpage.enabled" = false;
        "browser.newtab.url" = "about:blank";

        # Fix URL navigation behavior - prevent new tabs when changing URLs
        "browser.link.open_newwindow" = 2; # Open links in new tab
        "browser.link.open_newwindow.restriction" = 0; # No restrictions

        # Hide bookmarks bar by default
        "browser.toolbars.bookmarks.visibility" = "never";

        # UI tweaks
        "browser.compactmode.show" = true;
        "findbar.highlightAll" = true;
        "browser.tabs.firefox-view" = false;
      };

      # [SECTION] ZEN BROWSER SPECIFIC
      zenSettings = {
        "zen.urlbar.onlyfloatingbar" = true;
        "zen.containers.enable_container_essentials" = true;
        "zen.widget.windows.acrylic" = false;
        "zen.sidebar.enabled" = true; # Keep sidebar but optimize
        "zen.workspaces.enabled" = false;
        "zen.themes.dynamic-loading" = false; # Disable dynamic theme loading
        "zen.updates.check-interval" = 86400000; # Check updates daily
        "zen.animation.enabled" = false; # Disable zen-specific animations
        "zen.sounds.enabled" = false; # Disable zen sound effects

        "zen.glance.enabled" = false;
        "zen.splitView.enable-tab-drop" = false;
        "zen.haptic-feedback.enabled" = false;
        "zen.swipe.is-fast-swipe" = false;
        "zen.theme.disable-lightweight" = false;
        "zen.theme.gradient" = false;
        "zen.theme.acrylic-elements" = false;

        "zen.theme.use-sysyem-colors" = true;
        "zen.watermark.enabled" = false;
      };

      # [SECTION] PERFORMANCE OPTIMIZATIONS
      performanceSettings = {
        "browser.preferences.defaultPerformanceSettings.enabled" = false;

        # Hardware acceleration
        "media.ffmpeg.vaapi.enabled" = true;
        "widget.dmabuf.force-enabled" = true;
        "gfx.webrender.all" = true;
        "layers.acceleration.force-enabled" = true;

        # Process management optimizations
        "dom.ipc.processCount" = 8;
        # "dom.ipc.keepProcessesAlive.web" = 4;
        # "dom.ipc.processCount.webIsolated" = 4; # Isolated web processes
        # "dom.ipc.processPrelaunch.enabled" = true; # Prelaunch processes
        # "browser.tabs.remote.autostart" = true; # Enable multiprocess
        # "dom.ipc.processHangMonitor" = true; # Monitor hanging processes

        # Graphics and rendering optimizations
        "gfx.canvas.accelerated" = true;
        "gfx.webrender.compositor" = true;
        "layers.mlgpu.enabled" = true;

        # Media decoding optimizations
        "media.hardware-video-decoding.enabled" = true;
        "media.rdd-process.enabled" = true;
        "image.mem.decode_bytes_at_a_time" = 32768; # Faster image decoding

        # Background activity and animations
        "browser.tabs.animate" = false;
        "browser.fullscreen.animate" = false;
        "toolkit.cosmeticAnimations.enabled" = false;
        "browser.download.animateNotifications" = false;

        # Accessibility (disable for performance)
        "accessibility.force_disabled" = 1;
        "accessibility.typeaheadfind.enabled" = false;

        # # Background processes and timers
        # "dom.timeout.enable_budget_timer_throttling" = false; # No timer throttling
        # "dom.timeout.throttling_delay" = -1; # Disable timeout throttling
        # "dom.serviceWorkers.enabled" = false; # Disable service workers
        # "dom.push.enabled" = false; # Disable push notifications

        # # Image and content loading
        # "image.animation_mode" = "none"; # Disable animated images
        # "browser.display.use_document_fonts" = 1; # Allow web fonts for icons
        # "gfx.downloadable_fonts.enabled" = true; # Enable web fonts for proper icon display

        # Smooth scroll
        "general.smoothScroll" = true;
        "general.smoothScroll.msdPhysics.enabled" = false;
        "general.smoothScroll.currentVelocityWeighting" = 0;
        # "apz.overscroll.enabled" = false;
        # "general.smoothScroll.stopDecelerationWeighting" = 1;
        # "general.smoothScroll.mouseWheel.durationMaxMS" = 150;
        # "general.smoothScroll.mouseWheel.durationMinMS" = 50;
        # "mousewheel.min_line_scroll_amount" = 18;
        # "mousewheel.scroll_series_timeout" = 10;

        # Wayland
        "widget.wayland.opaque-region.enabled" = true;
        "widget.wayland.fractional-scale.enabled" = true;

        # Misc:
        "layout.frame_rate" = 60;
        "widget.gtk.rounded-bottom-corners.enabled" = false;
      };

      # ================================
      # [CATEGORY] SECURITY
      # ================================

      # [SECTION] SECURITY - Permissions, safe browsing, and other security
      securitySettings = {
        # Permissions
        "permissions.manager.defaultsUrl" = ""; # Remove Mozilla special permissions
        "permissions.default.desktop-notification" = 2; # Block notifications
        "permissions.default.geo" = 2; # Block location requests

        # Safe browsing (disabled for privacy)
        "browser.safebrowsing.malware.enabled" = false;
        "browser.safebrowsing.phishing.enabled" = false;
        "browser.safebrowsing.blockedURIs.enabled" = false;
        "browser.safebrowsing.provider.google4.gethashURL" = "";
        "browser.safebrowsing.provider.google4.updateURL" = "";
        "browser.safebrowsing.provider.google.gethashURL" = "";
        "browser.safebrowsing.provider.google.updateURL" = "";

        # Disable download scanning
        "browser.safebrowsing.downloads.enabled" = false;
        "browser.safebrowsing.downloads.remote.enabled" = false;
        "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
        "browser.safebrowsing.downloads.remote.block_uncommon" = false;
        "browser.safebrowsing.downloads.remote.url" = "";
        "browser.safebrowsing.provider.google4.dataSharingURL" = "";
      };

      # ================================
      # [CATEGORY] REGION
      # ================================

      # [SECTION] REGION - Geolocation and language settings
      regionSettings = {
        # Geolocation - Use BeaconDB instead of Google
        "geo.provider.network.url" = "https://api.beacondb.net/v1/geolocate";
        "geo.provider.ms-windows-location" = false; # Windows
        "geo.provider.use_corelocation" = false; # macOS
        "geo.provider.use_gpsd" = false; # Linux
        "geo.provider.use_geoclue" = false; # Linux

        # Language and region updates
        "browser.region.network.url" = "";
        "browser.region.update.enabled" = false;
      };

      # ================================
      # [CATEGORY] BEHAVIOR
      # ================================

      # [SECTION] SEARCH AND URLBAR
      searchSettings = {
        "browser.urlbar.suggest.searches" = false;
        "browser.search.suggest.enabled" = false;
        "browser.search.update" = false;
        "browser.search.separatePrivateDefault" = true;
        "browser.search.separatePrivateDefault.ui.enabled" = true;
        "browser.search.serpEventTelemetryCategorization.enabled" = false;

        # MDN and other suggestions
        "browser.urlbar.suggest.mdn" = true;
        "browser.urlbar.addons.featureGate" = false;
        "browser.urlbar.mdn.featureGate" = false;
        "browser.urlbar.trending.featureGate" = false;
        "browser.urlbar.weather.featureGate" = false;

        # Firefox Suggest
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.suggest.weather" = false;
        "browser.urlbar.update2.engineAliasRefresh" = true;

        # URL Bar Privacy
        "browser.urlbar.trimHttps" = true;
        "browser.urlbar.untrimOnUserInteraction.featureGate" = true;
      };

      # [SECTION] DOWNLOADS AND AUTOPLAY
      downloadSettings = {
        "browser.download.useDownloadDir" = true;
        "browser.download.autohideButton" = false;
        "browser.download.manager.addToRecentDocs" = false;
        "browser.download.alwaysOpenPanel" = false;
        "browser.download.start_downloads_in_tmp_dir" = true;

        # Autoplay
        "media.autoplay.default" = 5; # Block autoplay unless right-clicked
      };

      # ================================
      # [CATEGORY] EXTENSIONS
      # ================================

      # [SECTION] USER INSTALLED EXTENSIONS
      extensionSettings = {
        "extensions.webextensions.restrictedDomains" = ""; # Allow extensions on all domains
        "extensions.enabledScopes" = 5; # Profile + application scope
        "extensions.postDownloadThirdPartyPrompt" = false;
        "extensions.quarantinedDomains.enabled" = false; # Disable quarantined domains
      };

      # [SECTION] SYSTEM EXTENSIONS
      systemExtensionSettings = {
        "extensions.systemAddon.update.enabled" = false; # No auto-updates for system addons
        "extensions.systemAddon.update.url" = "";
        "extensions.webcompat-reporter.enabled" = false;
        "extensions.webcompat-reporter.newIssueEndpoint" = "";
      };

      # ================================
      # [CATEGORY] BUILT-IN FEATURES
      # ================================

      # [SECTION] FIREFOX ACCOUNTS AND SYNC
      firefoxAccountsSettings = {
        "identity.fxaccounts.enabled" = false; # Disable Firefox Sync
        "identity.fxaccounts.toolbar.pxiToolbarEnabled" = false; # Hide Firefox Sync ads

        # App updates (managed by Nix)
        "app.update.auto" = false;
      };

      # [SECTION] BUILT-IN FEATURES - Password manager, containers, devtools
      builtInFeaturesSettings = {
        # Password manager and autofill (Lockwise)
        "signon.rememberSignons" = false; # Disable password manager
        "signon.autofillForms" = false; # Disable autofill
        "extensions.formautofill.addresses.enabled" = false; # Disable address autofill
        "extensions.formautofill.creditCards.enabled" = false; # Disable credit card autofill
        "signon.formlessCapture.enabled" = false; # Disable formless capture
        "signon.privateBrowsingCapture.enabled" = false;
        "editor.truncate_user_pastes" = false;

        # Container tabs
        "privacy.userContext.enabled" = true; # Enable container tabs
        "privacy.userContext.ui.enabled" = true; # Show container UI

        # Developer tools
        "devtools.debugger.remote-enabled" = false; # Disable remote debugging
        "devtools.selfxss.count" = 0; # Allow console usage
      };

      # ================================
      # [CATEGORY] UI
      # ================================

      # [SECTION] FIRST LAUNCH
      firstLaunchSettings = {
        "browser.startup.homepage_override.mstone" = "ignore";
        "startup.homepage_override_url" = "about:blank";
        "startup.homepage_welcome_url" = "about:blank";
        "startup.homepage_welcome_url.additional" = "";
        "startup.homepage_override_nimbus_disable_wnp" = true;
        "browser.uitour.enabled" = false;
        "browser.uitour.url" = "";
        "browser.shell.checkDefaultBrowser" = false;
      };

      # [SECTION] NEW TAB PAGE
      newTabSettings = {
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories.options" = "{\"hidden\":true}";
        "browser.newtabpage.activity-stream.default.sites" = "";
        "browser.newtabpage.activity-stream.feeds.weatherfeed" = false;
        "browser.newtabpage.activity-stream.showWeather" = false;
      };

      # [SECTION] ABOUT PAGES
      aboutSettings = {
        "browser.contentblocking.report.lockwise.enabled" = false;
        "browser.contentblocking.report.hide_vpn_banner" = true;
        "browser.contentblocking.report.vpn.enabled" = false;
        "browser.contentblocking.report.show_mobile_app" = false;
        "browser.vpn_promo.enabled" = false;
        "browser.promo.focus.enabled" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "extensions.getAddons.showPane" = false;
        "lightweightThemes.getMoreURL" = "";
        "browser.topsites.useRemoteSetting" = false;
        "browser.aboutConfig.showWarning" = false;
        "browser.preferences.moreFromMozilla" = false;
      };

      # [SECTION] RECOMMENDED FEATURES
      recommendedSettings = {
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
      };

      # [SECTION] OTHER UI AND MACHINE LEARNING
      otherUiSettings = {
        "sidebar.main.tools" = "history"; # Default sidebar layout

        # Machine Learning
        "browser.ml.enable" = false;
        "browser.ml.chat.enabled" = false;
      };

      # ================================
      # [CATEGORY] TELEMETRY
      # ================================

      # [SECTION] COMPREHENSIVE TELEMETRY - Core, studies, crash reports, connectivity
      telemetrySettings = {
        # Core telemetry
        "toolkit.telemetry.unified" = false; # Master switch
        "toolkit.telemetry.enabled" = false; # Master switch
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.cachedClientID" = "";
        "toolkit.telemetry.previousBuildID" = "";
        "toolkit.telemetry.server_owner" = "";
        "toolkit.coverage.opt-out" = true;
        "toolkit.telemetry.coverage.opt-out" = true;
        "toolkit.coverage.enabled" = false;
        "toolkit.coverage.endpoint.base" = "";
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.usage.uploadEnabled" = false;

        # Studies and Normandy
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "app.shield.optoutstudies.enabled" = false;
        "browser.discovery.enabled" = false; # Disable personalized extension recommendations

        # Crash reports
        "browser.tabs.crashReporting.sendReport" = false;
        "breakpad.reportURL" = "";

        # Connectivity and attribution
        "network.connectivity-service.enabled" = false;
        "network.captive-portal-service.enabled" = false;
        "captivedetect.canonicalURL" = "";
        "dom.private-attribution.submission.enabled" = false; # Privacy-Preserving Attribution
      };

      # Combine all settings into one object
      commonSettings =
        # PRIVACY CATEGORY
        isolationSettings
        // sanitizingSettings
        // cacheSettings
        // historySettings
        // privacySettings # Merged: queryStrippingSettings + loggingSettings
        # NETWORKING CATEGORY
        # // dohSettings
        # // networkingSettings # Merged: httpsSettings + webrtcSettings + proxySettings + prefetchingSettings + dnsSettings + refererSettings
        # FINGERPRINTING CATEGORY
        // fingerprintingSettings # Merged: rfpSettings + webglSettings
        # SECURITY CATEGORY
        // securitySettings # Merged: permissionsSettings + safeBrowsingSettings + otherSecuritySettings
        # REGION CATEGORY
        // regionSettings # Merged: locationSettings + languageSettings
        # BEHAVIOR CATEGORY
        // searchSettings
        // downloadSettings # Merged: downloadSettings + autoplaySettings
        # EXTENSIONS CATEGORY
        // extensionSettings
        // systemExtensionSettings
        # BUILT-IN FEATURES CATEGORY
        // firefoxAccountsSettings # Merged: syncSettings + updaterSettings + identity.fxaccounts.*
        // builtInFeaturesSettings # Merged: lockwiseSettings + containerSettings + devtoolsSettings
        # UI CATEGORY
        // firstLaunchSettings
        // newTabSettings
        // aboutSettings
        // recommendedSettings
        // otherUiSettings # Merged: otherUiSettings + mlSettings
        # TELEMETRY CATEGORY
        // telemetrySettings # Merged: telemetrySettings + studiesSettings + crashSettings + connectivitySettings
        # WINDOWS CATEGORY
        # UI AND PERFORMANCE CATEGORY
        // uiSettings
        // zenSettings
        // performanceSettings;

      commonExtensions = with addons; [
        bitwarden
        ublock-origin
        vimium
        firefox-translations
        refined-github
        leechblock-ng
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
        extensions.packages = commonExtensions;
      };

      work = {
        id = 1;
        name = "work";
        isDefault = false;

        userChrome = disableWebRtcIndicator;
        extraConfig = "";

        search = commonSearch;
        settings = commonSettings;
        extensions.packages = commonExtensions;
      };
    };
  };

  xdg = {
    enable = true;
    mimeApps = let
      associations = builtins.listToAttrs (map (name: {
          inherit name;
          value = "zen-beta.desktop";
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
