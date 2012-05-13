if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_proccess) do |forked|
    if forked
      Rails.cache.instance_variable_get(:@data).reset if Rails.cache.class == ActiveSupport::Cache::MemCacheStore
    end
  end
end
