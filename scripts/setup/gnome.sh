#!/bin/bash -

# Configure Gnome 3 the way I like it

# Special screenshots directory
gsettings set org.gnome.gnome-screenshot auto-save-directory "$HOME/Screenshots/"

# Turn off animations to improve performance
gsettings set org.gnome.desktop.interface enable-animations false
