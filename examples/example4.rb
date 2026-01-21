#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/rubyshell"

sh do
  positions = slurp

  content = chain do
    grim("-g", positions.quoted, "-") | tesseract(
      "- stdout",
      oem: 1,
      psm: 6,
      c: [
        "load_system_dawg=1",
        "load_freq_dawg=1",
        'tessedit_char_blacklist="¦"'
      ]
    )
  end

  chain { echo("-n", content.quoted) | sh("wl-copy") }

  sh(
    "notify-send",
    { h: ["string:x-canonical-private-synchronous:ocr", "string:markup-body:1"] },
    '"OCR copiado"',
    "'<tt>#{content}</tt>'"
  )
end
