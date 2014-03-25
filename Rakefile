desc 'Setup with example files'
task :setup do
	# Copy Secrets
	 puts 'Copying JFISecret.h example into place...'

	 `cp Justaway/JFISecret.h.SAMPLE Justaway/JFISecret.h`

	 # Done
	 puts "Done! You\'re ready to get started!"
end

# Run setup by default
task :default => :setup