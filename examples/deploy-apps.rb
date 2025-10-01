#!/usr/bin/env ruby

require_relative "../lib/rubyshell"

sh_unsafe_mode true

def update_from_master(master_branch: "master")
  git "pull origin #{master_branch}"
  git "checkout -B test"
  git "merge --no-edit #{master_branch}"
  # git "push"

  puts git("branch --show-current")
end

cd(zoxide("query tau bac")) { update_from_master }
cd(zoxide("query tau man")) { update_from_master }
cd(zoxide("query tau esta")) { update_from_master }
cd(zoxide("query tau guest")) { update_from_master }
cd(zoxide("query tau cli")) { update_from_master(master_branch: "main") }
