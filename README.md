<h1 align="center">
  <img alt="RubyShell" src="./docs/images/rubyshelllogo.png" width="60%">
</h1>

<h3 align="center">The Rubyist way to write shell scripts</h3>

<p align="center">
  <a href="https://rubygems.org/gems/rubyshell">
    <img src="https://img.shields.io/gem/v/rubyshell?color=red&logo=ruby" alt="Gem Version">
  </a>
  <a href="https://rubygems.org/gems/rubyshell">
    <img src="https://img.shields.io/gem/dt/rubyshell.svg?label=Downloads&colorA=004d99&colorB=0073e6" alt="Gem Version">
  </a>
  <a href="https://github.com/albertalef/rubyshell/actions/workflows/main.yml">
    <img src="https://github.com/albertalef/rubyshell/actions/workflows/main.yml/badge.svg" alt="Build Status">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  </a>

  <p align="center">
    <a href="#installation">Installation</a>
    ·
    <a href="#usage">Usage</a>
    ·
    <a href="https://github.com/albertalef/rubyshell/wiki">Wiki</a>
    ·
    <a href="#real-world-examples">Examples</a>
    ·
    <a href="#contributing">Contributing</a>
  </p>
</p>
<br />
<br />

```ruby
  cd "/log" do
    ls.each_line do |line|
      puts cat(line)
    end
  end
```

Yes, that's valid Ruby!
`ls` and `cat` are just shell commands, but **RubyShell** makes them behave like Ruby methods.

## Installation

```bash
bundle add rubyshell
```

Or install directly:

```bash
gem install rubyshell
```

## Why RubyShell?

### The Problem

Ever written something like this?

```bash
# Bash: Find large files modified in the last 7 days, show top 10 with human sizes
find . -type f -mtime -7 -exec ls -lh {} \; 2>/dev/null | \
  awk '{print $5, $9}' | \
  sort -hr | \
  head -10
```

Or tried to do error handling in bash?

```bash
# Bash: Hope nothing goes wrong...
output=$(some_command 2>&1) || echo "failed somehow"
```

### The Solution

```ruby
sh do
  # Ruby + Shell: Same task, actually readable
  find(".", type: "f", mtime: "-7")
    .lines
    .map { |f| [File.size(f.strip), f.strip] }
    .sort_by(&:first)
    .last(10)
    .each { |size, file| puts "#{size / 1024}KB  #{file}" }
rescue RubyShell::CommandError => e
  puts "Failed: #{e.message}"
  puts "Exit code: #{e.status}"
end
```

## Usage

### Basic Commands

```ruby
require 'rubyshell'

sh do
  pwd                        # Run any command
  ls("-la")                  # With arguments
  mkdir("project")           # Create directories
  docker("ps", all: true)    # --all flag
  git("status", s: true)     # -s flag
end

# Or chain directly
sh.git("log", oneline: true, n: 5)
```

### Pipelines

```ruby
sh do
  # Using chain block
  chain { cat("access.log") | grep("ERROR") | wc("-l") }

  # Using bang pattern
  (cat!("data.csv") | sort! | uniq!).exec
end
```

### Directory Scoping

```ruby
sh do
  cd "/var/log" do
    # Commands run here, then return to original dir
    tail("-n", "100", "syslog")
  end
  # Back to original directory
end
```

### Error Handling

```ruby
sh do
  begin
    rm("-rf", "important_folder")
  rescue RubyShell::CommandError => e
    puts "Command: #{e.command}"
    puts "Stderr: #{e.stderr}"
    puts "Exit code: #{e.status}"
  end
end
```

### Parallel Execution

Run multiple commands concurrently and get results as they complete:

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

Returns an Enumerator with results in completion order. Errors are captured and returned as values (not raised).

### Environment Variables

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

### Debug Mode

```ruby
# Global
RubyShell.debug = true

# Block scope
RubyShell.debug { sh.ls }

# Per command
sh.git("status", _debug: true)
# Output:
#   Executed: git status
#   Duration: 0.003521s
#   Pid: 12345
#   Exit code: 0
#   Stdout: "On branch main..."
```

### Output Parsers

Parse command output directly into Ruby objects:

```ruby
sh.cat("data.json", _parse: :json)   # => Hash
sh.cat("config.yml", _parse: :yaml)  # => Hash
sh.cat("users.csv", _parse: :csv)    # => Array
```

### Chain Options

```ruby
# Debug mode for chains
chain(debug: true) { ls | grep("test") }

# Parse chain output
chain(parse: :json) { curl("https://api.example.com") }
```

## Real-World Examples

### Git Workflow Automation

```ruby
sh do
  # Stash changes, pull, pop, and show what changed
  changes = git("status", porcelain: true).lines

  if changes.any?
    puts "Stashing #{changes.count} changed files..."
    git("stash")
    git("pull", rebase: true)
    git("stash", "pop")
  else
    git("pull", rebase: true)
  end

  # Show recent commits by author
  git("log", oneline: true, n: 100)
    .lines
    .map { |line| `git show -s --format='%an' #{line.split.first}`.strip }
    .tally
    .sort_by { |_, count| -count }
    .first(5)
    .each { |author, count| puts "#{author}: #{count} commits" }
