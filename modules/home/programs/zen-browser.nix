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
      commonSettings = {
        ######################
        # Basic UI Settings  #
        ######################

        # Disable updates (managed by Nix)
        "app.update.channel" = "default";
        "app.normandy.first_run" = false;

        # Disable translations popup
        "browser.translations.automaticallyPopup" = false;

        # Don't check if browser is default
        "browser.shell.checkDefaultBrowser" = false;

        ########################
        # New Tab Page Settings #
        ########################

        # Use blank new tab page
        "browser.newtabpage.enabled" = false;
        "browser.newtab.url" = "about:blank";

        # Disable Activity Stream
        "browser.newtabpage.activity-stream.enabled" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.newtabpage.activity-stream.showSearch" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        # Disable new tab tile ads
        "browser.newtabpage.enhanced" = false;
        "browser.newtabpage.introShown" = true;
        "browser.newtabpage.directory.ping" = "";
        "browser.newtabpage.directory.source" = "data:text/plain,{}";

        ###################
        # URL Bar Settings #
        ###################

        # Reduce URL bar clutter
        "browser.urlbar.shortcuts.bookmarks" = false;
        "browser.urlbar.shortcuts.history" = false;
        "browser.urlbar.shortcuts.tabs" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.urlbar.speculativeConnect.enabled" = false;

        # Disable quick actions
        "browser.urlbar.quickactions.enabled" = false;
        "browser.urlbar.quickactions.showPrefs" = false;
        "browser.urlbar.shortcuts.quickactions" = false;
        "browser.urlbar.suggest.quickactions" = false;
        "browser.urlbar.suggest.trending" = false;
        "browser.search.suggest.enabled" = false;

        # URL bar suggestions
        "browser.urlbar.suggest.history" = true;
        "browser.urlbar.suggest.bookmark" = false;
        "browser.urlbar.suggest.clipboard" = false;
        "browser.urlbar.suggest.openpage" = false;
        "browser.urlbar.suggest.engines" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.weather" = false;
        "browser.urlbar.suggest.topsites" = false;
        "browser.urlbar.suggest.quicksuggest" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;

        ######################
        # Disable Annoyances #
        ######################

        "browser.disableResetPrompt" = true;
        "browser.onboarding.enabled" = false;
        "browser.aboutConfig.showWarning" = false;
        "extensions.unifiedExtensions.enabled" = false;
        "extensions.shield-recipe-client.enabled" = false;
        "reader.parse-on-load.enabled" = false;

        # URL bar behavior
        "browser.urlbar.trimURLs" = false;
        "browser.urlbar.openintab" = true;

        #################
        # Tab Settings  #
        #################

        "browser.ctrlTab.recentlyUsedOrder" = false;
        "browser.tabs.allow_transparent_browser" = true;
        "browser.tabs.newtabbutton" = false;
        "browser.tabs.hoverPreview.enabled" = true;
        "browser.sessionstore.restore_pinned_tabs_on_demand" = true;

        ####################
        # Security Settings #
        ####################

        "security.pki.sha1_enforcement_level" = 1;

        # Extension recommendations
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "extensions.htmlaboutaddons.discover.enabled" = false;
        "extensions.getAddons.showPane" = false;
        "browser.discovery.enabled" = false;

        # Reduce SSD writes (30 minutes instead of 15 seconds)
        "browser.sessionstore.interval" = "1800000";

        # Don't guess domain names for invalid URLs
        "browser.fixup.alternate.enabled" = false;

        ##################
        # Other Settings #
        ##################

        # Disable disk cache
        "browser.cache.disk.enable" = false;

        # Never show bookmarks bar
        "browser.toolbars.bookmarks.visibility" = "never";

        # URL bar features
        "browser.urlbar.suggest.calculator" = true;
        "browser.urlbar.unitConversion.enabled" = true;
        "browser.urlbar.trending.featureGate" = true;

        # UI tweaks
        "browser.compactmode.show" = true;
        "signon.firefoxRegalay.feature" = "disabled";
        "findbar.highlightAll" = true;
        "browser.tabs.firefox-view" = false;

        ##########################
        # Performance Settings   #
        ##########################

        # Faster initial paint
        "nglayout.initialpaint.delay" = 5;

        # New tab and loading optimizations
        "browser.newtab.preload" = true;
        "dom.iframe_lazy_loading.enabled" = true;

        # WebRender optimizations
        "gfx.webrender.all" = true;
        "gfx.webrender.precache-shaders" = true;
        "gfx.webrender.compositor.force-enabled" = true;

        # JavaScript compression
        "browser.cache.jsbc_compression_level" = 3;

        # Disable Pocket completely
        "extensions.pocket.enabled" = false;
        "browser.payments.enable" = false;
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
        "services.sync.prefs.sync.browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "services.sync.prefs.sync-seen.services.sync.prefs.sync.browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "services.sync.prefs.sync.browser.newtabpage.activity-stream.feeds.section.topstories" = false;

        # Media and hardware acceleration
        "media.ffmpeg.vaapi.enabled" = true;
        "widget.dmabuf.force-enabled" = true;

        ###################
        # Zen-specific    #
        ###################

        "zen.urlbar.onlyfloatingbar" = true;
        "zen.containers.enable_container_essentials" = true;
        "zen.widget.windows.acrylic" = false;

        # Network optimizations
        "network.http.max-connections" = 1800;
        "network.http.max-persistent-connections-per-server" = 10;
        "network.http.max-urgent-start-excessive-connections-per-host" = 5;
        "network.http.pacing.requests.enabled" = false;
        "network.dnsCacheExpiration" = 3600;
        "network.predictor.enabled" = true;
        "network.http.speculative-parallel-limit" = 0;
        "network.dns.disablePrefetch" = false;
        "network.dns.disablePrefetchFromHTTPS" = false;
        "network.prefetch-next" = true;
        "network.preload" = true;

        # Process and memory management
        "dom.ipc.processCount" = 8;
        "dom.ipc.processHangMonitor" = false;
        "dom.ipc.reportProcessHangs" = false;
        "javascript.options.mem.high_water_mark" = 512;
        "javascript.options.mem.max" = -1;
        "javascript.options.mem.gc_per_zone" = true;
        "javascript.options.mem.gc_incremental_slice_ms" = 20;
        "javascript.options.mem.gc_compacting" = true;
        "javascript.options.mem.gc_parallel_marking" = true;
        "browser.low_commit_space_threshold_mb" = 200;
        "browser.tabs.unloadOnLowMemory" = true;
        "config.trim_on_minimize" = true;

        # Graphics and GPU acceleration
        "gfx.webrender.enabled" = true;
        "gfx.canvas.accelerated" = true;
        "layers.gpu-process.enabled" = true;
        "layers.gpu-process.force-enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;

        # Startup and loading optimizations
        "browser.startup.preXulSkeletonUI" = false;
        "browser.startup.blankWindow" = false;
        "browser.startup.upgradeDialog.enabled" = false;
        "browser.tabs.remote.warmup.enabled" = true;
        "browser.tabs.remote.warmup.maxTabs" = 3;
        "browser.tabs.remote.warmup.unloadDelayMs" = 2000;
        "dom.image-lazy-loading.enabled" = true;
        "browser.sessionstore.restore_on_demand" = true;
        "dom.ipc.processPrelaunch.enabled" = true;
        "dom.ipc.processPrelaunch.fission.number" = 3;

        # JavaScript and threading optimizations
        "javascript.options.baselinejit" = true;
        "javascript.options.ion" = true;
        "javascript.options.asmjs" = true;
        "javascript.options.wasm" = true;
        "javascript.options.wasm_trustedprincipals" = true;
        "javascript.options.wasm_verbose" = false;
        "dom.workers.maxPerDomain" = 8;
        "dom.serviceWorkers.enabled" = true;
        "javascript.options.shared_memory" = true;
        "security.sandbox.content.level" = 4;
        "dom.postMessage.sharedArrayBuffer.withCOOP_COEP" = true;

        # Smooth scrolling
        "general.smoothScroll.msdPhysics.enabled" = true;
        "general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS" = 12;
        "general.smoothScroll.msdPhysics.motionBeginSpringConstant" = 600;
        "general.smoothScroll.msdPhysics.slowdownMinDeltaMS" = 25;
        "general.smoothScroll.msdPhysics.slowdownMinDeltaRatio" = "2.0";
        "general.smoothScroll.msdPhysics.slowdownSpringConstant" = 250;
        "general.smoothScroll.currentVelocityWeighting" = "1.0";
        "general.smoothScroll.stopDecelerationWeighting" = "1.0";

        # Content and layout optimizations
        "content.notify.interval" = 100000;
        "content.notify.ontimer" = true;
        "content.switch.threshold" = 1500000;
        "browser.quitShortcut.disabled" = true;
        "layout.frame_rate" = 144;

        # Additional optimizations
        "layers.acceleration.force-enabled" = true;
        "network.http.pipelining" = true;
        "network.http.proxy.pipelining" = true;
        "network.http.proxy.pipelining.ssl" = true;
        "network.http.pipelining.maxrequests" = 25;
        "browser.cache.disk.parent_directory" = "/dev/shm/ffcache";
        "network.dns.disableIPv6" = true;

        # Advanced network optimizations
        "network.dns.cacheEntries" = 20000;
        "network.dns.cacheExpiration" = 3600;
        "network.dns.cacheExpirationGracePeriod" = 240;
        "network.predictor.enable-prefetch" = true;
        "network.predictor.preconnect-min-confidence" = 20;
        "network.predictor.prefetch-force-valid-for" = 3600;
        "network.predictor.prefetch-min-confidence" = 30;
        "network.predictor.prefetch-rolling-load-count" = 120;
        "network.predictor.preresolve-min-confidence" = 10;
        "network.ssl_tokens_cache_capacity" = 32768;

        # Cache optimizations
        "browser.cache.disk.capacity" = 8192000;
        "browser.cache.disk.smart_size.enabled" = false;
        "browser.cache.disk.metadata_memory_limit" = 15360;
        "browser.cache.frecency_half_life_hours" = 18;
        "browser.cache.max_shutdown_io_lag" = 16;
        "browser.cache.memory.capacity" = 2097152;
        "browser.cache.memory.max_entry_size" = 327680;

        # Advanced graphics optimizations
        "gfx.canvas.accelerated.cache-items" = 32768;
        "gfx.canvas.accelerated.cache-size" = 4096;
        "gfx.content.skia-font-cache-size" = 80;
        "layers.gpu-process.startup_timeout_ms" = 8000;
        "layers.gpu-process.max_restarts" = 1;
        "gfx.webrender.software.opengl" = true;
        "gfx.webrender.program-binary-disk" = true;
        "gfx.webrender.batched-upload-threshold" = 512;

        # Media and image optimizations
        "media.cache_readahead_limit" = 9900;
        "media.cache_resume_threshold" = 9900;
        "media.memory_cache_max_size" = 1048576;
        "media.memory_caches_combined_limit_kb" = 2560000;
        "media.memory_caches_combined_limit_pc_sysmem" = 20;
        "image.cache.size" = 10485760;
        "image.cache.timeweight" = 500;
        "image.decode-immediately.enabled" = true;
        "image.mem.decode_bytes_at_a_time" = 131072;

        # DOM optimizations
        "dom.enable_web_task_scheduler" = true;
        "dom.script_loader.bytecode_cache.enabled" = true;
        "dom.script_loader.bytecode_cache.strategy" = 0;

        # Content process optimization
        "dom.ipc.processCount.webIsolated" = 4;
        "dom.ipc.processCount.privilegedabout" = 1;
        "dom.ipc.processCount.privilegedmozilla" = 1;
        "dom.ipc.processCount.extension" = 1;
        "dom.ipc.processCount.file" = 1;

        # Security and layout optimizations
        "security.sandbox.content.read_path_whitelist" = "";
        "security.sandbox.logging.enabled" = false;
        "layout.css.grid-template-subgrid-value.enabled" = true;
        "layout.css.has-selector.enabled" = true;
        "layout.css.animation-composition.enabled" = true;

        # Additional optimizations
        "browser.places.speculativeConnect.enabled" = false;
        "layout.css.grid-template-masonry-value.enabled" = true;

        ###################
        # UI Improvements #
        ###################

        # Remove Mozilla promotions
        "browser.privatebrowsing.vpnpromourl" = "";
        "browser.preferences.moreFromMozilla" = false;
        "browser.aboutwelcome.enabled" = false;
        "browser.profiles.enabled" = true;

        # Theme and customization
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layout.css.prefers-color-scheme.content-override" = 2;
        "browser.privateWindowSeparation.enabled" = false;

        # Behavior tweaks
        "browser.newtabpage.activity-stream.default.sites" = "";
        "browser.download.manager.addToRecentDocs" = false;
        "browser.download.open_pdf_attachments_inline" = true;
        "browser.bookmarks.openInTabClosesMenu" = false;
        "browser.menu.showViewImageInfo" = true;

        # Final optimizations
        "network.http.http2.enabled" = true;
        "network.http.http2.max-concurrent-streams" = 200;
        "network.http.altsvc.enabled" = true;
        "media.dormant-on-pause-timeout-ms" = 5000;
        "media.suspend-bkgnd-video.enabled" = false;
        "browser.sessionhistory.max_total_viewers" = 4;
      };

      privacySettings = {
        # Privacy and tracking protection
        "privacy.donottrackheader.enabled" = true;
        "privacy.donottrackheader.value" = 1;
        "privacy.purge_trackers.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.webrtc.legacyGlobalIndicator" = false;

        # Enhanced Tracking Protection
        "browser.contentblocking.category" = "strict";

        # Disable telemetry and data collection
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

        # Disable health reports and data submission
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.healthreport.service.enabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.policy.dataSubmissionEnable" = false;

        # Disable crash reports
        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

        # Disable normandy and studies
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "app.shield.optoutstudies.enabled" = false;

        # Disable Form autofill for privacy
        "browser.formfill.enable" = false;
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.available" = "off";
        "extensions.formautofill.creditCards.available" = false;
        "extensions.formautofill.creditCards.enabled" = false;
        "extensions.formautofill.heuristics.enabled" = false;

        # Disable password manager for privacy
        "signon.autofillForms" = false;
        "signon.generation.enabled" = false;
        "signon.management.page.breach-alerts.enabled" = false;
        "signon.rememberSignons" = false;

        # Disable battery API for privacy
        "dom.battery.enabled" = false;

        # Disable beacon for privacy (used for analytics)
        "beacon.enabled" = false;

        # Disable pinging URIs for privacy
        "browser.send_pings" = false;

        # Disable gamepad API to prevent USB device enumeration
        "dom.gamepad.enabled" = false;

        # Use Mozilla geolocation service instead of Google
        "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
        "geo.provider.use_gpsd" = false;

        # Disable captive portal and connectivity checks
        "network.captiveportal.enabled" = false;
        "network.connectivity-service.enabled" = false;

        # Disable SSL error reporting
        "network.ssl.errorReporting.enabled" = false;

        # Disable security family safety mode
        "security.family_safety.mode" = 0;
      };

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
          // privacySettings
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
        settings = commonSettings // privacySettings;
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
            zen-browser = flakes.zen-browser.packages.${pkgs.system}.twilight;
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
