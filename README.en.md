# caelestia-ptbr

🌐 [Português (Brasil)](README.md) · **English**

Brazilian Portuguese translation for the [Caelestia shell](https://github.com/caelestia-dots/shell).

Caelestia marks its UI text with `qsTr()`, but quickshell never loads translation catalogues — so
nothing ever shows up translated, no matter what locale your system is in. This project works
around that by editing the literals in the QML itself, on a copy of the shell that lives in your
`~/.config`. The packaged files are never touched.

One command installs it, and the translation re-applies itself after every `pacman -Syu`.

> **Don't speak Portuguese?** The script has nothing Portuguese-specific in it beyond the data.
> Jump to [Translating to another language](#translating-to-another-language) — it is built to be
> reused, and pull requests adding other languages are welcome.

---

## What it looks like

The screenshots below show the Brazilian Portuguese result.

| | |
|:--:|:--:|
| ![Dashboard home](docs/painel.png) | ![Media tab](docs/midia.png) |
| **Dashboard** — weather, calendar and uptime | **Media** — player state |
| ![Performance tab](docs/desempenho.png) | ![Weather tab](docs/clima.png) |
| **Performance** — CPU, disk, network and memory | **Weather** — 7-day forecast and conditions |
| ![Wi-Fi popout](docs/wifi.png) | ![Bluetooth popout](docs/bluetooth.png) |
| **Wi-Fi** | **Bluetooth** |
| ![Battery popout](docs/bateria.png) | ![Bar and desktop](docs/data-area-de-trabalho.png) |
| **Battery** — power profile and time remaining | **Bar** — date in the correct locale |

![Notifications and quick toggles](docs/notificacoes-acoes-rapidas.png)

**Sidebar** — notifications, screen recorder and quick toggles.

---

## Why a `.qm` catalogue can't work

This is the part that usually costs a few hours to figure out, so here it is in writing.

The normal way to translate a Qt app is to compile a `.qm` catalogue and let Qt load it. Qt even
does it automatically: drop `i18n/qml_<locale>.qm` next to the main QML file and it gets picked
up. Except **that feature belongs to `QQmlApplicationEngine`**, and quickshell uses a plain
`QQmlEngine`. With no `QTranslator` installed on the `QCoreApplication`, `qsTr("Wireless")`
returns `"Wireless"` — always.

You can check this on your own machine:

```bash
nm -D /usr/bin/qs | grep -ci QQmlApplicationEngine   # 0
nm -D /usr/bin/qs | grep -ci QTranslator             # 0
```

No catalogue will ever be loaded, wherever you put it. That leaves editing the source text as the
only option — which is exactly what this script does, reproducibly.

There was a second, unrelated problem: `services/Time.qml` used
`Qt.formatDateTime(date, format)`, which resolves day and month names using the **C** locale. The
result was a bar reading `"Sat 15"` next to a calendar reading `"Agosto 2026"`. Fixed by switching
to `toLocaleString(Qt.locale(), format)`, the same pattern the rest of the shell already used.

---

## What gets translated

**231 strings** in the map plus **34 code rules**, producing **268 replacements across 61 files**:

- bar, Wi-Fi / Bluetooth / battery / Caps-Num lock popouts
- the whole dashboard: home, media, performance and weather
- launcher, lock screen, notifications, sidebar, OSD, session menu and utilities
- dates and times in the right locale
- uptime, battery durations and weather conditions (WMO code map)
- low-battery warnings — which aren't in the QML at all: they are default values compiled into
  `libcaelestia-config.so`, so they get translated at display time
- toasts emitted by Caelestia's own C++ (such as "Hibernate failed"), intercepted in the
  `toaster` IPC handler — the single choke point every message from outside the QML goes through
- enums that come back in English from quickshell's C++ (`PowerProfile`,
  `PerformanceDegradationReason`)
- rewritten plurals: English appends an `"s"`, while Portuguese inflects both the noun *and* the
  adjective, so those became complete sentences instead of a suffix

**Deliberately left alone:**

| What | Why |
|---|---|
| Settings panel (`modules/nexus/`) | 524 of the 819 occurrences, almost all config jargon where English is clearer |
| `description:` on global shortcuts | these are keybind identifiers for the Hyprland portal, not on-screen text |
| `"The account is locked"` in `lock/Pam.qml` | never displayed — it's a `startsWith()` comparing against PAM's output. Translating it breaks the check |
| `Enhanced Open`, `Enterprise` | Wi-Fi security standard names (WPA3-OWE), same as in NetworkManager |

---

## Requirements

- [caelestia-shell](https://github.com/caelestia-dots/shell) installed at `/etc/xdg/quickshell/caelestia`
- quickshell (`qs`) on your PATH
- Python 3.9+ and Bash

Developed against `caelestia-shell 2.3.0` and `quickshell 0.3.0` on Arch/CachyOS. It should work
on any distro — nothing here depends on pacman.

## Install

```bash
git clone https://github.com/xKIROxKUNx/caelestia-ptbr.git
cd caelestia-ptbr
./instalar.sh
```

The installer checks dependencies, copies the files, enables automatic re-application, translates
and restarts the shell. Running it again is safe.

Want to see what would change first?

```bash
./caelestia-ptbr --dry-run
```

## Uninstall

```bash
./desinstalar.sh
```

Removes the translated copy and the shell goes back to loading `/etc/xdg`. Because the packaged
files are never modified, `pacman -Qkk caelestia-shell` stays clean the whole time.

---

## Updating

Whenever there are fixes or new strings, from inside your clone:

```bash
./atualizar.sh
```

It fetches the new version, shows what changed, reinstalls and restarts the shell. **No need to
re-clone** — the script updates the very clone it lives in.

If there's nothing new it says so and exits without touching anything. Per-version changes are in
the [CHANGELOG](CHANGELOG.md).

## Changing a word

Don't like one of the translations? Create `~/.config/caelestia-ptbr/local.tsv` with just what you
want to change:

```
Rescan networks	Buscar redes de novo
Nothing playing	Nenhuma mídia
```

Same format as the base map — `english<TAB>translation`, one per line — and whatever is in here
**wins**.

This file is yours: neither the installer nor `atualizar.sh` ever touches it, so your tweaks
survive every project update. After editing:

```bash
caelestia-ptbr && caelestia shell -k && caelestia shell -d
```

The full map, for reference, is [`pt_BR.tsv`](pt_BR.tsv). Strings missing from both files simply
stay in English — they never break anything.

---

## How it works

**A copy, not a patch.** quickshell looks for configurations in each XDG config directory, and
`~/.config` takes priority over `/etc/xdg`. The script copies the shell to
`~/.config/quickshell/caelestia` and translates it there, so `qs -c caelestia` loads the
translated version without a single packaged file being modified.

**Always starts from pristine.** Every run re-syncs from `/etc/xdg` before translating. There is
no accumulated drift, and the result is idempotent: running it twice produces byte-identical trees.

**Atomic swap.** The new tree is built at `caelestia.new` and only then renamed over the old one.
Deleting the in-use copy would break components the shell loads on demand.

**Replacements anchored on `qsTr(`.** Only the literal immediately inside `qsTr(` is swapped.
This is not fussiness: the QML uses English words as internal identifiers — Material icons are
named `"search"` and `"home"`, and there are states called `"visible"` and `"background"`. A loose
find-and-replace would hit those and break the UI.

**Rules for what isn't `qsTr()`.** The `RULES` list at the top of
[`caelestia-ptbr`](caelestia-ptbr) covers what no catalogue could ever reach: labels never marked
translatable, date formats, plurals and enums coming from C++. Each rule is an
`(file, original snippet, replacement)` triple and fails loudly if upstream changes the code.

**Two kinds of update, two mechanisms.** Worth understanding the distinction:

| What changes | How the translation keeps up |
|---|---|
| **Caelestia** is updated by `pacman -Syu` | Automatic. The `caelestia-ptbr.path` unit watches `/etc/xdg/quickshell/caelestia/shell.qml` and re-applies the translation on its own |
| **The translation** gets fixes or new strings | You run `./atualizar.sh` whenever you like |

The first case is the one that would leave the UI broken if unhandled, so that's the automatic
one. The second is an improvement: until you update, new upstream strings show up in English —
it degrades gracefully, it never breaks.

---

## Translating to another language

The script has nothing Portuguese-specific in it beyond the data. To bring Caelestia to your
language:

**1. Extract the shell's strings** (excluding the settings panel):

```bash
grep -rhoP 'qsTr\(\s*"(?:[^"\\]|\\.)*"' /etc/xdg/quickshell/caelestia \
    --include='*.qml' --exclude-dir=nexus \
  | sed -E 's/^qsTr\(\s*"//; s/"$//' | sort -u > strings.txt
```

That's 255 lines. Drop `--exclude-dir=nexus` if you want all 617 from the entire shell.

**2. Build your map.** Copy `pt_BR.tsv` to `xx_XX.tsv` and translate the second column. Rules:

- the separator is a **TAB**, not spaces
- lines starting with `#` are comments; strings that should stay in English are simply omitted
- keep the `%1` / `%2` placeholders and the `\"` and `\n` escapes exactly as they are

**3. Adjust `RULES`** at the top of `caelestia-ptbr`. Many of them apply to any language (the date
fix, the enums), but date ordering, plurals and the weather conditions need your language.

**4. Test with no risk:**

```bash
./caelestia-ptbr --map xx_XX.tsv --dry-run
```

It reports how many replacements it would make and lists map entries that matched nothing — handy
for catching typos. Once it looks right, drop the `--dry-run`.

Pull requests adding other languages are welcome.

---

## License

GPL-3.0, same as the Caelestia shell. This repository does not redistribute any upstream code: it
contains only the script, the translation map and screenshots.

## Credits

[caelestia-dots/shell](https://github.com/caelestia-dots/shell) for the shell, and
[quickshell](https://quickshell.org) for the runtime.
