if Rails.application.config.respond_to?(:session_store)
  Rails.application.config.session_store :cookie_store, key: '_dummy_session'
end
