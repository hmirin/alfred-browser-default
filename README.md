# Alfred — Default Browser

An Alfred 5 workflow to change the macOS default web browser.

Lists every installed app that can handle `https://` (queried from LaunchServices) and sets it as the default handler for both `http` and `https`.

## Install

1. Run `./build.sh` to produce `default-browser.alfredworkflow`.
2. Double-click the file to import it into Alfred.

## Usage

Trigger Alfred and type:

```
browser
```

Pick a browser. macOS will show a one-time confirmation dialog on first switch — that prompt is enforced by the OS and cannot be bypassed.

The current default is pinned to the top of the list and marked with `✓`.

## Requirements

- macOS 12 (Monterey) or later — uses `NSWorkspace.setDefaultApplication(at:toOpenURLsWithScheme:)`.
- Swift toolchain (Xcode Command Line Tools) only required to build.

## How it works

`default-browser.swift` is a tiny Swift CLI with two subcommands:

| Command | Behavior |
| --- | --- |
| `default-browser list` | Emits Alfred Script Filter JSON of every app registered as an `https` handler. |
| `default-browser set <bundle-id>` | Sets that app as the default for `http` and `https`. |

The workflow wires the Script Filter output into a Run Script action that invokes `set`.

## License

MIT
