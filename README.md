# FolderToQLabSlideshow

This is a simple app to take a folder full of images and create a slideshow in QLab to play them.

## Features

- Keeps checking the folder for any changes (additions, deletions, modifications) every 10 seconds.
- Talks to QLab over OSC.
- Waits 32 seconds to push changes to QLab, in case there are more changes incoming (e.g. copying over a network). If any changes are detected, the 32 second clock resets.
- Preferences for configuring what folder to watch and what OSC PIN to use to talk to QLab.

## Usage

1. Create a QLab workspace like the sample one here. It should have 2 playlist group cues numbered "SS1" and "SS2". FolderToQLabSlideshow will swap between them, with one actively playing while the other can be edited. The one for editing will be disarmed.
2. If you want to forde an update, send the app SIGUSR1. There's an example cue that does this in the example workspace.
3. Launch the app, set its Preferences, and leave it running.