end
```

### Log Analysis

```ruby
sh do
  cd "/var/log" do
    # Parse nginx logs: top 10 IPs by request count
    cat("nginx/access.log")
      .lines
      .map { |line| line.split.first }  # Extract IP
      .tally
      .sort_by { |_, count| -count }
      .first(10)
      .each { |ip, count| puts "#{ip.ljust(15)} #{count} requests" }
  end
end
```

### Docker Cleanup

```ruby
sh do
  # Remove containers that exited more than a day ago
  containers = docker("ps", a: true, format: "{{.ID}} {{.Status}}")
    .lines
    .select { |line| line.include?("Exited") }
    .map { |line| line.split.first }

  if containers.any?
    puts "Removing #{containers.count} dead containers..."
    docker("rm", *containers)
  end

  # Remove dangling images
  images = docker("images", f: "dangling=true", q: true).lines.map(&:strip)

  if images.any?
    puts "Removing #{images.count} dangling images..."
    docker("rmi", *images)
  end

  puts "Disk usage:"
  puts docker("system", "df")
end
```

### Batch File Processing

```ruby
sh do
  # Convert all PNGs to WebP, preserving directory structure
  find(".", name: "*.png")
    .lines
    .map(&:strip)
    .each do |png|
      webp = png.sub(/\.png$/, ".webp")
      puts "Converting: #{png}"

      begin
        cwebp("-q", "80", png, o: webp)
        rm(png)
      rescue RubyShell::CommandError => e
        puts "  Failed: #{e.message}"
      end
    end
end
```

### System Health Check

```ruby
sh do
  puts "=== System Health ==="

  # Disk usage warnings
  df("-h")
    .lines
    .drop(1)
    .each do |line|
      parts = line.split
      usage = parts[4].to_i
      mount = parts[5]
      puts "WARNING: #{mount} at #{usage}%" if usage > 80
    end

  # Memory info
  mem = cat("/proc/meminfo")
    .lines
    .first(3)
    .to_h { |l| k, v = l.split(":"); [k, v.strip] }

  puts "\nMemory: #{mem['MemAvailable']} available of #{mem['MemTotal']}"

  # Top 5 CPU consumers
  puts "\nTop CPU processes:"
  ps("aux", sort: "-%cpu")
    .lines
    .drop(1)
    .first(5)
    .each { |proc| puts "  #{proc.split[10]}% - #{proc.split[10..-1].join(' ').slice(0, 40)}" }
end
```

### Interactive Script with Confirmation

```ruby
sh do
  files = find(".", name: "*.tmp", mtime: "+30").lines.map(&:strip)

  if files.empty?
    puts "No old temp files found."
    exit
  end

  puts "Found #{files.count} temp files older than 30 days:"
  files.first(10).each { |f| puts "  #{f}" }
  puts "  ... and #{files.count - 10} more" if files.count > 10

  total_size = files.sum { |f| File.size(f) rescue 0 }
  puts "\nTotal size: #{total_size / 1024 / 1024}MB"

  print "\nDelete all? [y/N] "
  if gets.strip.downcase == 'y'
    files.each { |f| rm(f) }
    puts "Deleted #{files.count} files."
  end
end
```

### Deploy Script

```ruby
#!/usr/bin/env ruby
require 'rubyshell'

APP_NAME = "myapp"
DEPLOY_PATH = "/var/www/#{APP_NAME}"

sh do
  puts "Deploying #{APP_NAME}..."

  # Ensure clean state
  git("status", porcelain: true).lines.tap do |changes|
    abort "Uncommitted changes!" if changes.any?
  end

  # Run tests
  puts "Running tests..."
  rake("spec")

  # Build and deploy
  cd DEPLOY_PATH do
    git("pull", "origin", "main")
    bundle("install", deployment: true)
    rake("db:migrate")

    # Restart with zero downtime
    puts "Restarting..."
    systemctl("reload", APP_NAME)
  end

  puts "Deployed successfully!"

rescue RubyShell::CommandError => e
  puts "Deploy failed: #{e.message}"
  exit 1
end
```

## Comparison

| Task | Bash | RubyShell |
|------|------|-----------|
| Error handling | `cmd \|\| echo "fail"` | `rescue CommandError` |
| String manipulation | `echo $var \| sed \| awk` | `result.gsub(/.../)` |
| Data structures | Arrays only | Hashes, objects, classes |
| Iteration | `for f in *; do` | `.each`, `.map`, `.select` |
| Testing | DIY | RSpec, Minitest |

## Documentation

See [Wiki](https://github.com/albertalef/rubyshell/wiki) for complete documentation including all options and advanced features.

## Development

```bash
bin/setup          # Install dependencies
rake spec          # Run tests
rake rubocop       # Lint code
bin/console        # Interactive console
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/albertalef/rubyshell). See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and testing patterns.

## Sponsors

<a href="https://avantsoft.com.br">
  <img alt="Avantsoft" src="./docs/images/LogoAvantsoft.png" width="40%">
</a>

## License

MIT License - see [LICENSE](https://opensource.org/licenses/MIT).
