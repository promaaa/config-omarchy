import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.promaaa.omamoney"

  readonly property var panel: panelLoader.item
  readonly property bool opened: panel ? panel.opened === true : false
  readonly property bool popoutSwitchClosing: panel ? panel.popoutSwitchClosing === true : false

  property string baseCurrency: "EUR"
  property string targetCurrency: "KRW"
  property var presets: []
  property var majorCurrencies: ["USD", "JPY", "GBP", "CHF", "CAD", "AUD"]

  property var rates: ({ "EUR": 1.0, "KRW": 1635.65, "USD": 1.156, "JPY": 184.14, "GBP": 0.854, "CHF": 0.940, "CAD": 1.605, "AUD": 1.633, "CNY": 7.808 })
  property int lastUpdated: 0
  property bool isLive: false
  property int barMode: 0
  property string barStyle: "standard"
  property bool isMinimized: barStyle === "icon" || barMode === 4

  readonly property string homeDir: Quickshell.env("HOME")
  readonly property string scriptPath: homeDir + "/.config/omarchy/plugins/io.github.promaaa.omamoney/get-rates.sh"
  readonly property string configPath: homeDir + "/.config/omarchy/omamoney.json"
  readonly property string saveScriptPath: homeDir + "/.config/omarchy/plugins/io.github.promaaa.omamoney/save-config.py"

  // Dynamic rate calculations
  readonly property double activeRate: Model.getRate(root.baseCurrency, root.targetCurrency, root.rates)
  readonly property double inverseRate: Model.getRate(root.targetCurrency, root.baseCurrency, root.rates)
  readonly property string baseSymbol: Model.getSymbol(root.baseCurrency)
  readonly property string targetSymbol: Model.getSymbol(root.targetCurrency)

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function setMinimized(val) {
    root.isMinimized = !!val
    root.barStyle = root.isMinimized ? "icon" : "standard"
    if (root.isMinimized && root.barMode !== 4) {
      root.barMode = 4
    } else if (!root.isMinimized && root.barMode === 4) {
      root.barMode = 0
    }
    root.persistConfig()
  }

  function toggleMinimized() {
    root.setMinimized(!root.isMinimized)
  }

  function cycleBarMode() {
    root.barMode = (root.barMode + 1) % 5
    root.isMinimized = (root.barMode === 4)
    root.barStyle = root.isMinimized ? "icon" : "standard"
    root.persistConfig()
  }

  function persistConfig() {
    var cfg = {
      baseCurrency: root.baseCurrency,
      targetCurrency: root.targetCurrency,
      barStyle: root.barStyle,
      minimized: root.isMinimized,
      barMode: root.barMode,
      presets: root.presets,
      majorCurrencies: root.majorCurrencies
    }
    persistProc.command = ["python3", root.saveScriptPath, JSON.stringify(cfg)]
    persistProc.running = true
    root.injectPanel()
  }

  function refresh() {
    if (!fetchProc.running) fetchProc.running = true
  }

  function applyConfig(cfg) {
    if (!cfg) return
    root.baseCurrency = cfg.baseCurrency || "EUR"
    root.targetCurrency = cfg.targetCurrency || "KRW"
    root.barStyle = cfg.barStyle || (cfg.minimized ? "icon" : "standard")
    root.isMinimized = (root.barStyle === "icon") || (cfg.minimized === true) || (cfg.barMode === 4)
    if (typeof cfg.barMode === "number") {
      root.barMode = cfg.barMode
    } else {
      root.barMode = root.isMinimized ? 4 : 0
    }
    root.presets = cfg.presets || []
    root.majorCurrencies = cfg.majorCurrencies || ["USD", "JPY", "GBP", "CHF", "CAD", "AUD"]
    root.injectPanel()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.baseCurrency = root.baseCurrency
    panelLoader.item.targetCurrency = root.targetCurrency
    panelLoader.item.barStyle = root.barStyle
    panelLoader.item.isMinimized = root.isMinimized
    panelLoader.item.barMode = root.barMode
    panelLoader.item.presets = root.presets
    panelLoader.item.majorCurrencies = root.majorCurrencies
    panelLoader.item.rates = root.rates
    panelLoader.item.lastUpdated = root.lastUpdated
    panelLoader.item.isLive = root.isLive
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()

  Process {
    id: persistProc
  }

  // Live Config File Watcher
  FileView {
    id: configFileView
    path: root.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var cfg = Model.parseConfig(text())
      root.applyConfig(cfg)
    }
    onLoadFailed: {
      var defaultCfg = Model.parseConfig("")
      root.applyConfig(defaultCfg)
    }
  }

  Process {
    id: fetchProc
    command: ["bash", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) return
        try {
          var data = JSON.parse(raw)
          if (data && data.rates) {
            root.rates = data.rates
            root.lastUpdated = data.timestamp || Math.floor(Date.now() / 1000)
            root.isLive = !!data.is_live
            root.injectPanel()
          }
        } catch (e) {}
      }
    }
  }

  Timer {
    id: fetchTimer
    interval: 3600000 // 1 hour
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "io.github.promaaa.omamoney"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
    function cycle(): void { root.cycleBarMode() }
    function toggleMinimized(): void { root.toggleMinimized() }
    function minimize(): void { root.setMinimized(true) }
    function restore(): void { root.setMinimized(false) }
  }

  readonly property string formattedTargetRate: Model.formatCurrencyAmount(root.activeRate, root.targetCurrency)

  readonly property string barLabel: {
    if (root.barMode === 0) {
      return "1" + root.baseSymbol + " = " + root.formattedTargetRate + root.targetSymbol
    } else if (root.barMode === 1) {
      return root.formattedTargetRate + " " + root.targetSymbol + "/" + root.baseSymbol
    } else if (root.barMode === 2) {
      var sampleUnit = root.targetCurrency === "KRW" ? 10000 : (root.targetCurrency === "JPY" ? 1000 : 100)
      var sampleVal = sampleUnit * root.inverseRate
      return (sampleUnit >= 1000 ? (sampleUnit/1000 + "k") : sampleUnit) + root.targetSymbol + " = " + Model.formatCurrencyAmount(sampleVal, root.baseCurrency) + root.baseSymbol
    } else if (root.barMode === 3) {
      return root.formattedTargetRate + root.targetSymbol
    } else {
      return ""
    }
  }

  readonly property string tooltipContent: {
    var lines = ["OmaMoney Live FX Rates:"]
    lines.push("• 1 " + root.baseCurrency + " (" + root.baseSymbol + ") = " + root.formattedTargetRate + " " + root.targetCurrency + " (" + root.targetSymbol + ")")
    lines.push("• 1 " + root.targetCurrency + " = " + Model.formatNumber(root.inverseRate, 4) + " " + root.baseCurrency)
    var usdRate = Model.getRate("USD", root.targetCurrency, root.rates)
    lines.push("• 1 USD = " + Model.formatCurrencyAmount(usdRate, root.targetCurrency) + " " + root.targetSymbol)
    lines.push("")
    lines.push("Left Click: Open converter panel")
    lines.push("Middle Click: Toggle minimized (cube emoji only)")
    lines.push("Right Click: Cycle display mode (" + (root.isMinimized ? "Minimized 󰆧" : ("Mode " + (root.barMode + 1) + "/5")) + ")")
    return lines.join("\n")
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    horizontalMargin: root.isMinimized ? 6 : 8.75
    verticalPadding: 6
    tooltipText: root.tooltipContent
    fixedWidth: root.vertical ? -1 : (root.isMinimized ? Style.bar.iconSlot : (contentRow.implicitWidth + button.scaledHorizontalMargin * 2))
    fixedHeight: root.vertical ? (root.isMinimized ? Style.bar.iconSlot : (verticalContent.implicitHeight + button.scaledVerticalPadding * 2)) : -1

    onPressed: function(b) {
      if (b === Qt.RightButton) root.cycleBarMode()
      else if (b === Qt.MiddleButton) root.toggleMinimized()
      else root.toggle()
    }

    // Horizontal Minimized Cube Emoji
    Text {
      visible: !root.vertical && root.isMinimized
      anchors.centerIn: parent
      text: "󰆧"
      color: button.active ? button.activeColor : button.foreground
      font.family: button.fontFamily
      font.pixelSize: Style.bar.iconFont
    }

    // Horizontal Expanded Content Row
    Row {
      id: contentRow
      visible: !root.vertical && !root.isMinimized
      anchors.centerIn: parent
      spacing: Style.space(4)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰆧"
        color: button.active ? button.activeColor : Qt.rgba(button.foreground.r, button.foreground.g, button.foreground.b, 0.8)
        font.family: button.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.barLabel
        color: button.active ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.bold: true
        font.pixelSize: Style.font.caption
      }
    }

    // Vertical Minimized Cube Emoji
    Text {
      visible: root.vertical && root.isMinimized
      anchors.centerIn: parent
      text: "󰆧"
      color: button.active ? button.activeColor : button.foreground
      font.family: button.fontFamily
      font.pixelSize: Style.bar.iconFont
    }

    // Vertical Expanded Content Column
    Column {
      id: verticalContent
      visible: root.vertical && !root.isMinimized
      anchors.centerIn: parent
      spacing: Style.space(2)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "󰆧"
        color: button.active ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.caption
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.targetSymbol
        color: button.active ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.bold: true
        font.pixelSize: Style.font.caption
      }
    }
  }
}
