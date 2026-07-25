.PHONY: release lint test clean

release:
	ruby usr/bin/release.rb

lint:
	bundle exec rubocop

test:
	bundle exec polyrun parallel-rspec --workers 5 --merge-failures
	bundle exec rspec spec/integration

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem

install:
	bundle install

console:
	bundle exec bin/console

setup:
	bundle install
	bundle exec bin/setup
