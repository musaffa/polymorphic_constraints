if Dummy::Application.config.respond_to?(:secret_token=)
  Dummy::Application.config.secret_token = 'existing secret token'
end
if Dummy::Application.config.respond_to?(:secret_key_base=)
  Dummy::Application.config.secret_key_base = 'test secret key base that is long enough'
end
