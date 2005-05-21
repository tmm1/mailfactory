#!/usr/local/bin/ruby

require 'test/unit'
require '../lib/mailfactory.rb'

class TC_MailFactory < Test::Unit::TestCase

	def setup()
		@mail = MailFactory.new
	end
	
	
	def test_set_to
		assert_nothing_raised("exception raised while setting to=") {
			@mail.to = "test@test.com"
		}
		
		assert_equal(@mail.to, "test@test.com", "to does not equal what it was set to")
		
		assert_nothing_raised("exception raised while setting to=") {
			@mail.to = "test@test2.com"
		}
		
		# count to headers in the final message to make sure we have only one
		count = 0
		@mail.to_s().each_line() { |line|
			if(line =~ /^To:/)
				count = count + 1
			end
		}
		assert_equal(1, count, "Count of To: headers expected to be 1, but was #{count}")
	end

	def test_set_from
		assert_nothing_raised("exception raised while setting from=") {
			@mail.from = "test@test.com"
		}
		
		assert_equal(@mail.from, "test@test.com", "from does not equal what it was set to")
	end

	def test_set_subject
		assert_nothing_raised("exception raised while setting subject=") {
			@mail.subject = "Test Subject"
		}
		
		assert_equal(@mail.subject, "Test Subject", "subject does not equal what it was set to")
	end

	def test_set_header
		assert_nothing_raised("exception raised while setting arbitrary header") {
			@mail.set_header("arbitrary", "some value")
		}
		
		assert_equal("some value", @mail.get_header("arbitrary")[0], "arbitrary header does not equal \"some value\"")
	end
	
	def test_boundary_generator
		1.upto(50) {
			assert_match(/^----=_NextPart_[a-zA-Z0-9\._]{25}$/, @mail.generate_boundary(), "illegal message boundary generated")
		}
	end
	
	def test_email
		@mail.to="test@test.com"
		@mail.from="test@othertest.com"
		@mail.subject="This is a test"
		@mail.text = "This is a test message with\na few\n\nlines."
	end
end
