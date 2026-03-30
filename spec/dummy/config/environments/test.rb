Dummy::Application.configure do
  if config.respond_to?(:cache_classes=)
    config.cache_classes = true
  else
    config.enable_reloading = false
  end

  config.eager_load = false

  if config.respond_to?(:public_file_server)
    config.public_file_server.enabled = true
  elsif config.respond_to?(:serve_static_files=)
    config.serve_static_files = true
  else
    config.serve_static_assets = true
  end

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  if Rails::VERSION::MAJOR >= 8 || (Rails::VERSION::MAJOR == 7 && Rails::VERSION::MINOR >= 1)
    config.action_dispatch.show_exceptions = :none
  else
    config.action_dispatch.show_exceptions = false
  end

  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :test
  config.active_support.deprecation = :stderr
end
