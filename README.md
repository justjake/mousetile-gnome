# Mousetile

###### A tiling window manager inside Gnome Shell, for people who like using mice.

## Installation

This repository will eventially become a Gnome Shell extension. For now, just put
it wherever you usually store your personal projects, then symlink it into place:

    # Clone the repo
    $ cd ~/src; git clone https://github.com/justjake/mousetile-gnome.git

    # Link in the shell extension
    $ mkdir -p ~/.local/share/gnome-shell/extensions
    $ cd !$
    $ ln -s ~/src/mousetile-gnome mousetile@jake.teton-landis.org

Then, to activate the extension, point `Firefox` or any browser with
the Gnome-Shell plugin installed to the [installed extensions
page](https://extensions.gnome.org/local/), and turn the **Mousetile**
extension on.

## Usage

Right now the gnome shell extension adds a button to the toolbar that shows
"Hello world" when clicked. Uhh. Not that useful.

The most "impressive" thing we have to show so far is a simple GJS Clutter demo
that subdivides some space.

    $ cake build
    $ cake run

## Intended Behavior

Your shell should behave like the panel layout UI of Visual Studio
2012. If it doesn't, that's because there's no code here, yet.

## Name

Please suggest a new one.

Because I'm bad at names and `gnome-shell-extension-tool` really wanted
one
