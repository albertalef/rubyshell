#!/usr/bin/env ruby
# frozen_string_literal: true

require "rubyshell"

# Inspired on: https://www.reddit.com/r/hyprland/comments/1qfrpt2/my_very_lightweight_ocr_setup_with_tesseract/
sh do
  # Use Slurp to select on screen, and use grim to print the screen in selected area
  image = grim("-g", slurp.quoted, "-")

  # OCR the image
  content = tesseract(
    "- stdout",
    c: [
      "load_system_dawg=1",
      "load_freq_dawg=1",
      'tessedit_char_blacklist="¦"'
    ],
    oem: 1,
    psm: 6,
    _stdin: image
  )

  # Put text on clipboard
  sh("wl-copy", _stdin: content)

  # Send notification
  sh(
    "notify-send",
    "-h string:x-canonical-private-synchronous:ocr",
    "-h string:markup-body:1",
    '"OCR copiado"',
    content.quoted
  )
end
