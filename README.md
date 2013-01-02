# Mousetile

###### A tiling window manager inside Gnome Shell, for people who like using mice.

## Goal

A tiling window manager for mouse users. I'm really inspired by the pane management
UI of Visual Studio, and I'm going to bring that to general-purpose window management.

A side-goal is producing a library abstract enough that most of it can be used both
in the browser, and on the desktop as a Gnome-Shell extension.

The tertiary goal, as always, is not sucking.

## Installation

This repository will eventually become a Gnome Shell extension. For now, just put
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

## Building

Mousetile is written in Coffeescript, and is built using `cake`, the simple Coffeescript
build system. Both run on NodeJS, so you'll need a recent version of Node to install Coffeescript.

Mousetile uses `cake` for tasks

    # Show available tasks
    $ cake

    # Build the libraries and sample app
    $ cake build

If you are doing development and want live recompilation of the libraries,
use `watch.zsh` because it'll spit errors into your terminal. watch.zsh targets
only the libraries in `src` so if you're working on `app.coffee` or `extension.coffee`
you'll have to watch those separately.

## Usage

Right now the gnome shell extension adds a button to the toolbar that shows
"Hello world" when clicked. Uhh. Not that useful.

The most "impressive" thing we have to show so far is a simple GJS Clutter demo
that subdivides some space.

    $ cake build
    $ cake run

## Name

Please suggest a new one. The current name is failing the tertiary goal.

Because I'm bad at names and `gnome-shell-extension-tool` really wanted
one
