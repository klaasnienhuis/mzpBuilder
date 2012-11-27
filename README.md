# mzp builder

creates maxscript mzp-files from a list of specified files

The ini-file describes the data neede to create the mzp-file

# INI-file

			Expected structure:
				[Header]
					name=...
					description=...
					version=... (integer)
				[Root] the root of the source-paths
					rootpath=...
				[Mzp] 
					name=... the name of the mzp-file which is created
					targetpath=... the place where the mzp-file should be created in the end
				[Source] source and destination need to have the same amount of entries. Source[1] corresponds with Destination[1] and so on
					1=filename with extension. Path relative to the rootpath entered above
					2=...
				[Destination]
					1=filepath ending with a backslash. This is a path on the machine of the user who executes the mzp
					2=...
				[RunIndices]zero or more indices. Each index matches a source-file. These indexed files are also setup to run in the mzp-file
					1=...(integer)
					2=...	
