# Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/albertalef/rubyshell).

## Getting Started

```bash
bin/setup          # Install dependencies
rake spec          # Run tests
rake rubocop       # Lint code
rake               # Run both spec and rubocop
```

## Code Style

- Ruby 2.6+ target
- Follow RuboCop defaults, run `rubocop -a` to auto-fix
- 2-space indentation, double-quoted strings, 120 char line length

## Comments

- Avoid comments in the code
- Only add them when necessary to explain non-obvious logic to other developers or reviewers

## Commits

- (Optional) Commit messages use `type: summary` format (e.g., `fix: update version`, `refactor: extract method`)

## Testing

We follow specific RSpec conventions across the project. Please follow these when writing tests.

### Temporary Directory

Every spec must run inside a temporary directory to avoid side effects:

```ruby
around(:example) do |example|
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) { example.run }
  end
end
```

### Use `subject_call` / `subject_method` Helpers

Define the action under test as a helper method instead of using RSpec's built-in `subject`:

```ruby
def subject_call
  sh { pwd }
end

it "returns the correct filepath" do
  expect(subject_call).to include("/example-folder")
end
```

### Wrap Tests in `context` Blocks

All tests must be inside `context` blocks, no file-level `it` blocks:

```ruby
context "when executing a single command" do
  def subject_call
    sh.echo("hello")
  end

  it "returns the command output" do
    expect(subject_call).to eq("hello")
  end
end
```

### Keep Execution Out of `it` Blocks

Setup and execution should live in `let`, `before`, or `subject_call`/`subject_method` helpers. The `it` block should only assert:

```ruby
let(:log_output) { [] }
before { RubyShell.debug = true }

def subject_call
  sh.echo("hello")
end

it "returns the command output" do
  expect(subject_call).to eq("hello")
end
```

### Clean Up Global State with `after`

When tests modify global state, always reset it:

```ruby
after do
  RubyShell.debug = false
end
```

### Prefer Real Execution Over Stubs

Test through real behavior instead of manually constructing objects or stubbing values. If you need an error, trigger it through an actual command failure:

```ruby
# Good - real command triggers the error
def subject_call
  sh { ls("notexistingfolder") }
end

it "raises a Command Execution Error" do
  expect do
    subject_call
  end.to raise_error(RubyShell::CommandError,
                     /No such file or directory/)
end

# Bad - manually building the error
it "has the right message" do
  error = RubyShell::CommandError.new("fake error")
  expect(error.message).to include("fake error")
end
```

### `describe` Nesting

Use top-level `describe` for the class/module, nested `describe` for features or method groups, and `context` for scenarios:

```ruby
RSpec.describe RubyShell::Parsers::Json do
  describe "Methods" do
    describe "#parse" do
      context "when the stdout is a json" do
        # ...
      end
    end
  end
end
```
