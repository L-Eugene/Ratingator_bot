RUBY_VERSION = 2.7.0

build-BotLayer:
	bundle config --local silence_root_warning true
	bundle config --local path $(ARTIFACTS_DIR)
	bundle install --path=$(ARTIFACTS_DIR)
	rm -rf $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION)/cache && rm -rf $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION)/bin
	mkdir -p $(ARTIFACTS_DIR)/ruby/gems
	mv $(ARTIFACTS_DIR)/ruby/$(RUBY_VERSION) $(ARTIFACTS_DIR)/ruby/gems
