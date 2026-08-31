import QtQuick
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

    // --- Colossal Responsive 3D Flip Clock (Dominates Top/Center 88% of Screen) ---
    FlipClock {
      id: flipClock
      anchors.top: parent.top
      anchors.topMargin: 20
      anchors.bottom: inputField.top
      anchors.bottomMargin: 24
      anchors.horizontalCenter: parent.horizontalCenter
      availableWidth: root.width
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
