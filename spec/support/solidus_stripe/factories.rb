FactoryBot.definition_file_paths << SolidusStripe::Engine.root.join(
  'lib/solidus_stripe/testing_support/factories'
).to_s

FactoryBot.reload
