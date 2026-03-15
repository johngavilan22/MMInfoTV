var config = {
        address: "localhost", // Address to listen on, can be:
                              // - "localhost", "127.0.0.1", "::1" to listen on loopback interface
                              // - another specific IPv4/6 to listen on a specific interface
                              // - "", "0.0.0.0", "::" to listen on any interface
                              // Default, when address config is left out, is "localhost"
        port: 8080,
        ipWhitelist: ["127.0.0.1", "::ffff:127.0.0.1", "::1"], // Set [] to allow all IP addresses
                                                               // or add a specific IPv4 of 192.168.1.5 :
                                                               // ["127.0.0.1", "::ffff:127.0.0.1", "::1", "::ffff:192.168.1.5"],
                                                               // or IPv4 range of 192.168.3.0 --> 192.168.3.15 use CIDR format :
                                                               // ["127.0.0.1", "::ffff:127.0.0.1", "::1", "::ffff:192.168.3.0/28"],

        language: "en",
        timeFormat: 24,
        units: "metric",
  modules: [
/*
  // Base WallberryTheme adds new font, styles, and a rotating background image pulled from Unsplash.com
  {
    module: "WallberryTheme",
    position: "fullscreen_below", // Required Position
    config: {
      unsplashAccessKey: "d86b9ee0f18771a2ec612079395b3b24087f668bac0bfc6a0c97e8e09d596e36", // REQUIRED
      collections: "2589108", // optional - leave empty for a random photo
      orientation: "portrait",
      autoDimOn: true,
      brightImageOpacity: .5
    }
  },
*/

  {
    module: "MMM-RTSPStream",
    position: "fullscreen_below",
    config: {
        autoStart: true,
        rotateStreams:false,
        rotateStreamTimeout: 10,
        moduleWidth: 0,
        moduleHeight: 0,
        localPlayer: 'omxplayer', //omxplayer or vlc
        remotePlayer: 'none',
        showSnapWhenPaused: false,
        remoteSnaps: false,
        muted: true,
        omxRestart: 12,
        shutdownDelay: 12,
            stream1: {
            name: 'zmodo',
            url: 'rtsp://192.168.1.168:554/main',
            frameRate: 'undefined',
            width: 'undefined',
            height: 'undefined',
            absPosition: {top:1260,left:0,right:1080,bottom:1920}
            },
        }
  },
  {
    module: "MMM-Wallpaper",
    position: "fullscreen_below",
    config: { // See "Configuration options" for more information.
      source: "__WALLPAPER_SOURCE__",
      fadeEdges: true,
      maximumEntries: 50,
      fillRegion: false,
      slideInterval: 60 * 1000, // Change slides every minute
      updateInterval: 60 * 1000 //update every minute
    }
  },
  {
      module: 'MMM-auto-refresh',
      config: {
	refreshInterval:  3600000 // one hour
      }
  },

  // WB-clock adds local time (Optional Module)
  {
    module: "WallberryTheme/WB-clock",
    position: "top_left", // highly suggest using top_bar position
    config: {
      localCityName: "", // optional
      otherCities: [],
      timeFormat: 12
    }
  },

  {
                module: "newsfeed",
                position: "lower_third",        // This can be any of the regions. Best results in center regions.
                config: {
			reloadInterval: 600000,
                        feeds: [
				{
					url: "https://www.newsmax.com/rss/US/18",
				},
				{
					url: "https://www.dailywire.com/rss.xml",
				},
				{
					url: "https://babylonbee.com/feed",
				}

                        ]
                }
  },

 {
    module: "weather",
    position: "top_right",
    config: {
      // See 'Configuration options' for more information.
      weatherProvider: "openweathermap",
      apiKey:  "__OWM_API_KEY__",
      type: "current",
      location: "Huntley, US",
      units: "imperial",
      tempUnits: "imperial"
    },
  },

 {
    module: "weather",
    position: "top_right",
    config: {
      // See 'Configuration options' for more information.
      weatherProvider: "openweathermap",
      apiKey:  "__OWM_API_KEY__",
      type: "forecast",
      location: "Chicago, US",
      units: "imperial",
      tempUnits: "imperial",
      ignoreTtoday: true,
      maxEntries: 10,
      tableClass: "medium",
      weatherEndpoint: "/forecast",
      fade: false,
      colored: true,
      maxNumberOfDays: 10
    },
  },

 ,{
	module: "calendar",
	position: "top_left",	// This can be any of the regions. Best results in left or right regions.
	config: {
	colored: true,
	coloredSymbolOnly: false,
	fade: false,
	displaySymbol: false,
	maximumNuberOfDays: 30,
	maximumEntries: 7,
	tableClass: "medium",
        timeFormat: 'absolute',
	getRelative: 0,
        urgency: 3,
        nextDaysRelative: true,
	maxTitleLength: 80,
	calendars: [
		{
                        url: '__PRIVATE_CALENDAR_ICS_URL__',
			symbol: 'calendar'
		},
	],
	}
  }

  ],
  paths: {
    modules: 'modules',
    vendor: 'vendor'
  }
};

/*************** DO NOT EDIT THE LINE BELOW ***************/
if (typeof module !== 'undefined') {module.exports = config;}
