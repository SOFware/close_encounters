module CloseEncounters
  class Engine < ::Rails::Engine
    isolate_namespace CloseEncounters

    config.generators do |g|
      g.test_framework :minitest, spec: true
    end

    if defined?(Importmap)
      initializer "close_encounters.importmap", before: "importmap" do |app|
        app.config.importmap.paths << root.join("config/importmap.rb")
      end
    end

    if defined?(Sprockets)
      initializer "close_encounters.assets" do |app|
        app.config.assets.precompile += %w[close_encounters_manifest.js]
      end
    end
  end
end
