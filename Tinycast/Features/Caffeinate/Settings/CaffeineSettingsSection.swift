import SwiftUI

struct CaffeineSettingsSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle(isOn: $settings.caffeinatePreventDisplaySleep) {
                SettingsRowTitle(.commandsCaffeinate, "Prevent display sleep")
                Text("The screen stays on.")
            }
            Toggle(isOn: $settings.caffeinatePreventSystemSleep) {
                SettingsRowTitle(.commandsCaffeinate, "Prevent system sleep")
                Text("The Mac doesn't idle-sleep. The screen can still turn off.")
            }
            Toggle(isOn: $settings.caffeinatePreventDiskSleep) {
                SettingsRowTitle(.commandsCaffeinate, "Prevent disk sleep")
                Text("Disks stay spun up. This uses more power.")
            }
            Toggle(isOn: $settings.caffeinateShowsMenuBar) {
                SettingsRowTitle(.commandsCaffeinate, "Show in menu bar")
                Text("A cup stays in the menu bar while the Mac is being kept awake.")
            }
        } header: {
            SettingsSectionHeader(.commandsCaffeinate)
        }
    }
}
