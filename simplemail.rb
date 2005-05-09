#!/usr/local/bin/ruby


require 'base64'
require 'pathname'

# try to bring in the mime/types module, make a dummy module if it can't be found
begin
	begin
		require 'rubygems'
	rescue LoadError
	end
	require 'mime/types'
rescue LoadError
	module MIME
		class Types
			def Types::type_for(filename)
				return('')
			end
		end
	end
end

# An easy class for creating a mail message
class SimpleMail
	
	def initialize()
		@headers = Array.new()
		@attachments = Array.new()
		@attachmentboundary = generate_boundary()
		@bodyboundary = generate_boundary()
	end
	
	
	# adds a header to the bottom of the headers
	def add_header(header, value)
		@headers << "#{header}: #{value}"
	end
	
	
	# removes the named header - case insensitive
	def remove_header(header)
		@headers.delete_if() { |h|
			header =~ /^#{header}:/i
		}
	end
	
	
	# sets a header (removing any other versions of that header)
	def set_header(header, value)
		remove_header(header)
		add_header(header, value)
	end
	
	
	def to=(newto)
		remove_header("To")
		add_header("To", newto)
	end
	
	
	def to()
		return(get_header("To")[0])
	end
	
	
	def from=(newfrom)
		remove_header("From")
		add_header("From", newfrom)
	end
	
	
	def from()
		return(get_header("From")[0])
	end
	
	
	def subject=(newsubject)
		remove_header("Subject")
		add_header("Subject", newsubject)
	end
	
	
	def subject()
		return(get_header("Subject")[0])
	end
	
	
	def cc=(newcc)
		remove_header("CC")
		add_header("CC", newcc)
	end
	
	
	def cc()
		return(get_header("CC")[0])
	end
	
	
	# sets the plain text body of the message
	def text=(newtext)
		@text = newtext
	end
	
	
	# sets the HTML body of the message.  If raw is set to true then the newhtml will not
	# be wrapped in a standard set of headers.  If it is left at false only the body of the
	# html should be provided
	def html=(newhtml, raw=false)
		if(raw)
			@html = newhtml
		else
			@html = "<html>\n<head>\n<meta content=\"text/html;charset=ISO-8859-1\" http-equiv=\"Content-Type\">\n</head>\n<body bgcolor=\"#ffffff\" text=\"#000000\">\n#{newhtml}\n</body>\n</html>"
		end
	end
	
	
	# returns the value (or values) of the named header in an array
	def get_header(header)
		headers = Array.new()
		headerregex = /^#{Regexp.escape(header)}:/i
		@headers.each() { |h|
			if(headerregex.match(h))
				headers << h[/^[^:]+:(.*)/i, 1].strip()
			end
		}
		
		return(headers)
	end
	
	
	# returns true if the email is multipart
	def multipart?()
		if(@attachments.length > 0 or (@text != nil and @html != nil))
			return(true)
		else
			return(false)
		end
	end
	
	
	# returns a formatted email
	def to_s()
		if(get_header("Date").length == 0)
			add_header("Date", Time.now.strftime("%a, %d %B %Y %H:%M:%S %Z"))
		end
		
		# Add a mime header if we don't already have one and we have multiple parts
		if(multipart?())
			if(get_header("MIME-Version").length == 0)
				add_header("MIME-Version", "1.0")
			end
			
			if(get_header("Content-Type").length == 0)
				if(@attachments.length == 0)
					add_header("Content-Type", "multipart/alternative; boundary=\"#{@attachmentboundary}\"")
				else
					add_header("Content-Type", "multipart/mixed; boundary=\"#{@attachmentboundary}\"")
				end
			end
		end
		
		return("#{headers_to_s()}#{body_to_s()}")
	end
	
	
	# generates a unique boundary string
	def generate_boundary()
		randomstring = Array.new()
		1.upto(25) {
			whichglyph = rand(100)
			if(whichglyph < 40)
				randomstring << (rand(25) + 65).chr()
			elsif(whichglyph < 70)
				randomstring << (rand(25) + 97).chr()
			elsif(whichglyph < 90)
				randomstring << (rand(10) + 48).chr()
			elsif(whichglyph < 95)
				randomstring << '.'
			else
				randomstring << '_'
			end
		}
		return("----=_NextPart_#{randomstring.join()}")
	end
	
	
	# adds an attachment to the mail.  Type may be given as a mime type.  If it
	# is left off it will be determined automagically.
	def add_attachment(filename, type=nil)
		attachment = Array.new()
		attachment[0] = Pathname.new(filename).basename
		attachment[1] = MIME::Types.type_for(filename).to_s
		File.open(filename, File::RDONLY) { |fp|
			attachment[2] = Base64.b64encode(fp.read())
		}
		@attachments << attachment
	end
	
protected

	# returns the @headers as a properly formatted string
	def headers_to_s()
		return("#{@headers.join("\r\n")}\r\n\r\n")
	end
	
	
	# returns the body as a properly formatted string
	def body_to_s()
		body = Array.new()
		
		# simple message with one part
		if(!multipart?())
			return(@text)
		else
			body << "This is a multi-part message in MIME format.\n--#{@attachmentboundary}\r\nContent-Type: multipart/alternative; boundary=\"#{@bodyboundary}\""
			
			# text part
			body << "#{buildbodyboundary('text/plain; charset=ISO-8859-1; format=flowed', '7bit')}\r\n\r\n#{@text}"
			
			# html part
			body << "#{buildbodyboundary('text/html; charset=ISO-8859-1', '7bit')}\r\n\r\n#{@html}"
			
			body << "--#{@bodyboundary}--"
			
			# and, the attachments
			if(@attachments.length > 0)
				@attachments.each() { |attachment|
					body << "#{buildattachmentboundary(attachment[1], 'base64', attachment[0])}\r\n\r\n#{attachment[2]}"
				}
				body << "\r\n--#{@attachmentboundary}--"
			end
			
			return(body.join("\r\n\r\n"))
		end
	end
	
	
	# builds a boundary string for including attachments in the body
	def buildattachmentboundary(type, encoding, filename)
		disposition = "\r\nContent-Disposition: inline; filename=\"#{filename}\""
		return("--#{@attachmentboundary}\r\nContent-Type: #{type}; name=\"#{filename}\"\r\nContent-Transfer-Encoding: #{encoding}#{disposition}")
	end
	
	
	# builds a boundary string for inclusion in the body of a message
	def buildbodyboundary(type, encoding, filename=nil)
		return("--#{@bodyboundary}\r\nContent-Type: #{type}\r\nContent-Transfer-Encoding: #{encoding}")
	end
	
end

