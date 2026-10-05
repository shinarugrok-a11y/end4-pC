pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Loads Material colors for the shell.
 * Default is the bundled Altimit OS / Grok Bot theme. Wallpaper-generated
 * colors.json is used only when appearance.palette.lockTheme is false.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string bundledThemePath: Directories.altimitOsGrokBotThemePath
    property string filePath: bundledThemePath

    function themeIsLocked() {
        return (Config.options?.appearance?.palette?.lockTheme ?? true) !== false
    }

    function preferredLivePath() {
        return root.themeIsLocked() ? root.bundledThemePath : Directories.generatedMaterialThemePath
    }

    function reapplyTheme() {
        const next = root.preferredLivePath()
        if (root.filePath === next)
            themeFileView.reload()
        else
            root.filePath = next
    }

    function applyColors(fileContent) {
        let json
        try {
            json = JSON.parse(fileContent)
        } catch (error) {
            console.log("[Altimit OS] Could not parse theme file:", error)
            return
        }
        const source = (json && typeof json.id === "string" && json.colors) ? json.colors : json
        for (const key in source) {
            if (!source.hasOwnProperty(key))
                continue
            const value = source[key]
            if (typeof value !== "string" || value.charAt(0) !== "#")
                continue
            const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
            const m3Key = `m3${camelCaseKey}`
            if (Appearance.m3colors[m3Key] !== undefined)
                Appearance.m3colors[m3Key] = value
            else if (Appearance.m3colors[camelCaseKey] !== undefined)
                Appearance.m3colors[camelCaseKey] = value
        }
        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    function useLockTheme() {
        if (root.themeIsLocked()) {
            root.reapplyTheme()
            return
        }
        root.filePath = ""
        root.filePath = Directories.generatedLockMaterialThemePath
    }

    function useLiveTheme() {
        root.reapplyTheme()
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                root.reapplyTheme()
        }
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            if (!root.themeIsLocked()) {
                root.filePath = ""
                root.filePath = Directories.generatedMaterialThemePath
            }
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            if (!themeFileView.loaded)
                return
            const fileContent = themeFileView.text()
            if (!fileContent || fileContent.length === 0)
                return
            root.applyColors(fileContent)
        }
        onLoadFailed: {
            if (root.filePath !== root.bundledThemePath)
                root.filePath = root.bundledThemePath
        }
    }
}
