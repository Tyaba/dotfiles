#!/bin/bash
# Play notification sound on stop

if [ "$(uname)" = "Darwin" ]; then
    afplay /System/Library/Sounds/Submarine.aiff
else
    paplay /usr/share/sounds/freedesktop/stereo/message.oga
fi
