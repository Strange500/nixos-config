#!/usr/bin/env python3
"""Remap French text so `ydotool type` reproduces it on a French AZERTY layout.

Why: `ydotool type` translates each character to a keycode using a *hardcoded
US QWERTY* table and ignores the compositor's keyboard layout.  On a French
AZERTY system the result is garbled (``que`` -> ``aue``, ``faire`` -> ``fqire``,
``problème`` -> ``probl,e`` …) and accented letters are dropped outright.

This tool applies the inverse map: for every character it emits the US-QWERTY
keystroke(s) that sit on the *same physical key* as the target French
character, so that the compositor (still on ``fr``/AZERTY) yields the correct
glyph.  Shifted French characters (digits, some punctuation, uppercase) map to
the corresponding shifted US character so `ydotool` emits Shift itself.

Reads UTF-8 text on stdin, writes the remapped keystroke stream on stdout.
"""

import sys

# French AZERTY -> US QWERTY keystrokes.  Multi-char values are dead-key
# sequences (dead circumflex `^` -> US `[`, dead diaeresis `¨` -> US `{`).
MAP = {
    # --- letters (physical positions differ: a/q, z/w, m/; …) ---
    "a": "q", "z": "w", "m": ";", "q": "a", "w": "z",
    "A": "Q", "Z": "W", "M": ":", "Q": "A", "W": "Z",
    # letters unchanged: e r t y u i o p s d f g h j k l x c v b n
    # --- accents (direct, unshifted on AZERTY) ---
    "é": "2", "è": "7", "ç": "9", "à": "0", "ù": "'",
    # --- accents (dead circumflex -> US `[`) ---
    "â": "[a", "ê": "[e", "î": "[i", "ô": "[o", "û": "[u",
    "Â": "[Q", "Ê": "[E", "Î": "[I", "Ô": "[O", "Û": "[U",
    # --- accents (dead diaeresis -> US `{`) ---
    "ä": "{a", "ë": "{e", "ï": "{i", "ö": "{o", "ü": "{u", "ÿ": "{y",
    "Ä": "{Q", "Ë": "{E", "Ï": "{I", "Ö": "{O", "Ü": "{U",
    # --- uppercase accents with no direct AZERTY key: drop the accent ---
    "É": "E", "È": "E", "À": "Q", "Ç": "C", "Ù": "U",
    # --- digits (shifted on AZERTY) ---
    "1": "!", "2": "@", "3": "#", "4": "$", "5": "%",
    "6": "^", "7": "&", "8": "*", "9": "(", "0": ")",
    # --- unshifted punctuation (AZERTY -> US key at same position) ---
    "&": "1", '"': "3", "'": "4", "(": "5", "-": "6", "_": "8",
    ")": "-", "=": "=", "$": "]", ",": "m", ";": ",", ":": ".",
    "!": "/",
    # --- shifted punctuation ---
    "°": "_", "+": "+", "?": "M", ".": "<", "/": ">", "%": '"',
    "£": "}", "§": "?",
    # --- ligatures (no AZERTY key): transliterate ---
    "œ": "oe", "Œ": "OE", "æ": "ae", "Æ": "AE",
}

# Lowercase letters whose AZERTY and QWERTY positions coincide; add them
# explicitly so the table is complete and self-documenting.
_IDENTICAL = "ertyuio psdfghjkl xcvbn".replace(" ", "")
for _ch in _IDENTICAL:
    MAP.setdefault(_ch, _ch)
    MAP.setdefault(_ch.upper(), _ch.upper())


def remap(text: str) -> str:
    return text.translate({ord(k): v for k, v in MAP.items()})


def main() -> None:
    sys.stdout.write(remap(sys.stdin.read()))


if __name__ == "__main__":
    main()
