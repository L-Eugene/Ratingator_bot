RUBY_VERSION = 2.7.0

build-BotLayer:
	mv -f Gemfile.lock Gemfile.lock.bak
	bundle config --local silence_root_warning true
	bundle config --local path $(ARTIFACTS_DIR)
	bundle install
	rm -rf $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION)/cache && rm -rf $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION)/bin
	mkdir -p $(ARTIFACTS_DIR)/ruby/gems
	mv $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION) $(ARTIFACTS_DIR)/ruby/gems
	rm Gemfile.lock
	mv -f Gemfile.lock.bak Gemfile.lock
