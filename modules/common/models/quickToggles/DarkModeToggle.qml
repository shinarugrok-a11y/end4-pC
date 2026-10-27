import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Dark Mode")
    statusText: Appearance.m3colors.darkmode ? Translation.tr("Dark") : Translation.tr("Light")

    toggled: Appearance.m3colors.darkmode
    icon: "contrast"
    
    mainAction: () => {
        if (Appearance.m3colors.darkmode) {
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
        } else {
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
        }
    }

    tooltipText: (Config.options?.appearance?.palette?.lockTheme ?? true)
        ? Translation.tr("Shell colors stay on Altimit OS / Grok Bot while appearance.palette.lockTheme is true")
        : Translation.tr("Dark Mode")
}
