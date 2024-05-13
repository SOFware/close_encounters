module CloseEncounters
  class Engine < ::Rails::Engine
    isolate_namespace CloseEncounters

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
