# frozen_string_literal: true

Dir[File.join(__dir__, "**", "*.rb")].sort.each do |file|
  next if file == __FILE__

  require_relative file
end
