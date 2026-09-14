import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.weedwhitesandwine.omazone"

  readonly property var panel: panelLoader.item
  readonly property bool opened: panel ? panel.opened === true : false
  readonly property bool popoutSwitchClosing: panel ? panel.popoutSwitchClosing === true : false

  readonly property var zoneIds: panel && panel.zoneIds && panel.zoneIds.length > 0
    ? panel.zoneIds
    : ["Europe/Paris", "Asia/Seoul", "America/Mexico_City"]
  readonly property var zoneMeta: panel && panel.zoneMeta ? panel.zoneMeta : ({})
  readonly property var zoneTimes: panel && panel.zoneTimes ? panel.zoneTimes : ({})
  readonly property bool use24h: panel ? panel.use24h : true
  readonly property string barStyle: panel && panel.barStyle ? panel.barStyle : "compact"
  readonly property bool showGlobeIcon: panel ? panel.showGlobeIcon : false
  readonly property bool showDayBadge: panel ? panel.showDayBadge : true
  readonly property bool showClocksOnBar: panel ? (panel.showClocksOnBar !== false && panel.barStyle !== "icon") : true

  property int cycleIndex: 0

  Timer {
    id: cycleTimer
    interval: 5000
    running: root.showClocksOnBar && root.barStyle === "cycle" && root.zoneIds.length > 1
    repeat: true
    onTriggered: {
      if (root.zoneIds.length > 0)
        root.cycleIndex = (root.cycleIndex + 1) % root.zoneIds.length
    }
  }

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

  function cycleBarStyle() {
    var styles = ["compact", "codes", "names", "cycle"]
    var idx = styles.indexOf(root.barStyle)
    var next = styles[(idx + 1) % styles.length]
    if (panelLoader.item) {
      panelLoader.item.barStyle = next
      panelLoader.item.showClocksOnBar = true
      panelLoader.item.scheduleSettingsSave()
    }
  }

  function toggle24h() {
    if (panelLoader.item) {
      panelLoader.item.use24h = !panelLoader.item.use24h
      panelLoader.item.scheduleSettingsSave()
    }
  }

  function toggleClocksVisibility() {
    if (panelLoader.item) {
      panelLoader.item.showClocksOnBar = !panelLoader.item.showClocksOnBar
      panelLoader.item.scheduleSettingsSave()
    }
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  function zoneIcon(id) {
    if (panelLoader.item && typeof panelLoader.item.zoneIcon === "function") {
      return panelLoader.item.zoneIcon(id)
    }
    var meta = root.zoneMeta[id]
    return (meta && meta.emoji) ? meta.emoji : Model.cityIcon(id)
  }

  function zoneLabel(id) {
    if (panelLoader.item && typeof panelLoader.item.zoneLabel === "function") {
      return panelLoader.item.zoneLabel(id)
    }
    var meta = root.zoneMeta[id]
    return (meta && meta.label) ? meta.label : Model.friendlyName(id)
  }

  function zoneTimeText(id) {
    if (panelLoader.item && typeof panelLoader.item.zoneTimeText === "function") {
      return panelLoader.item.zoneTimeText(id)
    }
    var e = root.zoneTimes[id]
    if (!e || e.time24 === undefined) return "--:--"
    return root.use24h ? e.time24 : (e.time12 + " " + e.ampm)
  }

  function zoneBadge(id) {
    if (panelLoader.item && typeof panelLoader.item.zoneBadge === "function") {
      return panelLoader.item.zoneBadge(id)
    }
    var e = root.zoneTimes[id]
    var l = root.zoneTimes["__local__"]
    if (!e || !l) return ""
    return Model.dayBadge(e.date, l.date)
  }

  readonly property string barTooltipText: {
    if (!root.showClocksOnBar) return "Omazone (Click to open timezone panel)"
    if (!root.zoneIds || root.zoneIds.length === 0) return "Omazone: No tracked cities (Click to add)"
    var lines = ["Omazone Multi-Timezone:"]
    for (var i = 0; i < root.zoneIds.length; i++) {
      var id = root.zoneIds[i]
      var icon = root.zoneIcon(id)
      var label = root.zoneLabel(id)
      var time = root.zoneTimeText(id)
      var badge = root.zoneBadge(id)
      var tObj = root.zoneTimes[id]
      var abbr = tObj && tObj.abbr ? (" " + tObj.abbr) : ""
      var offset = tObj && tObj.utcOffset ? (" (" + Model.formatUtcOffset(tObj.utcOffset) + ")") : ""
      var badgeStr = badge !== "" ? (" [" + badge + " day]") : ""
      lines.push(icon + " " + label + ": " + time + abbr + offset + badgeStr)
    }
    lines.push("")
    lines.push("Left click: Open panel · Middle click: Switch bar style · Right click: Toggle 24h")
    return lines.join("\n")
  }

  readonly property real openPanelIndicatorWidth: Math.max(Style.space(12), Math.min(button.width * 0.65, Style.space(64)))
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()

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
    target: "io.github.weedwhitesandwine.omazone"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function cycleStyle(): void { root.cycleBarStyle() }
    function toggleFormat(): void { root.toggle24h() }
    function toggleClocks(): void { root.toggleClocksVisibility() }
    function toggleBar(): void { root.toggleClocksVisibility() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    horizontalMargin: root.showClocksOnBar ? 14 : 6
    verticalPadding: 6
    tooltipText: root.barTooltipText
    fixedWidth: root.vertical ? -1 : (root.showClocksOnBar ? (contentRow.implicitWidth + button.scaledHorizontalMargin * 2) : Style.bar.iconSlot)
    fixedHeight: root.vertical ? (verticalContent.implicitHeight + button.scaledVerticalPadding * 2) : -1

    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggle24h()
      else if (b === Qt.MiddleButton) root.cycleBarStyle()
      else root.toggle()
    }
    onWheelMoved: function(delta) {
      if (root.showClocksOnBar && root.barStyle === "cycle" && root.zoneIds.length > 1) {
        if (delta > 0) root.cycleIndex = (root.cycleIndex - 1 + root.zoneIds.length) % root.zoneIds.length
        else root.cycleIndex = (root.cycleIndex + 1) % root.zoneIds.length
      }
    }

    // Single Globe Icon (when collapsed / clocks hidden)
    Text {
      visible: !root.showClocksOnBar && !root.vertical
      anchors.centerIn: parent
      text: "󰖟"
      color: button.active ? button.activeColor : button.foreground
      font.family: button.fontFamily
      font.pixelSize: Style.bar.iconFont
    }

    // Expanded Clocks Row (when showClocksOnBar is true)
    Row {
      id: contentRow
      visible: root.showClocksOnBar && !root.vertical
      anchors.centerIn: parent
      spacing: Style.space(6)

      // Optional globe icon prefix if enabled
      Text {
        visible: root.showGlobeIcon || root.zoneIds.length === 0
        anchors.verticalCenter: parent.verticalCenter
        text: "󰖟"
        color: button.active ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.body
      }

      // Multi-zone horizontal list (compact, codes, or names)
      Row {
        visible: root.zoneIds.length > 0 && root.barStyle !== "cycle"
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(8)

        Repeater {
          model: root.zoneIds

          delegate: Row {
            id: zoneRow
            required property string modelData
            required property int index
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(3.5)

            // Flag/Emoji (in compact mode)
            Text {
              visible: root.barStyle === "compact"
              anchors.verticalCenter: parent.verticalCenter
              text: root.zoneIcon(modelData)
              font.pixelSize: Style.font.caption
            }

            // Airport / 3-letter code (in codes mode)
            Text {
              visible: root.barStyle === "codes"
              anchors.verticalCenter: parent.verticalCenter
              text: Model.cityCode(modelData)
              color: Qt.rgba(button.foreground.r, button.foreground.g, button.foreground.b, 0.75)
              font.family: button.fontFamily
              font.bold: true
              font.pixelSize: Style.font.caption
            }

            // City name (in names mode)
            Text {
              visible: root.barStyle === "names"
              anchors.verticalCenter: parent.verticalCenter
              text: root.zoneLabel(modelData)
              color: Qt.rgba(button.foreground.r, button.foreground.g, button.foreground.b, 0.8)
              font.family: button.fontFamily
              font.bold: true
              font.pixelSize: Style.font.caption
            }

            // Time digits
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.zoneTimeText(modelData)
              color: button.active ? button.activeColor : button.foreground
              font.family: button.fontFamily
              font.bold: true
              font.pixelSize: Style.font.caption
            }

            // Day difference badge (+1 / -1)
            Text {
              visible: root.showDayBadge && root.zoneBadge(modelData) !== ""
              anchors.verticalCenter: parent.verticalCenter
              text: root.zoneBadge(modelData)
              color: Color.accent
              font.family: button.fontFamily
              font.bold: true
              font.pixelSize: Math.max(9, Math.round(Style.font.caption * 0.85))
            }
          }
        }
      }

      // Single cycling zone mode
      Row {
        visible: root.zoneIds.length > 0 && root.barStyle === "cycle"
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(4)

        readonly property string currentId: root.zoneIds.length > 0
          ? root.zoneIds[Math.min(root.cycleIndex, root.zoneIds.length - 1)]
          : ""

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.zoneIcon(parent.currentId)
          font.pixelSize: Style.font.caption
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.zoneLabel(parent.currentId)
          color: Qt.rgba(button.foreground.r, button.foreground.g, button.foreground.b, 0.8)
          font.family: button.fontFamily
          font.bold: true
          font.pixelSize: Style.font.caption
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.zoneTimeText(parent.currentId)
          color: button.active ? button.activeColor : button.foreground
          font.family: button.fontFamily
          font.bold: true
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.showDayBadge && root.zoneBadge(parent.currentId) !== ""
          anchors.verticalCenter: parent.verticalCenter
          text: root.zoneBadge(parent.currentId)
          color: Color.accent
          font.family: button.fontFamily
          font.bold: true
          font.pixelSize: Math.max(9, Math.round(Style.font.caption * 0.85))
        }
      }
    }

    // Vertical bar layout
    Column {
      id: verticalContent
      visible: root.vertical
      anchors.centerIn: parent
      spacing: Style.space(2)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "󰖟"
        color: button.active ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.body
      }

      Repeater {
        model: root.showClocksOnBar && root.zoneIds.length > 0 ? root.zoneIds.slice(0, 3) : []

        delegate: Text {
          required property string modelData
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.zoneIcon(modelData)
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
