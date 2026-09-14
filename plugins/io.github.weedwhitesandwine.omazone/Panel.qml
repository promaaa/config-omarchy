import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.weedwhitesandwine.omazone"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property string homeDir: Quickshell.env("HOME")
  readonly property string pluginDir: homeDir + "/.config/omarchy/plugins/io.github.weedwhitesandwine.omazone"
  readonly property string stateDir: homeDir + "/.local/state/omarchy/omazone"
  readonly property string settingsPath: stateDir + "/settings.json"

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color subtleForeground: Qt.rgba(contentForeground.r, contentForeground.g, contentForeground.b, 0.65)

  property var zoneIds: ["Europe/Paris", "Asia/Seoul", "America/Mexico_City"]
  property var zoneMeta: ({
    "Europe/Paris": { "emoji": "🇫🇷", "label": "Paris" },
    "Asia/Seoul": { "emoji": "🇰🇷", "label": "Seoul" },
    "America/Mexico_City": { "emoji": "🇲🇽", "label": "Mexico City" }
  })
  property bool use24h: true
  property string keybind: "SUPER + I"
  property string barStyle: "compact"
  property bool showGlobeIcon: false
  property bool showDayBadge: true
  property bool showClocksOnBar: true
  property bool settingsLoaded: false

  property bool settingsOpen: false
  property string editingId: ""
  property string editEmoji: ""
  property string editLabel: ""

  property int travelOffsetMinutes: 0
  property var zoneTimes: ({})

  property bool recording: false
  property string pendingCombo: ""
  property string recordError: ""
  property string applyStatus: ""
  property string applyError: ""

  function open() {
    root.travelOffsetMinutes = 0
    root.settingsOpen = false
    root.editingId = ""
    root.controller.show()
    root.refreshTimes()
  }

  function close() {
    root.recording = false
    root.editingId = ""
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.scheduleRefresh()
  }

  readonly property int nowEpoch: Math.floor(clock.date.getTime() / 1000)
  readonly property int effectiveEpoch: nowEpoch + root.travelOffsetMinutes * 60

  onEffectiveEpochChanged: root.scheduleRefresh()
  onZoneIdsChanged: {
    if (citiesMultiSelect) citiesMultiSelect.values = root.zoneIds
    root.scheduleRefresh()
    root.scheduleSettingsSave()
  }
  onSettingsOpenChanged: {
    if (settingsOpen && citiesMultiSelect) {
      citiesMultiSelect.values = root.zoneIds
      citiesMultiSelect.refresh()
    }
  }

  Timer {
    id: refreshDebounce
    interval: 120
    repeat: false
    onTriggered: root.refreshTimes()
  }

  function scheduleRefresh() {
    refreshDebounce.restart()
  }

  Process {
    id: ensureDirsProc
    command: ["mkdir", "-p", root.stateDir]
  }

  FileView {
    id: settingsFile
    path: root.settingsPath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadSettings(text())
    onLoadFailed: root.loadSettings("")
  }

  Timer {
    id: settingsSaveTimer
    interval: 200
    repeat: false
    onTriggered: root.flushSettings()
  }

  function loadSettings(json) {
    var parsed = {}
    try { parsed = JSON.parse(json || "{}") } catch (e) { parsed = {} }
    if (Array.isArray(parsed.zoneIds)) root.zoneIds = parsed.zoneIds
    else root.zoneIds = ["Europe/Paris", "Asia/Seoul", "America/Mexico_City"]
    if (parsed.zoneMeta && typeof parsed.zoneMeta === "object") root.zoneMeta = parsed.zoneMeta
    if (typeof parsed.use24h === "boolean") root.use24h = parsed.use24h
    if (typeof parsed.keybind === "string" && parsed.keybind !== "") root.keybind = parsed.keybind
    if (typeof parsed.barStyle === "string" && parsed.barStyle !== "") root.barStyle = parsed.barStyle
    if (typeof parsed.showGlobeIcon === "boolean") root.showGlobeIcon = parsed.showGlobeIcon
    if (typeof parsed.showDayBadge === "boolean") root.showDayBadge = parsed.showDayBadge
    if (typeof parsed.showClocksOnBar === "boolean") root.showClocksOnBar = parsed.showClocksOnBar
    else if (typeof parsed.showOnBar === "boolean") root.showClocksOnBar = parsed.showOnBar
    root.settingsLoaded = true
    if (citiesMultiSelect) citiesMultiSelect.values = root.zoneIds
    root.refreshTimes()
  }

  function scheduleSettingsSave() {
    if (root.settingsLoaded) settingsSaveTimer.restart()
  }

  function flushSettings() {
    settingsFile.setText(JSON.stringify({
      zoneIds: root.zoneIds,
      zoneMeta: root.zoneMeta,
      use24h: root.use24h,
      keybind: root.keybind,
      barStyle: root.barStyle,
      showGlobeIcon: root.showGlobeIcon,
      showDayBadge: root.showDayBadge,
      showClocksOnBar: root.showClocksOnBar
    }, null, 2) + "\n")
  }

  onUse24hChanged: scheduleSettingsSave()
  onKeybindChanged: scheduleSettingsSave()
  onZoneMetaChanged: scheduleSettingsSave()
  onBarStyleChanged: scheduleSettingsSave()
  onShowGlobeIconChanged: scheduleSettingsSave()
  onShowDayBadgeChanged: scheduleSettingsSave()
  onShowClocksOnBarChanged: scheduleSettingsSave()

  Component.onCompleted: {
    ensureDirsProc.running = true
    Qt.callLater(function() { settingsFile.reload() })
  }

  function refreshTimes() {
    var cmd = ["bash", root.pluginDir + "/get-times.sh", String(root.effectiveEpoch)].concat(root.zoneIds)
    timesProc.command = cmd
    timesProc.running = false
    timesProc.running = true
  }

  Process {
    id: timesProc
    stdout: StdioCollector {
      id: timesStdout
      waitForEnd: true
      onStreamFinished: root.zoneTimes = Model.parseTimesOutput(timesStdout.text)
    }
  }

  function zoneIcon(id) {
    var meta = root.zoneMeta[id]
    return (meta && meta.emoji) ? meta.emoji : Model.cityIcon(id)
  }

  function zoneLabel(id) {
    var meta = root.zoneMeta[id]
    return (meta && meta.label) ? meta.label : Model.friendlyName(id)
  }

  function zoneTimeText(id) {
    var e = root.zoneTimes[id]
    if (!e || e.time24 === undefined) return "--:--"
    return root.use24h ? e.time24 : (e.time12 + " " + e.ampm)
  }

  function zoneBadge(id) {
    var e = root.zoneTimes[id]
    var l = root.zoneTimes["__local__"]
    if (!e || !l) return ""
    return Model.dayBadge(e.date, l.date)
  }

  function zoneSubText(id) {
    var e = root.zoneTimes[id]
    if (!e || e.abbr === undefined) return ""
    return e.abbr + " · " + e.weekday
  }

  function beginEdit(id) {
    root.editingId = id
    root.editEmoji = root.zoneIcon(id)
    root.editLabel = root.zoneLabel(id)
  }

  function cancelEdit() {
    root.editingId = ""
  }

  function saveEdit() {
    if (root.editingId === "") return
    var meta = {}
    for (var key in root.zoneMeta) meta[key] = root.zoneMeta[key]
    meta[root.editingId] = { emoji: root.editEmoji.trim(), label: root.editLabel.trim() }
    root.zoneMeta = meta
    root.editingId = ""
  }

  function removeZone(id) {
    var filtered = []
    for (var i = 0; i < root.zoneIds.length; i++) {
      if (root.zoneIds[i] !== id) filtered.push(root.zoneIds[i])
    }
    root.zoneIds = filtered
    var meta = {}
    for (var key in root.zoneMeta) {
      if (key !== id) meta[key] = root.zoneMeta[key]
    }
    root.zoneMeta = meta
    if (root.editingId === id) root.editingId = ""
    if (citiesMultiSelect) citiesMultiSelect.values = filtered
    root.scheduleRefresh()
    root.scheduleSettingsSave()
  }

  function moveZone(id, delta) {
    var ids = root.zoneIds.slice()
    var i = ids.indexOf(id)
    if (i === -1) return
    var j = i + delta
    if (j < 0 || j >= ids.length) return
    var tmp = ids[i]
    ids[i] = ids[j]
    ids[j] = tmp
    root.zoneIds = ids
    if (citiesMultiSelect) citiesMultiSelect.values = ids
  }

  function isBareModifier(key) {
    return key === Qt.Key_Super_L || key === Qt.Key_Super_R || key === Qt.Key_Meta
      || key === Qt.Key_Control || key === Qt.Key_Shift || key === Qt.Key_Alt || key === Qt.Key_AltGr
  }

  function hyprKeyName(key) {
    if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key)
    if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key)
    if (key >= Qt.Key_F1 && key <= Qt.Key_F12) return "F" + (key - Qt.Key_F1 + 1)
    var names = {}
    names[Qt.Key_Space] = "SPACE"
    names[Qt.Key_Return] = "RETURN"
    names[Qt.Key_Enter] = "RETURN"
    names[Qt.Key_Escape] = "ESCAPE"
    names[Qt.Key_Tab] = "TAB"
    names[Qt.Key_Backspace] = "BACKSPACE"
    names[Qt.Key_Delete] = "Delete"
    names[Qt.Key_Home] = "Home"
    names[Qt.Key_End] = "End"
    names[Qt.Key_PageUp] = "PageUp"
    names[Qt.Key_PageDown] = "PageDown"
    names[Qt.Key_Left] = "left"
    names[Qt.Key_Right] = "right"
    names[Qt.Key_Up] = "up"
    names[Qt.Key_Down] = "down"
    names[Qt.Key_Comma] = "comma"
    names[Qt.Key_Period] = "period"
    names[Qt.Key_Minus] = "minus"
    names[Qt.Key_Equal] = "equal"
    names[Qt.Key_Slash] = "slash"
    names[Qt.Key_Backslash] = "backslash"
    names[Qt.Key_Semicolon] = "semicolon"
    names[Qt.Key_Apostrophe] = "apostrophe"
    names[Qt.Key_BracketLeft] = "bracketleft"
    names[Qt.Key_BracketRight] = "bracketright"
    names[Qt.Key_QuoteLeft] = "grave"
    return names[key] || ""
  }

  function beginRecording() {
    root.recording = true
    root.recordError = ""
    root.pendingCombo = ""
    root.applyStatus = ""
    Qt.callLater(function() { recorder.forceActiveFocus() })
  }

  function cancelRecording() {
    root.recording = false
    root.recordError = ""
    root.pendingCombo = ""
  }

  function handleRecordKey(event) {
    if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
      root.cancelRecording()
      event.accepted = true
      return
    }
    if (root.isBareModifier(event.key)) {
      event.accepted = true
      return
    }

    var mods = []
    if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
    if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
    if (event.modifiers & Qt.AltModifier) mods.push("ALT")
    if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")

    var keyStr = root.hyprKeyName(event.key)
    if (keyStr === "") {
      root.recordError = "Unsupported key — try a letter, digit, F-key, arrow, or punctuation key."
      event.accepted = true
      return
    }
    if (mods.length === 0) {
      root.recordError = "Add a modifier (Super/Ctrl/Alt/Shift) — a bare key would break typing everywhere."
      event.accepted = true
      return
    }
    if (mods.length > 1) {
      root.recordError = "Use exactly one modifier — combos with two or more fail to apply on this system."
      event.accepted = true
      return
    }

    root.recordError = ""
    root.pendingCombo = mods.join(" ") + " + " + keyStr
    event.accepted = true
  }

  function confirmRecording() {
    if (root.pendingCombo === "") return
    root.applyStatus = "applying"
    root.applyError = ""
    keybindProc.command = ["bash", root.pluginDir + "/set-keybind.sh", root.pendingCombo]
    keybindProc.running = true
  }

  Process {
    id: keybindProc
    stdout: StdioCollector { id: keybindStdout; waitForEnd: true }
    stderr: StdioCollector { id: keybindStderr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.keybind = root.pendingCombo
        root.applyStatus = ""
        root.recording = false
        root.pendingCombo = ""
      } else {
        root.applyStatus = "error"
        root.applyError = (keybindStderr.text || "").trim() || "Failed to apply keybind"
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(Style.space(460))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.recording || root.editingId !== ""
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Item {
        anchors.fill: parent

        Row {
          id: headerRow
          width: parent.width
          height: Math.max(titleText.implicitHeight, gearBtn.implicitHeight)

          Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            text: "Omazone"
            color: root.contentForeground
            font.bold: true
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.subtitle
          }

          Item {
            width: Math.max(0, headerRow.width - titleText.width - headerActions.width)
            height: 1
          }

          Row {
            id: headerActions
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            PanelActionButton {
              id: visBtn
              iconText: root.showClocksOnBar ? "󰈈" : "󰈉"
              tooltipText: root.showClocksOnBar ? "Collapse to globe icon on bar" : "Show timezone clocks on bar"
              foreground: root.showClocksOnBar ? root.contentForeground : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.5)
              fontFamily: root.contentFontFamily
              onClicked: {
                root.showClocksOnBar = !root.showClocksOnBar
                root.scheduleSettingsSave()
              }
            }

            PanelActionButton {
              id: gearBtn
              anchors.verticalCenter: parent.verticalCenter
              iconText: root.settingsOpen ? "✕" : "󰒓"
              tooltipText: root.settingsOpen ? "Back to cities" : "Settings"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.settingsOpen = !root.settingsOpen
            }
          }
        }

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

          Column {
            id: mainColumn
            visible: !root.settingsOpen
            width: bodyFlick.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "TIME TRAVEL"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Row {
              width: parent.width
              height: Math.max(travelLabel.implicitHeight, nowBtn.implicitHeight)

              Text {
                id: travelLabel
                anchors.verticalCenter: parent.verticalCenter
                text: Model.formatOffset(root.travelOffsetMinutes)
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.bold: true
                font.pixelSize: Style.font.body
              }

              Item {
                width: parent.width - travelLabel.width - nowBtn.width
                height: 1
              }

              PanelActionButton {
                id: nowBtn
                anchors.verticalCenter: parent.verticalCenter
                iconText: "⟲"
                tooltipText: "Reset to now"
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                enabled: root.travelOffsetMinutes !== 0
                onClicked: root.travelOffsetMinutes = 0
              }
            }

            PanelSlider {
              width: parent.width
              bar: root.bar
              minimum: -1440
              maximum: 2880
              step: 15
              integer: true
              value: root.travelOffsetMinutes
              onMoved: function(v) { root.travelOffsetMinutes = v }
              onReleased: function(v) { root.travelOffsetMinutes = v; root.refreshTimes() }
            }

            Text {
              visible: root.travelOffsetMinutes !== 0
              width: parent.width
              text: {
                var l = root.zoneTimes["__local__"]
                if (!l || l.date === undefined) return ""
                return l.weekday + " " + l.date + " · " + (root.use24h ? l.time24 : (l.time12 + " " + l.ampm)) + " your local time"
              }
              color: root.subtleForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
            }

            PanelSeparator { foreground: root.contentForeground }

            Text {
              visible: root.zoneIds.length === 0
              width: parent.width
              text: "No cities yet — add some from Settings (" + "⚙" + ")."
              color: root.subtleForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.Wrap
            }

            Repeater {
              model: root.zoneIds

              delegate: Item {
                id: rowItem
                required property string modelData
                readonly property bool editing: root.editingId === modelData
                width: mainColumn.width
                height: editing ? Style.space(40) : Style.space(46)

                Row {
                  id: editRow
                  visible: rowItem.editing
                  width: parent.width
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.spacing.xs

                  TextField {
                    id: emojiField
                    width: Style.space(46)
                    text: root.editEmoji
                    foreground: root.contentForeground
                    font.family: root.contentFontFamily
                    horizontalAlignment: Text.AlignHCenter
                    onTextChanged: root.editEmoji = text
                  }

                  TextField {
                    id: labelField
                    width: editRow.width - emojiField.width - saveBtn.width - cancelBtn.width - editRow.spacing * 3
                    text: root.editLabel
                    foreground: root.contentForeground
                    font.family: root.contentFontFamily
                    placeholderText: Model.friendlyName(rowItem.modelData)
                    onTextChanged: root.editLabel = text
                  }

                  PanelActionButton {
                    id: saveBtn
                    iconText: "✓"
                    tooltipText: "Save"
                    foreground: root.contentForeground
                    fontFamily: root.contentFontFamily
                    onClicked: root.saveEdit()
                  }

                  PanelActionButton {
                    id: cancelBtn
                    iconText: "✕"
                    tooltipText: "Cancel"
                    foreground: root.contentForeground
                    fontFamily: root.contentFontFamily
                    onClicked: root.cancelEdit()
                  }
                }

                Row {
                  id: normalRow
                  visible: !rowItem.editing
                  width: parent.width
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.spacing.sm

                  Row {
                    id: leftBlock
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacing.sm

                    Text {
                      text: root.zoneIcon(rowItem.modelData)
                      font.pixelSize: Style.font.subtitle
                    }

                    Column {
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: 2

                      Text {
                        text: root.zoneLabel(rowItem.modelData)
                        color: root.contentForeground
                        font.family: root.contentFontFamily
                        font.bold: true
                        font.pixelSize: Style.font.body
                      }
                      Text {
                        text: Model.regionName(rowItem.modelData)
                        color: root.subtleForeground
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.caption
                      }
                    }
                  }

                  Item {
                    id: spacerItem
                    width: Math.max(0, normalRow.width - leftBlock.width - timeBlock.width - actionsBlock.width - normalRow.spacing * 3)
                    height: 1
                  }

                  Column {
                    id: timeBlock
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Row {
                      anchors.right: parent.right
                      spacing: Style.spacing.xs

                      Text {
                        text: root.zoneTimeText(rowItem.modelData)
                        color: root.contentForeground
                        font.family: root.contentFontFamily
                        font.bold: true
                        font.pixelSize: Style.font.subtitle
                      }
                      Text {
                        visible: text !== ""
                        text: root.zoneBadge(rowItem.modelData)
                        color: Color.accent
                        font.family: root.contentFontFamily
                        font.bold: true
                        font.pixelSize: Style.font.caption
                      }
                    }

                    Text {
                      anchors.right: parent.right
                      text: root.zoneSubText(rowItem.modelData)
                      color: root.subtleForeground
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }

                  Row {
                    id: actionsBlock
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    PanelActionButton {
                      iconText: "↑"
                      tooltipText: "Move up"
                      foreground: root.contentForeground
                      fontFamily: root.contentFontFamily
                      onClicked: root.moveZone(rowItem.modelData, -1)
                    }
                    PanelActionButton {
                      iconText: "↓"
                      tooltipText: "Move down"
                      foreground: root.contentForeground
                      fontFamily: root.contentFontFamily
                      onClicked: root.moveZone(rowItem.modelData, 1)
                    }
                    PanelActionButton {
                      iconText: "✎"
                      tooltipText: "Edit icon & label"
                      foreground: root.contentForeground
                      fontFamily: root.contentFontFamily
                      onClicked: root.beginEdit(rowItem.modelData)
                    }
                    PanelActionButton {
                      iconText: "✕"
                      tooltipText: "Remove"
                      foreground: root.contentForeground
                      fontFamily: root.contentFontFamily
                      hoverColor: Color.urgent
                      onClicked: root.removeZone(rowItem.modelData)
                    }
                  }
                }
              }
            }
          }

          Column {
            id: settingsColumn
            visible: root.settingsOpen
            width: bodyFlick.width
            spacing: Style.space(14)

            PanelSectionHeader {
              text: "BAR DISPLAY"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Toggle {
              width: parent.width
              label: "Show clocks on status bar"
              description: root.showClocksOnBar ? "Displaying timezone clocks on bar" : "Collapsed to globe icon (󰖟) on bar"
              checked: root.showClocksOnBar
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.showClocksOnBar = !root.showClocksOnBar
            }

            Dropdown {
              visible: root.showClocksOnBar
              width: parent.width
              label: "Bar display style"
              value: root.barStyle
              options: [
                { value: "compact", label: "Compact (🇫🇷 09:22 · 🇰🇷 16:22 · 🇲🇽 01:22)" },
                { value: "codes", label: "Airport Codes (PAR · SEL · MEX)" },
                { value: "names", label: "City Names (Paris · Seoul · Mexico)" },
                { value: "cycle", label: "Single Zone (Cycling every 5s)" }
              ]
              foreground: root.contentForeground
              accent: Color.accent
              fontFamily: root.contentFontFamily
              onChanged: function(val) { root.barStyle = val }
            }

            Toggle {
              visible: root.showClocksOnBar
              width: parent.width
              label: "Show globe icon in bar"
              description: "Show 󰖟 prefix icon before timezone clocks"
              checked: root.showGlobeIcon
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.showGlobeIcon = !root.showGlobeIcon
            }

            Toggle {
              visible: root.showClocksOnBar
              width: parent.width
              label: "Show day difference badge"
              description: "Show +1 / −1 when a city is on a different day"
              checked: root.showDayBadge
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.showDayBadge = !root.showDayBadge
            }

            PanelSeparator { foreground: root.contentForeground }

            PanelSectionHeader {
              text: "CITIES"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            MultiSelect {
              id: citiesMultiSelect
              width: parent.width
              label: "Track these cities"
              values: root.zoneIds
              optionsCommand: ["bash", root.pluginDir + "/list-zones.sh"]
              placeholderText: "Search timezones…"
              emptyText: "No matches"
              noSelectionText: "None selected"
              foreground: root.contentForeground
              accent: Color.accent
              fontFamily: root.contentFontFamily
              onChanged: function(values) {
                root.zoneIds = values
              }
            }

            PanelSeparator { foreground: root.contentForeground }

            PanelSectionHeader {
              text: "FORMAT"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Toggle {
              width: parent.width
              label: "24-hour time"
              description: root.use24h ? "14:30" : "2:30 PM"
              checked: root.use24h
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.use24h = !root.use24h
            }

            PanelSeparator { foreground: root.contentForeground }

            PanelSectionHeader {
              text: "KEYBIND"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Button {
              text: root.recording ? (root.pendingCombo !== "" ? root.pendingCombo : "Press keys…") : root.keybind
              bordered: true
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.recording ? root.cancelRecording() : root.beginRecording()
            }

            Item {
              id: recorder
              width: 1
              height: 1
              focus: root.recording
              Keys.onPressed: function(event) { root.handleRecordKey(event) }
            }

            Text {
              visible: root.recording
              text: "Press a shortcut with one modifier (e.g. Super+T). Esc to cancel."
              color: root.subtleForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.Wrap
              width: parent.width
            }

            Text {
              visible: root.recordError !== ""
              text: root.recordError
              color: Color.urgent
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.Wrap
              width: parent.width
            }

            Row {
              visible: root.recording && root.pendingCombo !== ""
              spacing: Style.spacing.sm

              Button {
                text: "Apply"
                bordered: true
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.confirmRecording()
              }
              Button {
                text: "Cancel"
                bordered: true
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.cancelRecording()
              }
            }

            Text {
              visible: root.applyStatus === "applying"
              text: "Applying…"
              color: root.subtleForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
            }
            Text {
              visible: root.applyStatus === "error"
              text: "Failed: " + root.applyError
              color: Color.urgent
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.Wrap
              width: parent.width
            }
          }
        }
      }
    }
  }
}
