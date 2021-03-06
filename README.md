# MZP builder

creates maxscript mzp-files from a list of specified files. An mzp-file is a zip-file which behaves like an installer in 3dsMax.

The ini-file describes the data needed to create the mzp-file. Also check out the article on [my blog] (http://www.klaasnienhuis.nl/WordPress/2012/11/building-mzp-scripts-for-3dsmax/)

# Usage

Fill in the filepaths in the ini-file along with the other information specified below.

Specifiy the filepath in the mzpBuilder scriptfile

Execute the scriptfile

# INI-file

	Expected structure:
		[About]
			installMessage=... a message which is displayed in a readme-file. This should reduce paranoia when installing an mzp from someone you don't know.
			license=..the license for the script
			support=... contact information for support
			contact=... general contact information	
		[Header] this information is not critical but helps to identify your stuff later on
			name=...
			description=...
			version=... (integer)
		[config]
			sourcerootpath=... the common root of all files which need to be packaged
			buildfilename=... the filename of the resulting build
			buildfilepath=... the filepath of the resulting build
		[Source] source and destination need to have the same amount of entries. Source[1] corresponds with Destination[1] and so on
			1=filename with extension. Path relative to the sourcerootpath entered above
			2=...
		[Destination]
			1=filepath ending with a backslash. This is a path on the machine of the user who executes the mzp
			2=...
		[DropIndices]zero or more indices. Each index matches a source-file. These indexed files are also setup to run in the mzp-file after dropping it into a viewport
			1=...(integer)
			2=...	
		[RunIndices]zero or more indices. Each index matches a source-file. These indexed files are also setup to run in the mzp-file. These are run in order
			1=...(integer)
			2=...
		[Encrypt]
			encryptscripts=boolean encrypts all scripts if set to true. Make sure the script itself is prepared for this
			theArray=#() an array of indices. Indexed files will be encrypted. Only ms-files are supported for encryption.