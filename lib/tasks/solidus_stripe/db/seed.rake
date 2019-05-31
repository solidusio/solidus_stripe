# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc 'Loads stripe sample data'
    task solidus_stripe: :environment do
      seed_file = Dir[SolidusStripe::Engine.root.join('db', 'seeds.rb')][0]
      return unless File.exist?(seed_file)

      puts "Seeding #{seed_file}..."
      load(seed_file)
    end
  end
end
