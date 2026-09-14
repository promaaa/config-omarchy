import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.promaaa.omamoney"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color subtleForeground: Qt.rgba(contentForeground.r, contentForeground.g, contentForeground.b, 0.65)
  readonly property color themeAccent: Color.accent

  property string baseCurrency: "EUR"
  property string targetCurrency: "KRW"
  property string barStyle: "standard"
  property bool isMinimized: false
  property int barMode: 0
  property var presets: []
  property var majorCurrencies: ["USD", "JPY", "GBP", "CHF", "CAD", "AUD"]

  property var rates: ({ "EUR": 1.0, "KRW": 1635.65, "USD": 1.156, "JPY": 184.14, "GBP": 0.854, "CHF": 0.940, "CAD": 1.605, "AUD": 1.633, "CNY": 7.808 })
  property int lastUpdated: 0
  property bool isLive: false

  // Dynamic symbols and rate
  readonly property string baseSymbol: Model.getSymbol(root.baseCurrency)
  readonly property string targetSymbol: Model.getSymbol(root.targetCurrency)
  readonly property double baseToTargetRate: Model.getRate(root.baseCurrency, root.targetCurrency, root.rates)
  readonly property double targetToBaseRate: Model.getRate(root.targetCurrency, root.baseCurrency, root.rates)

  // Converter state
  property bool isBaseToTarget: true
  property string inputAmountStr: "1"
  property bool settingsOpen: false

  // Settings edit temporary state
  property string editBase: root.baseCurrency
  property string editTarget: root.targetCurrency

  readonly property string homeDir: Quickshell.env("HOME")
  readonly property string configPath: homeDir + "/.config/omarchy/omamoney.json"
  readonly property string saveScriptPath: homeDir + "/.config/omarchy/plugins/io.github.promaaa.omamoney/save-config.py"

  function open() {
    root.settingsOpen = false
    root.controller.show()
    if (amountInput) {
      amountInput.forceActiveFocus()
      amountInput.selectAll()
    }
  }

  function close() {
    root.settingsOpen = false
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function swapDirection() {
    root.isBaseToTarget = !root.isBaseToTarget
    if (root.isBaseToTarget) {
      root.inputAmountStr = "1"
    } else {
      var sample = root.targetCurrency === "KRW" ? "10000" : (root.targetCurrency === "JPY" ? "1000" : "10")
      root.inputAmountStr = sample
    }
    if (amountInput) {
      amountInput.text = root.inputAmountStr
      amountInput.selectAll()
    }
  }

  function setPreset(amt, isBase) {
    root.isBaseToTarget = isBase
    root.inputAmountStr = String(amt)
    if (amountInput) {
      amountInput.text = String(amt)
      amountInput.selectAll()
    }
  }

  function saveCurrentConfig() {
    var cfg = {
      baseCurrency: root.baseCurrency,
      targetCurrency: root.targetCurrency,
      barStyle: root.isMinimized ? "icon" : "standard",
      minimized: root.isMinimized,
      barMode: root.barMode,
      presets: root.presets,
      majorCurrencies: root.majorCurrencies
    }
    saveProc.command = ["python3", root.saveScriptPath, JSON.stringify(cfg)]
    saveProc.running = true
  }

  function toggleMinimized() {
    if (root.hostWidget && typeof root.hostWidget.toggleMinimized === "function") {
      root.hostWidget.toggleMinimized()
    } else {
      root.isMinimized = !root.isMinimized
      root.barStyle = root.isMinimized ? "icon" : "standard"
      root.barMode = root.isMinimized ? 4 : 0
      root.saveCurrentConfig()
    }
  }

  function saveSettings(newBase, newTarget) {
    var cfg = {
      baseCurrency: (newBase || root.baseCurrency).toUpperCase().trim(),
      targetCurrency: (newTarget || root.targetCurrency).toUpperCase().trim(),
      barStyle: root.isMinimized ? "icon" : "standard",
      minimized: root.isMinimized,
      barMode: root.barMode,
      presets: root.presets,
      majorCurrencies: root.majorCurrencies
    }
    saveProc.command = ["python3", root.saveScriptPath, JSON.stringify(cfg)]
    saveProc.running = true
    root.baseCurrency = cfg.baseCurrency
    root.targetCurrency = cfg.targetCurrency
    root.settingsOpen = false
  }

  function quickSetCurrencies(b, t) {
    root.saveSettings(b, t)
  }

  readonly property double parsedInput: {
    var raw = (root.inputAmountStr || "0").trim().replace(/\s/g, '').replace(/,/g, '.')
    var val = parseFloat(raw)
    return isNaN(val) ? 0 : val
  }

  readonly property double convertedValue: {
    if (root.isBaseToTarget) {
      return root.parsedInput * root.baseToTargetRate
    } else {
      return root.parsedInput * root.targetToBaseRate
    }
  }

  readonly property string convertedText: {
    if (root.isBaseToTarget) {
      return Model.formatCurrencyAmount(root.convertedValue, root.targetCurrency) + " " + root.targetSymbol
    } else {
      return Model.formatCurrencyAmount(root.convertedValue, root.baseCurrency) + " " + root.baseSymbol
    }
  }

  readonly property string convertedSubText: {
    if (root.isBaseToTarget) {
      if (root.targetCurrency === "KRW") {
        return "approx. " + Model.formatKoreanUnits(root.convertedValue)
      } else {
        return "(" + Model.formatCurrencyAmount(root.parsedInput, root.baseCurrency) + " " + root.baseSymbol + ")"
      }
    } else {
      if (root.targetCurrency === "KRW") {
        return "(" + Model.formatCurrencyAmount(root.parsedInput, "KRW") + " ₩)"
      } else {
        return "(" + Model.formatCurrencyAmount(root.parsedInput, root.targetCurrency) + " " + root.targetSymbol + ")"
      }
    }
  }

  Process {
    id: saveProc
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(350))
    contentHeight: panel.fittedContentHeight(Style.space(480))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Item {
        anchors.fill: parent

        // Top Header
        Row {
          id: headerRow
          width: parent.width
          height: Math.max(titleText.implicitHeight, closeBtn.implicitHeight)

          Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            text: root.settingsOpen ? "OmaMoney · Settings" : "OmaMoney · FX Converter"
            color: root.contentForeground
            font.bold: true
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.subtitle
          }

          Item {
            width: Math.max(0, headerRow.width - titleText.implicitWidth - headerActions.width)
            height: 1
          }

          Row {
            id: headerActions
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            PanelActionButton {
              id: visBtn
              iconText: root.isMinimized ? "󰈉" : "󰈈"
              tooltipText: root.isMinimized ? "Show currency rates on bar" : "Collapse to cube icon on bar"
              foreground: root.isMinimized ? Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.5) : root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.toggleMinimized()
            }

            PanelActionButton {
              iconText: root.settingsOpen ? "󰅁" : "󰒓"
              tooltipText: root.settingsOpen ? "Back to converter" : "Customization & Settings"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: {
                root.settingsOpen = !root.settingsOpen
              }
            }

            PanelActionButton {
              iconText: "󰑐"
              tooltipText: "Refresh Rates"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: {
                if (root.hostWidget) root.hostWidget.refresh()
              }
            }

            PanelActionButton {
              id: closeBtn
              iconText: "✕"
              tooltipText: "Close"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.close()
            }
          }
        }

        // Scrollable Body
        Flickable {
          id: bodyFlick
          anchors.top: headerRow.bottom
          anchors.topMargin: Style.space(8)
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          clip: true
          contentWidth: width
          contentHeight: root.settingsOpen ? settingsColumn.implicitHeight : mainColumn.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          interactive: contentHeight > height

          // ==========================================
          // MAIN CONVERTER VIEW
          // ==========================================
          Column {
            id: mainColumn
            visible: !root.settingsOpen
            width: bodyFlick.width
            spacing: Style.space(10)

            // Current Rate Hero Card
            Rectangle {
              width: parent.width
              height: 52
              radius: Style.cornerRadius
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.06)
              border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.15)
              border.width: 1

              Column {
                anchors.centerIn: parent
                spacing: Style.space(2)

                Row {
                  anchors.horizontalCenter: parent.horizontalCenter
                  spacing: Style.space(6)

                  Text {
                    text: "1 " + root.baseCurrency + " ="
                    color: root.subtleForeground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                  }

                  Text {
                    text: Model.formatCurrencyAmount(root.baseToTargetRate, root.targetCurrency) + " " + root.targetCurrency
                    color: root.contentForeground
                    font.bold: true
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                  }
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "1 " + root.targetCurrency + " = " + Model.formatNumber(root.targetToBaseRate, 4) + " " + root.baseCurrency + " · " + (root.isLive ? "Live API" : "Cached")
                  color: root.subtleForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Math.max(9, Math.round(Style.font.caption * 0.85))
                }
              }
            }

            // Converter Input Section
            PanelSectionHeader {
              text: "CONVERTER"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              // Direction Toggle Button
              Button {
                id: swapModeBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 120
                text: root.isBaseToTarget ? (root.baseCurrency + " ➜ " + root.targetCurrency) : (root.targetCurrency + " ➜ " + root.baseCurrency)
                onClicked: root.swapDirection()
              }

              // Amount Input Field
              TextField {
                id: amountInput
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - swapModeBtn.width - Style.space(8)
                text: root.inputAmountStr
                placeholderText: "Amount..."
                font.pixelSize: Style.font.body
                onTextChanged: {
                  root.inputAmountStr = text
                }
              }
            }

            // Converted Output Display Card
            Rectangle {
              width: parent.width
              height: 48
              radius: Style.cornerRadius
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)
              border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.2)
              border.width: 1

              Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.convertedText
                  color: root.contentForeground
                  font.bold: true
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.title
                }

                Item {
                  width: parent.width - parent.children[0].width - parent.children[2].width - 24
                  height: 1
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.convertedSubText
                  color: root.subtleForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }

            // Korean Units Bar (shown when KRW is active)
            Item {
              width: parent.width
              height: krwUnitsColumn.implicitHeight
              visible: root.baseCurrency === "KRW" || root.targetCurrency === "KRW"

              Column {
                id: krwUnitsColumn
                width: parent.width
                spacing: Style.space(6)

                PanelSectionHeader {
                  text: "KOREAN NUMERAL UNITS (MAN / EOK)"
                  foreground: root.contentForeground
                  fontFamily: root.contentFontFamily
                }

                Grid {
                  width: parent.width
                  columns: 3
                  spacing: Style.space(6)

                  Repeater {
                    model: [
                      { label: "1만 (10k ₩)", val: 10000 },
                      { label: "5만 (50k ₩)", val: 50000 },
                      { label: "10만 (100k ₩)", val: 100000 },
                      { label: "50만 (500k ₩)", val: 500000 },
                      { label: "100만 (1M ₩)", val: 1000000 },
                      { label: "1억 (100M ₩)", val: 100000000 }
                    ]

                    delegate: Button {
                      required property var modelData
                      width: (mainColumn.width - Style.space(12)) / 3
                      text: modelData.label
                      onClicked: root.setPreset(modelData.val, false)
                    }
                  }
                }
              }
            }

            // Custom Presets Section
            PanelSectionHeader {
              text: "EXPENSE PRESETS"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Column {
              width: parent.width
              spacing: Style.space(4)

              Repeater {
                model: root.presets

                delegate: Rectangle {
                  required property var modelData
                  width: parent.width
                  height: 30
                  radius: Style.cornerRadius
                  color: mouseArea.containsMouse
                    ? Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.1)
                    : "transparent"

                  readonly property bool isBaseItem: modelData.isBase === true
                  readonly property double rawAmt: Number(modelData.amount || 0)
                  readonly property string currCode: isBaseItem ? root.baseCurrency : root.targetCurrency
                  readonly property string currSym: isBaseItem ? root.baseSymbol : root.targetSymbol
                  readonly property string targetCode: isBaseItem ? root.targetCurrency : root.baseCurrency
                  readonly property string targetSym: isBaseItem ? root.targetSymbol : root.baseSymbol
                  readonly property double rateVal: isBaseItem ? root.baseToTargetRate : root.targetToBaseRate
                  readonly property double convertedVal: rawAmt * rateVal

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: Style.space(8)

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.icon || "󰆧"
                      color: root.contentForeground
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.body
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.name || "Expense"
                      color: root.contentForeground
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                    }

                    Item {
                      width: parent.width - parent.children[0].width - parent.children[1].width - subRow.width - 24
                      height: 1
                    }

                    Row {
                      id: subRow
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: Style.space(4)

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Model.formatCurrencyAmount(rawAmt, currCode) + " " + currSym
                        color: root.subtleForeground
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.caption
                      }

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "➜"
                        color: root.subtleForeground
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.caption
                      }

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Model.formatCurrencyAmount(convertedVal, targetCode) + " " + targetSym
                        color: root.contentForeground
                        font.family: root.contentFontFamily
                        font.bold: true
                        font.pixelSize: Style.font.caption
                      }
                    }
                  }

                  MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setPreset(rawAmt, isBaseItem)
                  }
                }
              }
            }

            // Major Currencies Table
            PanelSectionHeader {
              text: "MAJOR CURRENCIES"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Grid {
              width: parent.width
              columns: 2
              spacing: Style.space(6)

              Repeater {
                model: root.majorCurrencies

                delegate: Rectangle {
                  required property string modelData
                  width: (mainColumn.width - Style.space(6)) / 2
                  height: 32
                  radius: Style.cornerRadius
                  color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.05)
                  border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.1)
                  border.width: 1

                  readonly property double rVal: Model.getRate(root.baseCurrency, modelData, root.rates)

                  Row {
                    anchors.centerIn: parent
                    spacing: Style.space(6)

                    Text {
                      text: Model.getSymbol(modelData)
                      color: root.contentForeground
                      font.bold: true
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.body
                    }

                    Text {
                      text: modelData + ":"
                      color: root.subtleForeground
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                    }

                    Text {
                      text: "1" + root.baseSymbol + " = " + Model.formatCurrencyAmount(rVal, modelData)
                      color: root.contentForeground
                      font.bold: true
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }
            }
          }

          // ==========================================
          // SETTINGS / CUSTOMIZATION VIEW
          // ==========================================
          Column {
            id: settingsColumn
            visible: root.settingsOpen
            width: bodyFlick.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "BAR DISPLAY"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Toggle {
              width: parent.width
              label: "Show only cube emoji (󰆧)"
              description: "Minimize the status bar widget to only the icon."
              checked: root.isMinimized
              foreground: root.contentForeground
              accent: root.themeAccent
              onClicked: root.toggleMinimized()
            }

            PanelSectionHeader {
              text: "ACTIVE CURRENCIES"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              Column {
                width: (parent.width - Style.space(8)) / 2
                spacing: Style.space(4)

                Text {
                  text: "Base Currency"
                  color: root.subtleForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                }

                TextField {
                  id: baseInput
                  width: parent.width
                  text: root.baseCurrency
                  placeholderText: "e.g. EUR, USD, GBP"
                  font.pixelSize: Style.font.body
                }
              }

              Column {
                width: (parent.width - Style.space(8)) / 2
                spacing: Style.space(4)

                Text {
                  text: "Target Currency"
                  color: root.subtleForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                }

                TextField {
                  id: targetInput
                  width: parent.width
                  text: root.targetCurrency
                  placeholderText: "e.g. KRW, JPY, USD"
                  font.pixelSize: Style.font.body
                }
              }
            }

            PanelSectionHeader {
              text: "POPULAR PAIRINGS"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Grid {
              width: parent.width
              columns: 3
              spacing: Style.space(6)

              Repeater {
                model: [
                  { b: "EUR", t: "KRW" },
                  { b: "USD", t: "KRW" },
                  { b: "USD", t: "JPY" },
                  { b: "EUR", t: "USD" },
                  { b: "GBP", t: "EUR" },
                  { b: "USD", t: "THB" }
                ]

                delegate: Button {
                  required property var modelData
                  width: (settingsColumn.width - Style.space(12)) / 3
                  text: modelData.b + " ⇄ " + modelData.t
                  onClicked: {
                    baseInput.text = modelData.b
                    targetInput.text = modelData.t
                    root.saveSettings(modelData.b, modelData.t)
                  }
                }
              }
            }

            PanelSectionHeader {
              text: "CUSTOM CONFIGURATION"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              text: "Presets, expenses, and major currencies can be customized directly in ~/.config/omarchy/omamoney.json"
              color: root.subtleForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }

            Button {
              width: parent.width
              text: "Apply & Save Currency Changes"
              onClicked: {
                root.saveSettings(baseInput.text, targetInput.text)
              }
            }
          }
        }
      }
    }
  }
}
