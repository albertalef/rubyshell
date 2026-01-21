#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/rubyshell"

# Inspired on: https://www.reddit.com/r/hyprland/comments/1qfrpt2/my_very_lightweight_ocr_setup_with_tesseract/
sh do
  positions = slurp
  image = grim("-g", positions.quoted, "-")

  content = tesseract(
    "- stdout",
    oem: 1,
    psm: 6,
    c: ["load_system_dawg=1", "load_freq_dawg=1", 'tessedit_char_blacklist="¦"'],
    _stdin: image
  )

  sh("wl-copy", _stdin: content)

  sh(
    "notify-send",
    { h: ["string:x-canonical-private-synchronous:ocr", "string:markup-body:1"] },
    '"OCR copiado"',
    "'<tt>#{content}</tt>'"
  )
end
