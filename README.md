<h1 align="center">
  <img alt="RubyShell" src="./docs/images/rubyshelllogo.png" width="60%">
</h1>

<h3 align="center">✨ Rubist way to create shell scripts ✨</h3>

<p align="center">
  <a href="https://rubygems.org/gems/rubyshell">
    <img src="https://img.shields.io/gem/v/rubyshell?color=red&logo=ruby" alt="Gem Version">
  </a>
  <a href="https://github.com/albertalef/rubysh/actions">
    <img src="https://github.com/albertalef/rubysh/workflows/CI/badge.svg" alt="Build Status">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  </a>
</p>

```ruby
cd "/log" do
  ls.each_line do |line|
    puts cat(line)
  end
end
```

Yes, that’s valid Ruby!
`ls` and `cat` are just shell commands, but **RubyShell** makes them behave like Ruby methods.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rubyshell

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rubyshell

## Usage

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/albertalef/rubyshell. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/albertalef/rubyshell/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rubysh project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/albertalef/rubyshell/blob/master/CODE_OF_CONDUCT.md).
