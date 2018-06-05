all:
	gem build safe_type.gemspec
	gem install safe_type*.gem

clean:
	rm -f safe_type*.gem
