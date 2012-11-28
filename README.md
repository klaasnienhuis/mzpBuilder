# MZP builder

creates maxscript mzp-files from a list of specified files. An mzp-file is a zip-file which behaves like an installer in 3dsMax.

The ini-file describes the data needed to create the mzp-file. Also check out the article on [my blog] (http://www.klaasnienhuis.nl/WordPress/2012/11/building-mzp-scripts-for-3dsmax/)

# Usage

Fill in the filepaths in the ini-file along with the other information specified below.

Specifiy the filepath in the mzpBuilder scriptfile

Execute the scriptfile

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