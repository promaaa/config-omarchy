-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
o.window({ class = "^(MEGAsync|nz.co.mega.megasync|megasync)$", title = "^(MEGAsync)$" }, {
  float = true,
  center = true,
  size = { 430, 600 },
})
o.window({ class = "^(MEGAsync|nz.co.mega.megasync|megasync)$", title = "^(Settings|Preferences|Paramètres).*$" }, {
  float = true,
  center = true,
  size = { 800, 600 },
})
o.window({ class = "^(MEGAsync|nz.co.mega.megasync|megasync)$", title = "^(Add .*)$" }, {
  float = true,
  center = true,
  size = { 640, 420 },
})
o.window("^(kakaotalk\\.exe|KakaoTalk\\.exe)$", { float = true })
