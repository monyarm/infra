import Quickshell
import Quickshell.Io
import QtQuick

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            // the screen from the screens list will be injected into this
            // property
            required property var modelData

            color: "black"
            implicitHeight: 16

            // we can then set the window's screen to the injected property
            screen: modelData

            anchors {
                left: true
                right: true
                top: true
            }
            Text {
                id: clock

                anchors.centerIn: parent
                color: "white"

                Process {
                    id: dateProc

                    command: ["date"]
                    running: true

                    stdout: StdioCollector {
                        onStreamFinished: clock.text = this.text
                    }
                }
                Timer {
                    interval: 1000
                    repeat: true
                    running: true

                    onTriggered: dateProc.running = true
                }
            }
        }
    }
}
