#!/bin/bash
# Play notification sound on stop

if [ "$(uname)" = "Darwin" ]; then
    afplay /System/Library/Sounds/Submarine.aiff
elif command -v paplay >/dev/null 2>&1; then
    paplay /usr/share/sounds/freedesktop/stereo/message.oga
fi
