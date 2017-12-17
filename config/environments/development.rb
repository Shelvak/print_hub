Rails.application.configure do
  config.cache_classes = false

  config.eager_load = false

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true

  config.action_view.raise_on_missing_translations = true

  config.active_record.migration_error = :page_load

  config.active_support.deprecation = :stderr

  config.assets.quiet = true
  config.assets.debug = true
end
