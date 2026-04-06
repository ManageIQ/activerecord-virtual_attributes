require "bundler/gem_tasks"
require "rspec/core/rake_task"

namespace :db do
  desc "Create the database"
  task :create do
    require_relative "spec/support/database"
    Database.new.create
  rescue ActiveRecord::DatabaseAlreadyExists => e
    puts e.message
  end

  desc "Drop the database"
  task :drop do
    require_relative "spec/support/database"
    Database.new.drop
    # NOTE: this silently fails if the database does not exist
  end
end

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = "spec/*_spec.rb"
end

task :default => :spec
