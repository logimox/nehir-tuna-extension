# Nehir Tuna Extension

Search and control [Nehir](https://github.com/apphane-dev/nehir), the Niri-style scrolling tiling window manager for macOS, from [Tuna](https://tunaformac.com/).

## Features

- Search every Nehir-managed window by app name or title.
- **Focus Nehir Window** focuses a visible window.
- **Navigate to Nehir Window** changes workspace when needed, then focuses the window.
- A dedicated **Nehir Workspaces** source lists every workspace, including its window count and current-state marker.
- **Switch to Nehir Workspace** is the default action for a workspace.
- **Move Focused Window to Nehir Workspace** moves the current Nehir-focused window to the selected workspace.

The extension calls the official `nehirctl` CLI. It never reads Nehir's IPC secret itself.

## Requirements

- macOS 15 or newer
- Tuna 0.80 or newer
- Nehir with IPC enabled
- `nehirctl` at `/opt/homebrew/bin/nehirctl` (the Homebrew installation path)
- Xcode 16 or newer to build locally

Enable Nehir IPC in Settings → General, or add this to `~/.config/nehir/settings.toml`:

```toml
[general]
ipcEnabled = true
```

## Local development

```zsh
./scripts/tuna-extension build
DEV_BUNDLE_SIGN_IDENTITY=- ./scripts/tuna-extension install --restart
```

The development bundle is installed in:

```text
~/Library/Application Support/Tuna/ExtensionsDev/NehirExtension.framework
```

Tuna must restart after extension code changes. In Tuna, confirm the extension in Settings → Extensions, then enable **Nehir Windows & Workspaces** under Settings → Sources.

## Compatibility note

Nehir's IPC protocol is explicitly unstable. This extension targets the Nehir version installed and tested locally; update and retest it after Nehir upgrades.

## License

MIT. The Tuna extension template is also MIT-licensed.
