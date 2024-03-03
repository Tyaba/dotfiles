cond_disable = {
    "type": "frontmost_application_unless",
    "bundle_identifiers": [
        "^org\\.gnu\\.Emacs$",
        "^com\\.apple\\.Terminal$",
        "^com\\.googlecode\\.iterm2$",
        "^org\\.vim\\.",
        "^org\\.x\\.X11$",
        "^com\\.apple\\.x11$",
        "^org\\.macosforge\\.xquartz\\.X11$",
        "^org\\.macports\\.X11$",
        "^com\\.microsoft\\.VSCode$",
    ],
}

cond_disable_desktop = {
    "type": "frontmost_application_unless",
    "bundle_identifiers": [],
}

set_spc = {"set_variable": {"name": "C-SPC", "value": 1}}
clear_spc = {"set_variable": {"name": "C-SPC", "value": 0}}
