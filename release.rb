#!/usr/bin/env ruby

require "fileutils"

PREFIX = "https://github.com/treasure-data/trino-client-ruby"
RELEASE_NOTES_FILE = "ChangeLog.md"

last_tag = `git describe --tags --abbrev=0`.chomp
last_version = last_tag.sub("v", "")
puts "last version: #{last_version}"

print "next version? "
next_version = STDIN.gets.chomp

abort("Can't use empty version string") if next_version.empty?

logs = `git log #{last_tag}..HEAD --pretty=format:'%h %s'`
# Add links to GitHub issues
logs = logs.gsub(/\#([0-9]+)/, "[#\\1](#{PREFIX}/issues/\\1)")

new_release_notes = []
new_release_notes <<= "\#\# #{next_version}\n"
new_release_notes <<= logs.split("\n")
  .reject { |line| line.include?("#{last_version} release notes") }
  .map { |x|
    rev = x[0..6]
    "- #{x[8..-1]} [[#{rev}](#{PREFIX}/commit/#{rev})]\n"
  }

release_notes = []
notes = File.readlines(RELEASE_NOTES_FILE)

release_notes <<= notes[0..1]
release_notes <<= new_release_notes
release_notes <<= "\n"
release_notes <<= notes[2..-1]

TMP_RELEASE_NOTES_FILE = "#{RELEASE_NOTES_FILE}.tmp"
File.delete(TMP_RELEASE_NOTES_FILE) if File.exist?(TMP_RELEASE_NOTES_FILE)
File.write(TMP_RELEASE_NOTES_FILE.to_s, release_notes.join)
system("cat #{TMP_RELEASE_NOTES_FILE} | vim - -c ':f #{TMP_RELEASE_NOTES_FILE}' -c ':9'")

abort("The release note file is not saved. Aborted") unless File.exist?(TMP_RELEASE_NOTES_FILE)

def run(cmd)
  puts cmd
  system cmd
end

FileUtils.cp(TMP_RELEASE_NOTES_FILE, RELEASE_NOTES_FILE)
File.delete(TMP_RELEASE_NOTES_FILE)

# run "git commit #{RELEASE_NOTES_FILE} -m \"Add #{next_version} release notes\""
# run "git tag v#{next_version}"
# run "git push"
# run "git push --tags"
