# systemtheme

`systemtheme` switches micro's `colorscheme` option when macOS changes between
light and dark appearance.

The plugin uses an external watcher command. By default this is `dark-notify`,
which prints `light` or `dark` at startup and each time the system appearance
changes. Install it with:

```
brew install cormacrelf/tap/dark-notify
```

## Options

* `systemtheme.light`: colorscheme used for light appearance.
  Default: `bubblegum`.
* `systemtheme.dark`: colorscheme used for dark appearance.
  Default: `monokai`.
* `systemtheme.command`: watcher executable compatible with `dark-notify`.
  Default: `dark-notify`.
* `systemtheme.autorun`: start watching when micro starts.
  Default: `true`.
* `systemtheme.notifications`: show a message each time a colorscheme is
  applied.
  Default: `false`.

Example `settings.json`:

```
{
    "systemtheme.light": "bubblegum",
    "systemtheme.dark": "monokai"
}
```

## Commands

* `systemtheme start`: start watching system appearance.
* `systemtheme stop`: stop watching.
* `systemtheme restart`: restart the watcher.
* `systemtheme update`: detect and apply the current appearance.
* `systemtheme toggle`: switch between the configured light and dark schemes.
* `systemtheme light`: apply the configured light colorscheme.
* `systemtheme dark`: apply the configured dark colorscheme.
* `systemtheme status`: show watcher and mode state.

## Notes

If `dark-notify --exit` is unavailable, `systemtheme update` can still detect
the current macOS appearance with `defaults read -g AppleInterfaceStyle`.
Continuous watching requires `dark-notify` or another compatible command.
