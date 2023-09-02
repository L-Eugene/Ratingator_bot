RUBY_VERSION = 3.2.0

build-BotLayer:
	find . -name Gemfile.lock -exec mv {} Gemfile.lock.bak \;
	bundle config --local silence_root_warning true
	bundle config --local path $(ARTIFACTS_DIR)
	bundle install
	rm -rf $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION)/cache && rm -rf $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION)/bin
	mkdir -p $(ARTIFACTS_DIR)/ruby/gems
	mv $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION) $(ARTIFACTS_DIR)/ruby/gems
	rm Gemfile.lock
	find -name Gemfile.lock.bak -exec mv {} Gemfile.lock \;
