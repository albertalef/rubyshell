# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- **Parallel Execution** ([#34](https://github.com/albertalef/rubyshell/pull/34))
  ```ruby
  sh do
    results = parallel do
      curl("https://api1.example.com")
      curl("https://api2.example.com")
      chain { ls | wc("-l") }
    end

    results.each { |r| puts r }
  end
  ```
  - Returns an Enumerator with results in completion order
  - Supports regular commands, chains, and `sh()` calls
  - Errors are captured and returned as values (not raised)

- **Chain Options** ([#34](https://github.com/albertalef/rubyshell/pull/34))
  ```ruby
  # Debug mode for chains
  chain(debug: true) { ls | grep("test") }

  # Parse chain output
  chain(parse: :json) { curl("https://api.example.com") }
  ```

- **Environment Variables** ([#47](https://github.com/albertalef/rubyshell/pull/47))
  ```ruby
  # Command-level
  sh.npm("start", _env: { NODE_ENV: "production" })

  # Block-level
  sh(env: { DATABASE_URL: "postgres://localhost/db" }) do
    rake("db:migrate")
  end

  # Global
  RubyShell.env[:API_KEY] = "secret"
  RubyShell.config(env: { DEBUG: "true" })
  ```

- **Debug Mode** ([#39](https://github.com/albertalef/rubyshell/pull/39))
  ```ruby
  # Global
  RubyShell.debug = true

  # Block scope
  RubyShell.debug { sh.ls }

  # Per command
  sh.git("status", _debug: true)
  ```

- **Output Parsers** ([#38](https://github.com/albertalef/rubyshell/pull/38))
  ```ruby
  sh.cat("data.json", _parse: :json)   # => Hash
  sh.cat("config.yml", _parse: :yaml)  # => Hash
  sh.cat("users.csv", _parse: :csv)    # => Array
  ```

### Changed

- **BREAKING:** Renamed `_env` to `env` in `RubyShell.config` and `sh` block options ([#34](https://github.com/albertalef/rubyshell/pull/34))
  ```ruby
  # Before
  RubyShell.config(_env: { DEBUG: "true" })
  sh(_env: { NODE_ENV: "production" }) { ... }

  # After
  RubyShell.config(env: { DEBUG: "true" })
  sh(env: { NODE_ENV: "production" }) { ... }
  ```
  Note: Command-level `_env` option remains unchanged.

- Refactored specs directory structure


## [1.4.0] - 2026-01-23

### Added

- **Executable generator** ([#29](https://github.com/albertalef/rubyshell/pull/29))
  ```bash
  $ rubyshell new myscript
  # Creates executable file with chmod +x
  ```

- **Stdin parameter support**
  - `_stdin` option to pass string or command output to stdin
  ```ruby
  xclip(_stdin: "text")
  wc("-l", _stdin: some_command!)
  ```

- **Array values in hash params**
  ```ruby
  sed(e: ["one", "two", "three"])
  # equivalent to: sed -e 'one' -e 'two' -e 'three'
  ```

- **Direct command execution for special syntax**
  ```ruby
  sh("notify-send", "hello")
  sh("wl-copy", text)
  ```

## Previous

- Not Tracked
