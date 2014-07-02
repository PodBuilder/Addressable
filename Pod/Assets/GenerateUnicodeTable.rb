#!/usr/bin/env ruby

# This file exists to regenerate unicode_table.plist
# Run it like this:
# DATA=/usr/local/lib/ruby/gems/2.1.0/gems/addressable-2.3.6/data/unicode.data
#  # ... or <wherever your copy of addressable>/data/unicode.data
# ./GenerateUnicodeTable.rb $DATA unicode_table.plist

def xml_escape_char(char)
  case char
  when "<"
   "&lt;"
  when ">"
    "&gt;"
  when "&"
    "&amp;"
  else
    char
  end
end

def xml_escape(raw)
  if raw.kind_of?(Fixnum)
    raw = "%c" % raw
  end

  raw.gsub(/\<|\>|\&/) do |char|
    xml_escape_char(char)
  end
end

if ARGV.length != 2
  $stderr.puts "usage: #{$0} unicode.data unicode_data.plist"
  exit 1
end

data = File.open(ARGV[0], "rb") do |file|
  Marshal.load(file.read)
end

output = ""
output.force_encoding(Encoding::UTF_8)

output << <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<plist>
<dict>
<key>table</key>
<dict>
EOS

data.each { |key, value|
  output << "<key>#{key}</key>\n"
  output << "<dict>\n"

  output << "<key>combining_class</key>\n"
  output << "<integer>#{value[0]}</integer>\n"
  output << "<key>exclusion</key>\n"
  output << "<integer>#{value[1]}</integer>\n"

  if value[2] != nil
    output << "<key>canonical</key>\n"
    output << "<string>#{xml_escape(value[2])}</string>\n"
  end

  if value[3] != nil
    output << "<key>compatibility</key>\n"
    output << "<string>#{xml_escape(value[3])}</string>\n"
  end

  if value[4] != nil
    output << "<key>uppercase_codepoint</key>\n"
    output << "<string>#{xml_escape(value[4])}</string>\n"
  end

  if value[5] != nil
    output << "<key>lowercase_codepoint</key>\n"
    output << "<string>#{xml_escape(value[5])}</string>\n"
  end

  if value[6] != nil
    output << "<key>titlecase_codepoint</key>\n"
    output << "<string>#{xml_escape(value[6])}</string>\n"
  end

  output << "</dict>\n"
}

output << <<-EOS
</dict>
</dict>
</plist>
EOS

File.open(ARGV[1], "wb") do |file|
  file.write(output)
end
