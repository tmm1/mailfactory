#!/usr/local/bin/ruby

require 'test/unit/ui/console/testrunner'
require '../lib/mailfactory.rb'


def get_options()
	options = Hash.new()
	
	opts = OptionParser.new() { |opts|
		opts.on_tail("-h", "--help", "Print this message") {
			print(opts)
			exit()
		}

		opts.on("-s", "--smtpserver SERVER", "SMTP server to use for remote tests") { |server|
			options['smtpserver'] = server
		}
		
		opts.on("-f", "--from ADDRESS", "address to send the mail from") { |address|
			options['from'] = address
		}
		
		opts.on("-t", "--to ADDRESS", "address to send the mail to") { |address|
			options['to'] = address
		}
		
		opts.on("-u", "--username USERNAME", "username for smtp auth (required)") { |username|
			options['username'] = username
		}
		
		opts.on("-p", "--password PASSWORD", "password for smtp auth (required)") { |password|
			options['password'] = password
		}
				
	}
	
	opts.parse(ARGV)
	
	return(options)
end



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
			if(line =~ /^To:/i)
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

		assert_nothing_raised("exception raised while setting from=") {
			@mail.from = "test@test2.com"
		}
		
		# count to headers in the final message to make sure we have only one
		count = 0
		@mail.to_s().each_line() { |line|
			if(line =~ /^From:/i)
				count = count + 1
			end
		}
		assert_equal(1, count, "Count of From: headers expected to be 1, but was #{count}")
	end


	def test_set_subject
		assert_nothing_raised("exception raised while setting subject=") {
			@mail.subject = "Test Subject"
		}
		
		assert_equal(@mail.subject, "Test Subject", "subject does not equal what it was set to")

		assert_nothing_raised("exception raised while setting subject=") {
			@mail.subject = "A Different Subject"
		}
		
		# count to headers in the final message to make sure we have only one
		count = 0
		@mail.to_s().each_line() { |line|
			if(line =~ /^Subject:/i)
				count = count + 1
			end
		}
		assert_equal(1, count, "Count of Subject: headers expected to be 1, but was #{count}")		
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
		
		@mail.attach('testfile.txt')
		@mail.attach('testsheet.xls')
		
		if($options['smtpserver'] != nil and $options['to'] != nil and $options['from'] != nil)
			assert_nothing_raised() {
				require('net/smtp')
				Net::SMTP.start($options['smtpserver'], 25, 'mail.from.domain', $options['username'], $options['password'], :cram_md5) { |smtp|
	              smtp.send_message(@mail.to_s(), $options['from'], $options['to'])
	      	}
			}
		end
	end
	
	
	def test_attach
	end
	
end


$options = get_options()
Test::Unit::UI::Console::TestRunner.run(TC_MailFactory)
