require 'rubygems'

spec = Gem::Specification.new do |s|
    s.add_dependency('mime-types', '>= 1.13.1')
    s.name = 'mailfactory'
    s.version = "0.5.2"
    s.platform = Gem::Platform::RUBY
    s.summary = "MailFactory is a pure-ruby MIME mail generator"
    s.description = "MailFactory is s simple module for producing RFC compliant mail that can include multiple attachments, multiple body parts, and arbitrary headers"
    s.files = Dir.glob("lib/*").delete_if {|item| item.include?("~")}
    s.files << Dir.glob("tests/*").delete_if {|item| item.include?("~")}
    s.require_path = 'lib'
    s.autorequire = 'mailfactory'
    s.author = "David Powers"
    s.email = "david@grayskies.net"
    s.rubyforge_project = "mailfactory"
    s.homepage = "http://mailfactory.rubyforge.org"
    s.has_rdoc = true
    s.test_suite_file = "tests/test_mailfactory.rb"
end


if $0==__FILE__
	Gem.manage_gems
	Gem::Builder.new(spec).build
end
