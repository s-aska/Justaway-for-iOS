desc 'Setup with example files'
task :setup do
	#Copy Secrets
	 puts 'Copying secret.plist example into place...'

	 `cp Justaway/secret.plist.SAMPLE Justaway/secret.plist`
	 
	 #Done
	 puts "Done! You\'re ready to get started!"
end

# Run setup by default
task :default => :setup