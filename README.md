# micro-system-theme

A `micro` editor plugin that follows macOS light/dark appearance and updates
micro's `colorscheme` option automatically.

Currently implemented around a watcher command compatible with
[`dark-notify`](https://github.com/cormacrelf/dark-notify). The command must
print `light` or `dark` on stdout at startup and whenever the system appearance
changes.

## Requirements

Install `dark-notify`:

```sh
brew install cormacrelf/tap/dark-notify
```

## Install
Place this directory into micro's plugin directory:

```sh
mkdir -p ~/.config/micro/plug
git clone https://github.com/dpusceddu/micro-system-theme ~/.config/micro/plug/system-theme
```

Then restart micro.

## Configure
Available options for ``~/.config/micro/settings.json`:

* `systemtheme.light`: light-mode colorscheme, default `bubblegum`.
* `systemtheme.dark`: dark-mode colorscheme, default `monokai`.
* `systemtheme.command`: watcher executable, default `dark-notify`.
* `systemtheme.autorun`: start watcher automatically, default `true`.
* `systemtheme.notifications`: show mode-change messages, default `false`.

## Commands
Inside micro:

```text
> systemtheme update
> systemtheme toggle
> systemtheme start
> systemtheme stop
> systemtheme status
```
