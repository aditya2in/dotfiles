import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool loadBackground: true
  property string placeholderText: "Enter Password"
  property string failureMessage: ""
  property int failedAttempts: 0
  property string passwordText: ""
  property bool inputEnabled: true
  property bool authenticatingPassword: false
  property bool fingerprintConfigured: false
  property bool previewMode: false

  property real fieldWidth: 320
  property real fieldHeight: 48
  property real fieldFontSize: 14
  property real passwordDotFontSize: 18
  property real passwordDotLetterSpacing: 5.5
  property real passwordMaxDotCount: 16
  property bool showPasswordCursor: false
  property var inputBorderSpec: Style.lock ? Style.lock.inputBorder : ({})

  // Pomodoro & Live Clock State
  property string pomodoroPhase: "work"
  property string pomodoroPhaseTitle: "Focus Session"
  property string pomodoroPhaseIcon: "󰔛"
  property string pomodoroTimeString: "25:00"
  property int pomodoroCompletedSessions: 0
  property int pomodoroLongBreakInterval: 4
  property bool pomodoroIsBreak: false
  property bool pomodoroIsRunning: false

  property var breakTasks: []
  readonly property bool isUltrawideDualPane: (root.width > 2000 && root.pomodoroIsBreak)

  property string systemClockString: "00:00"
  property string systemDateString: ""

  signal wakeRequested()
  signal submitPassword(string password)
  signal passwordTextEdited(string text)
  signal clearFailureRequested()

  property bool syncingPasswordText: false

  function fileUrl(path) {
    if (!path) return ""
    if (path.indexOf("://") !== -1) return path
    return "file://" + path
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  readonly property real fingerprintReserve: fingerprintConfigured ? (fieldFontSize * 1.5) : 0
  readonly property real passwordAvailableWidth: Math.max(1, fieldWidth - (inputField.borderLeft + inputField.borderRight + 36 + fingerprintReserve * 2))
  readonly property real passwordDotScale: {
    if (dotMetrics.width <= 0) return 1.0
    return Math.min(1.0, passwordAvailableWidth / dotMetrics.width)
  }

  function syncPasswordText() {
    if (syncingPasswordText) return
    syncingPasswordText = true
    if (passwordInput.text !== root.passwordText) {
      passwordInput.text = root.passwordText
    }
    syncingPasswordText = false
  }

  function parseBreakChecklist(raw) {
    var rawText = (typeof raw === "string") ? raw : (breakChecklistFile.loaded ? breakChecklistFile.text() : "")
    var tasks = []
    if (!rawText) {
      breakTasks = []
      return
    }
    var lines = String(rawText).split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      // Match unchecked markdown tasks: - [ ] <task>
      var m = line.match(/^-\s*\[\s*\]\s+(.+)/)
      if (m && m[1]) {
        tasks.push(m[1].trim())
      }
    }
    breakTasks = tasks
  }

  function updatePomodoroState(raw) {
    var rawText = (typeof raw === "string") ? raw : (pomodoroStateFile.loaded ? pomodoroStateFile.text() : "")
    if (!rawText) return
    try {
      var data = JSON.parse(rawText)
      pomodoroPhase = data.phase || "work"
      pomodoroPhaseTitle = data.phaseTitle || "Focus Session"
      pomodoroPhaseIcon = data.phaseIcon || "󰔛"
      pomodoroTimeString = data.timeString || ""
      pomodoroCompletedSessions = data.completedSessions || 0
      pomodoroLongBreakInterval = data.longBreakInterval || 4
      pomodoroIsBreak = data.isBreak || false
      pomodoroIsRunning = data.isRunning || false
    } catch (e) {
      // ignore
    }
  }

  function updateSystemClock() {
    var now = new Date()
    var hours = now.getHours()
    var mins = now.getMinutes()
    var hStr = hours < 10 ? "0" + hours : String(hours)
    var mStr = mins < 10 ? "0" + mins : String(mins)
    systemClockString = hStr + ":" + mStr
    systemDateString = Qt.formatDate(now, "dddd, d MMMM yyyy")
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    updateSystemClock()
    updatePomodoroState()
    parseBreakChecklist()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  FileView {
    id: pomodoroStateFile
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-pomodoro-state.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.updatePomodoroState(text())
  }

  FileView {
    id: breakChecklistFile
    path: Quickshell.env("HOME") + "/Obsidian/All Things/break_routine.md"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parseBreakChecklist(text())
  }

  Timer {
    id: systemClockTimer
    interval: 1000
    repeat: true
    running: true
    onTriggered: root.updateSystemClock()
  }

  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: "#08080c"

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    // --- Left Pane: Live Break Action Checklist (Ultrawide Landscape Only) ---
    Rectangle {
      id: checklistPanel
      visible: root.isUltrawideDualPane
      width: Math.min(1050, Math.round(root.width * 0.34))
      anchors.left: parent.left
      anchors.leftMargin: 70
      anchors.top: parent.top
      anchors.topMargin: 40
      anchors.bottom: inputField.top
      anchors.bottomMargin: 30
      color: "#101018"
      border.color: "#252538"
      border.width: 1.5
      radius: 18
      clip: true

      Column {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 18

        // Panel Header
        Row {
          width: parent.width
          spacing: 12

          Text {
            text: "☕"
            font.pixelSize: 26
            verticalAlignment: Text.AlignVCenter
          }

          Text {
            text: "BREAK ACTION LIST"
            color: "#f5f5fa"
            font.family: Style.font.family
            font.pixelSize: 22
            font.bold: true
            verticalAlignment: Text.AlignVCenter
          }

          Item { width: 1; height: 1; Layout.fillWidth: true }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            width: taskBadgeText.implicitWidth + 20
            color: "#1e3a29"
            border.color: "#a6e3a1"
            border.width: 1
            radius: 14

            Text {
              id: taskBadgeText
              anchors.centerIn: parent
              text: root.breakTasks.length + " Pending"
              color: "#a6e3a1"
              font.family: Style.font.family
              font.pixelSize: 13
              font.bold: true
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: "#252538"
        }

        // Checklist Items
        ListView {
          width: parent.width
          height: parent.height - 70
          clip: true
          spacing: 12
          model: root.breakTasks

          delegate: Rectangle {
            width: parent.width
            height: Math.max(52, taskTextItem.implicitHeight + 20)
            color: "#161622"
            border.color: "#2a2a3e"
            border.width: 1
            radius: 12

            Row {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 14

              Text {
                text: "○"
                color: "#a6e3a1"
                font.family: Style.font.family
                font.pixelSize: 20
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                id: taskTextItem
                width: parent.width - 40
                text: modelData
                color: "#f5f5fa"
                font.family: Style.font.family
                font.pixelSize: 17
                wrapMode: Text.WordWrap
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }
        }
      }
    }

    // --- Colossal Responsive 3D Flip Clock ---
    FlipClock {
      id: flipClock
      anchors.top: parent.top
      anchors.topMargin: 20
      anchors.bottom: inputField.top
      anchors.bottomMargin: 24
      anchors.left: root.isUltrawideDualPane ? checklistPanel.right : undefined
      anchors.leftMargin: root.isUltrawideDualPane ? 40 : 0
      anchors.right: root.isUltrawideDualPane ? parent.right : undefined
      anchors.rightMargin: root.isUltrawideDualPane ? 70 : 0
      anchors.horizontalCenter: root.isUltrawideDualPane ? undefined : parent.horizontalCenter
      availableWidth: root.isUltrawideDualPane ? Math.round(root.width * 0.58) : root.width
      availableHeight: Math.max(300, root.height - root.fieldHeight - 70)

      timeString: root.pomodoroIsRunning ? root.pomodoroTimeString : root.systemClockString
      phaseTitle: root.pomodoroIsRunning ? root.pomodoroPhaseTitle : root.systemDateString
      phaseIcon: root.pomodoroIsRunning ? root.pomodoroPhaseIcon : "🕒"
      completedSessions: root.pomodoroCompletedSessions
      totalCycleSessions: root.pomodoroIsRunning ? root.pomodoroLongBreakInterval : 0
      isBreak: root.pomodoroIsRunning && root.pomodoroIsBreak
      isRunning: root.pomodoroIsRunning
    }

    // --- Sleek Password Input Field (Anchored to Bottom Center) ---
    BorderSurface {
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Math.max(36, Math.round(root.height * 0.04))
      anchors.horizontalCenter: parent.horizontalCenter
      color: Color.lock.background
      borderSpec: root.inputBorderSpec
      radius: Style.cornerRadius
      clip: true

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: Color.lock.text
        selectionColor: Color.lock.selection
        selectedTextColor: Color.lock.text
        font.family: Style.font.family
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: Color.lock.text
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? Color.lock.text : (root.failureMessage.length > 0 ? Color.lock.textError : Color.lock.placeholder)
        font.family: Style.font.family
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: "󰈷"
        color: Color.lock.placeholder
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }
}
