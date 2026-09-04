import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "omarchy-pomodoro"

  // Settings from shell.json
  readonly property int workMinutes: Model.parseDuration(setting("workMinutes", 25), 25, 1, 120)
  readonly property int shortBreakMinutes: Model.parseDuration(setting("shortBreakMinutes", 5), 5, 1, 60)
  readonly property int longBreakMinutes: Model.parseDuration(setting("longBreakMinutes", 15), 15, 1, 90)
  readonly property int longBreakInterval: Model.parseDuration(setting("longBreakInterval", 4), 4, 1, 12)
  readonly property bool autoStartBreaks: setting("autoStartBreaks", false)
  readonly property bool autoStartWork: setting("autoStartWork", false)
  readonly property bool soundEnabled: setting("soundEnabled", true)
  readonly property bool notifyEnabled: setting("notifyEnabled", true)
  readonly property bool showTimerInBar: setting("showTimerInBar", true)
  readonly property bool showIconInBar: setting("showIconInBar", true)
  readonly property bool showOnlyWhenRunning: setting("showOnlyWhenRunning", false)
  readonly property bool autoStartOnBoot: setting("autoStartOnBoot", true)
  readonly property string home: Quickshell.env("HOME")

  // Pomodoro State
  property string phase: Model.PHASE_WORK
  property string state: Model.STATE_IDLE
  property int completedSessions: 0
  property int totalSeconds: durationForPhase(Model.PHASE_WORK)
  property int timeLeft: totalSeconds

  property bool isMasterTimer: false
  property bool syncingFromShared: false

  readonly property bool isRunning: state === Model.STATE_RUNNING
  readonly property bool isPaused: state === Model.STATE_PAUSED
  readonly property bool isIdle: state === Model.STATE_IDLE
  readonly property real progress: Model.calcProgress(timeLeft, totalSeconds)
  readonly property string timeString: Model.formatTime(timeLeft)
  readonly property string iconString: Model.phaseIcon(phase)
  readonly property string phaseName: Model.phaseTitle(phase)

  // Visibility: can hide on bar when idle if configured
  visible: !showOnlyWhenRunning || isRunning || isPaused || opened

  // Label for horizontal bar
  readonly property string barLabel: {
    var parts = []
    if (showIconInBar) parts.push(iconString)
    if (showTimerInBar || !showIconInBar) parts.push(timeString)
    return parts.join(" ")
  }

  // Label for vertical bar
  readonly property string verticalBarLabel: {
    var mins = Math.ceil(timeLeft / 60)
    return iconString + "\n" + mins + "m"
  }

  function durationForPhase(p) {
    if (p === Model.PHASE_SHORT_BREAK) return shortBreakMinutes * 60
    if (p === Model.PHASE_LONG_BREAK) return longBreakMinutes * 60
    return workMinutes * 60
  }

  function claimMaster() {
    isMasterTimer = true
  }

  readonly property string soundDispatcher: home + "/DOTfiles/scripts/Pomodoro_and_LockScreen_Integration/pomodoro_sound.sh"

  function playSound(action) {
    if (!soundEnabled) return
    Quickshell.execDetached([soundDispatcher, action])
  }

  function start() {
    claimMaster()
    if (timeLeft <= 0) {
      timeLeft = durationForPhase(phase)
      totalSeconds = timeLeft
    }
    state = Model.STATE_RUNNING
    playSound("start")
    broadcastState()
  }

  function pause() {
    claimMaster()
    state = Model.STATE_PAUSED
    playSound("stop")
    broadcastState()
  }

  function togglePlayPause() {
    claimMaster()
    if (isRunning) pause()
    else start()
  }

  function reset() {
    claimMaster()
    state = Model.STATE_IDLE
    totalSeconds = durationForPhase(phase)
    timeLeft = totalSeconds
    playSound("stop")
    broadcastState()
  }

  function setPhase(newPhase, autoStart) {
    claimMaster()
    phase = newPhase
    totalSeconds = durationForPhase(newPhase)
    timeLeft = totalSeconds
    if (autoStart) {
      state = Model.STATE_RUNNING
      playSound("start")
    } else {
      state = Model.STATE_IDLE
    }
    broadcastState()
  }

  function skipPhase() {
    claimMaster()
    var nextInfo = Model.nextPhaseInfo(phase, completedSessions, longBreakInterval)
    completedSessions = nextInfo.completedSessions
    setPhase(nextInfo.nextPhase, false)
  }

  function adjustTime(secondsDelta) {
    claimMaster()
    var next = Model.clamp(timeLeft + secondsDelta, 5, 7200)
    timeLeft = next
    if (next > totalSeconds) totalSeconds = next
    broadcastState()
  }

  function finishSession() {
    var oldPhase = phase
    var nextInfo = Model.nextPhaseInfo(phase, completedSessions, longBreakInterval)
    var nextPhase = nextInfo.nextPhase
    completedSessions = nextInfo.completedSessions

    // Desktop Notification
    if (notifyEnabled) {
      var headline = Model.phaseNotificationHeadline(oldPhase)
      var desc = Model.phaseNotificationDescription(nextPhase)
      var glyph = Model.phaseIcon(oldPhase)
      Quickshell.execDetached([
        "omarchy-notification-send",
        "-g", glyph,
        "-u", "normal",
        headline,
        desc
      ])
    }

    // Audio Chime
    playSound("stop")

    var autoStart = (nextPhase === Model.PHASE_WORK) ? autoStartWork : autoStartBreaks
    setPhase(nextPhase, autoStart)
  }

  function broadcastState() {
    if (syncingFromShared) return
    var isBreak = (phase === Model.PHASE_SHORT_BREAK || phase === Model.PHASE_LONG_BREAK)
    var stateJson = JSON.stringify({
      phase: phase,
      phaseTitle: Model.phaseTitle(phase),
      phaseIcon: Model.phaseIcon(phase),
      state: state,
      timeLeft: timeLeft,
      totalSeconds: totalSeconds,
      completedSessions: completedSessions,
      longBreakInterval: longBreakInterval,
      progress: progress,
      timeString: timeString,
      isBreak: isBreak,
      isRunning: isRunning
    })
    Quickshell.execDetached(["bash", "-c", "echo '" + stateJson.replace(/'/g, "'\\''") + "' > \"${XDG_RUNTIME_DIR:-/tmp}/omarchy-pomodoro-state.json\""])
  }

  function tick() {
    if (timeLeft > 1) {
      timeLeft -= 1
      if (phase === Model.PHASE_WORK && timeLeft === 5) {
        playSound("grace")
        if (notifyEnabled) {
          Quickshell.execDetached([
            "omarchy-notification-send",
            "-g", "☕",
            "-u", "normal",
            "Focus Session Complete in 5s",
            "Break starting in 5 seconds..."
          ])
        }
      }
    } else {
      timeLeft = 0
      finishSession()
    }
    broadcastState()
  }

  function resetSessionsCount() {
    claimMaster()
    completedSessions = 0
    broadcastState()
  }

  // Multi-Monitor Synchronization Watcher
  FileView {
    id: sharedStateFile
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-pomodoro-state.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.syncFromSharedState(text())
  }

  function syncFromSharedState(raw) {
    if (isMasterTimer) return
    var content = String(raw || "").trim()
    if (!content) return
    try {
      var d = JSON.parse(content)
      if (!d) return
      syncingFromShared = true
      if (d.phase !== undefined && phase !== d.phase) phase = d.phase
      if (d.state !== undefined && state !== d.state) state = d.state
      if (d.timeLeft !== undefined && timeLeft !== d.timeLeft) timeLeft = d.timeLeft
      if (d.totalSeconds !== undefined && totalSeconds !== d.totalSeconds) totalSeconds = d.totalSeconds
      if (d.completedSessions !== undefined && completedSessions !== d.completedSessions) completedSessions = d.completedSessions
      syncingFromShared = false
    } catch (e) {
      syncingFromShared = false
    }
  }

  // 1-second interval timer (runs on master instance)
  Timer {
    id: countdownTimer
    interval: 1000
    repeat: true
    running: root.isRunning && root.isMasterTimer
    onTriggered: root.tick()
  }

  // Native auto-start on boot & crash recovery hook
  Timer {
    id: autoStartBootTimer
    interval: 500
    repeat: false
    running: true
    onTriggered: {
      if (!root.syncingFromShared && !root.isMasterTimer) {
        var rawState = sharedStateFile.loaded ? sharedStateFile.text() : ""
        if (!rawState) {
          if (root.autoStartOnBoot && root.isIdle) root.start()
        } else {
          try {
            var d = JSON.parse(rawState)
            if (d && d.isRunning === true && d.timeLeft > 0) {
              // Crash Recovery: Resume exact in-flight session!
              root.claimMaster()
              root.phase = d.phase || Model.PHASE_WORK
              root.timeLeft = d.timeLeft
              root.totalSeconds = d.totalSeconds || root.durationForPhase(root.phase)
              root.completedSessions = d.completedSessions || 0
              root.state = Model.STATE_RUNNING
              root.broadcastState()
            } else if (d && d.state === Model.STATE_PAUSED && d.timeLeft > 0) {
              // Restore paused session
              root.claimMaster()
              root.phase = d.phase || Model.PHASE_WORK
              root.timeLeft = d.timeLeft
              root.totalSeconds = d.totalSeconds || root.durationForPhase(root.phase)
              root.completedSessions = d.completedSessions || 0
              root.state = Model.STATE_PAUSED
              root.broadcastState()
            } else if (root.autoStartOnBoot && root.isIdle) {
              root.start()
            }
          } catch (e) {
            if (root.autoStartOnBoot && root.isIdle) root.start()
          }
        }
      }
    }
  }

  // Contract for shell.summon / hide / toggle and Bar panel routing
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    if (isIdle) {
      totalSeconds = durationForPhase(phase)
      timeLeft = totalSeconds
    }
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
    target: "omarchy-pomodoro"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function start(): void { root.start() }
    function pause(): void { root.pause() }
    function toggleRunning(): void { root.togglePlayPause() }
    function reset(): void { root.reset() }
    function skip(): void { root.skipPhase() }
    function setWork(): void { root.setPhase(Model.PHASE_WORK, false) }
    function setShortBreak(): void { root.setPhase(Model.PHASE_SHORT_BREAK, false) }
    function setLongBreak(): void { root.setPhase(Model.PHASE_LONG_BREAK, false) }
    function addMinute(): void { root.adjustTime(60) }
    function subMinute(): void { root.adjustTime(-60) }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? root.verticalBarLabel : root.barLabel
    hasVisualContent: true
    active: root.isIdle
    activeColor: "#f38ba8"
    foreground: root.isIdle ? "#f38ba8" : (root.isRunning ? (root.isBreak ? "#a6e3a1" : "#89b4fa") : (root.bar ? root.bar.barForeground : Color.foreground))
    dimmed: root.isPaused
    horizontalMargin: 8.5
    verticalPadding: 6
    tooltipText: ""

    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.togglePlayPause()
      } else if (b === Qt.MiddleButton) {
        root.skipPhase()
      } else {
        root.togglePanel()
      }
    }

    onWheelMoved: function(delta) {
      if (delta > 0) root.adjustTime(60)
      else if (delta < 0) root.adjustTime(-60)
    }
  }
}
