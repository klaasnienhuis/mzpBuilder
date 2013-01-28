/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-11-26
Last Updated: 2013-01-18
Version: 2

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	compile scripts, art and other files to a maxscript mzp-file
	specify paths of the needed files
	create a mzp.run-file
	enter the correct commands in the mzp.run file
	zip the files
	
Usage:
	specifiy a list of files and a list of destinations and run the script to create an mzp-file from it
	you can keep this file with your project and compile your mzp's based on an ini-file repeatedly without much hassle
	
Features:
	zips files from your developing-location to an mzp
	create a run-file which copies and runs files from that mzp-package
	
Wishlist:
	a bit more intelligence when handling filepaths
	an integritycheck for the supplied ini-file
	can the ini-file be easier to fill in
	does a gui help? Or does it make stuff more complicated?
Changelog:
	2012-11-26: first setup, used the zip-methods from teh sketchfab script
	2012-11-26: added fn_writeRunFile method to write a runfile
	2012-11-27: added mzpBuilder struct to hold data and retrieve it from an ini-file
	2012-11-27: refactoring. Combined all methods in a single struct. Moved more settings to the ini-file
	2012-11-27: made it as foolproof as possible without creating a gui. It's still a tool for developers, not regular users.
	2012-11-29: edited ini-filestructure. Now the run-file has its own destination
	2012-11-29: undo the last edit. Doesn't seem to work. Added support for a drop-file
	Branch: installReadme
	2012-11-29: also create a readme independently from the mzp-file. Contains info on the installer, license, support and contact information
	2013-01-18: added an option to encrypt all scripts
	2013-01-28: made encryption more specific. Now you point directly to the scripts you want encrypted with an array of indices
	2013-01-28: added the versionnumber to the filename of mzp
	2013-01-28: added a datestamp to the filename of mzp
</SCRIPTFILE>
*******************************************************************************************************/

(
	/***************************************************************************************************
	1 CREATE AN INI-FILE WITH A SCHEME CORRESPONDING TO THE ONE DESCRIBED IN THE FN_GETDATAFROMINI METHOD
	AND FILL IT WITH YOUR OWN DATA
	***************************************************************************************************/
	
	/***************************************************************************************************
	2 EDIT THIS FILEPATH (THEINIFILE) TO POINT TO YOUR OWN INI-FILE
	3 THEN EXECUTE THIS FILE TO COMPILE YOUR MZP-FILE
	***************************************************************************************************/
	local theIniFile = @"N:\GitHub\mzpBuilder\mzpbuilder_list_demo.ini"

	/***************************************************************************************************
	DON'T EDIT THE STUFF BELOW, IT SHOULD WORK BY ITS OWN...
	***************************************************************************************************/
	struct mzpBuilder
	(
		arrSource = #(),
		arrDestination = #(),
		runIndices = #(),
		dropIndices = #(),
		name = "scriptname",
		description = "A short description of the script",
		version = 0,
		sourcerootpath="",
		buildfilename="",
		buildfilepath="",
		encryptscripts=false,
		encryptIndices = #(),		
		installMessage="None provided",
		license="None provided",
		support="None provided",
		contact="None provided",
		
		function fn_getDataFromIni theIniFile =
		(
			/*<FUNCTION>
			Description:
				Gets all needed data from an ini-file and stores it in a struct.
				Expected structure:
					[Header]
						name=...
						description=...
						version=... (integer)
					[config]
						sourcerootpath=... --the common root of all files which need to be packaged
						buildfilename=... --the filename of the resulting build
						buildfilepath=... --the filepath of the resulting build
						encryptscripts=boolean --encrypts all scripts if set to true. Make sure the script itself is prepared for this
					[Source] source and destination need to have the same amount of entries. Source[1] corresponds with Destination[1] and so on
						1=filename with extension. Path relative to the rootpath entered above
						2=...
					[Destination]
						1=filepath ending with a backslash. This is a path on the machine of the user who executes the mzp
						2=...
					[DropIndices]zero or more indices. Each index matches a source-file. These indexed files are also setup to run in the mzp-file after dropping it into a viewport
						1=...(integer)
						2=...	
					[RunIndices]zero or more indices. Each index matches a source-file. These indexed files are also setup to run in the mzp-file
						1=...(integer)
						2=...
					[About]
						installMessage=... a message which is displayed in a readme-file. This should reduce paranoia when installing an mzp from someone you don't know.
						license=..the license for the script
						support=... contact information for support
						contact=... general contact information
			Arguments:
				<string> theIniFile: the path to the ini-file which contains the data
			Return:
				<struct> an mzpBuilder struct
			</FUNCTION>*/
			
			arrSource = for n in (GetINISetting theIniFile "Source") collect GetINISetting theIniFile "Source" n
			arrDestination = for n in (GetINISetting theIniFile "Destination") collect GetINISetting theIniFile "Destination" n
			sourcerootpath = GetINISetting theIniFile "config" "sourcerootpath"
			buildfilepath = GetINISetting theIniFile "config" "buildfilepath"
			buildfilename = GetINISetting theIniFile "config" "buildfilename"
			runIndices = for n in (GetINISetting theIniFile "RunIndices") collect (GetINISetting theIniFile "RunIndices" n) as integer
			dropIndices = for n in (GetINISetting theIniFile "dropIndices") collect (GetINISetting theIniFile "dropIndices" n) as integer
			encryptIndices = execute (GetINISetting theIniFile "Encrypt" "theArray")
			encryptscripts = GetINISetting theIniFile "Encrypt" "encryptscripts" as booleanclass			
			name = GetINISetting theIniFile "Header" "name"
			description = GetINISetting theIniFile "Header" "description"
			version = (GetINISetting theIniFile "Header" "version") as float
			installMessage = GetINISetting theIniFile "About" "installMessage"
			license = GetINISetting theIniFile "About" "license"
			support = GetINISetting theIniFile "About" "support"
			contact = GetINISetting theIniFile "About" "contact"
			
			--encrypt scritps and change the script-entries if needed
			if encryptscripts do
			(
				for i in encryptIndices where (matchPattern arrSource[i] pattern:"*.ms") do
				(
					encryptScript (sourcerootpath + arrSource[i])
					arrSource[i] = substituteString arrSource[i] ".ms" ".mse"
				)
			)
		),
		
		function fn_writeRunFile mzpBuilderStruct = 
		(
			/*<FUNCTION>
			Description:
				Creates a mzp.run file based on two arrays of strings and some template content
			Arguments:
				<mzpBuilder struct> mzpBuilderStruct: the struct which contains the relevant data bundled in a struct
			Return:
				file on disk
				<string> the path to the mzp.run file
			</FUNCTION>*/
			
			local theRunFilePath = mzpBuilderStruct.sourcerootpath + "mzp.run" --destination path for the run-file
			if doesFileExist theRunFilePath then deleteFile theRunFilePath else makeDir (getFilenamePath  theRunFilePath)--delete old run file if it exists or create the targetdirectory
			
			local theRunFile
			try (theRunFile = createFile theRunFilePath) catch (print "File: " + theRunFilePath + "cannot be created"; return false)
			
			--format the content to the file
			--THE HEADER
			format "name \"%\"\ndescription \"%\"\nversion %\n\n" mzpBuilderStruct.name mzpBuilderStruct.description mzpBuilderStruct.version to:theRunFile 
			--ALL COPY-OPERATIONS
			for i = 1 to mzpBuilderStruct.arrSource.count do format "copy \"%\" to \"%\"\n" mzpBuilderStruct.arrSource[i] mzpBuilderStruct.arrDestination[i] to:theRunFile 
			format "\n" to:theRunFile	
			--ALL DROP-OPERATIONS
			for i in mzpBuilderStruct.dropIndices do format "drop %\n" (mzpBuilderStruct.arrDestination[i] + (filenameFromPath  mzpBuilderStruct.arrSource[i])) to:theRunFile 
			format "\n" to:theRunFile	
			--ALL RUN-OPERATIONS
			for i in mzpBuilderStruct.runIndices do format "run %\n" (mzpBuilderStruct.arrDestination[i] + (filenameFromPath  mzpBuilderStruct.arrSource[i])) to:theRunFile 
			--CLEANING UP
			format "\nclear temp on MAX exit" to:theRunFile
				
			flush theRunFile
			close theRunFile
			
			--return the path to the listfile
			theRunFilePath
		),
		
		function fn_writeReadmeFile mzpBuilderStruct =
		(
			/*<FUNCTION>
			Description:
				Writes a readme file which is created next to the mzp-file. The readme shows similar information as the
				run-file, only human-readable. Also a custom message can be displayed.
			Arguments:
				<mzpBuilder struct> mzpBuilderStruct: the struct which contains the relevant data bundled in a struct
			Return:
				file on disk
				<string> the path to the readme file
			</FUNCTION>*/
			
			local readmeFilePath = mzpBuilderStruct.buildfilepath + "readme.txt" --this is the readme-file we're creating
			if doesFileExist readmeFilePath then deleteFile readmeFilePath else makeDir (getFilenamePath  readmeFilePath)--delete old readme file if it exists or create the targetdirectory
			local readmeFile
			try (readmeFile = createFile readmeFilePath) catch (print "File: " + readmeFilePath + "cannot be created"; return false)
			
			--format the content to the file
			format "Welcome to the readme of the % script. The readme contains a list of the contents of the installer and some instructions on how to install the script.\n" mzpBuilderStruct.buildfilename to:readmeFile
			format "You can install the mzp-file by dropping it onto any viewport, or by running it from the menu: MAXScript>>Run file...\n" to:readmeFile
			format "If you want to check out the contents of the mzp-file yourself, you can unzip it just like a zip-file.\n" to:readmeFile
			format "\nA message from the developer\n\t%\n" mzpBuilderStruct.installMessage to:readmeFile
			format "\tLicense: %\n" mzpBuilderStruct.license to:readmeFile
			format "\tSupport: %\n" mzpBuilderStruct.support to:readmeFile
			format "\tContact: %\n\n" mzpBuilderStruct.contact to:readmeFile
			
			--THE HEADER
			format "name \"%\"\ndescription \"%\"\nversion %\n\n" mzpBuilderStruct.name mzpBuilderStruct.description mzpBuilderStruct.version to:readmeFile 
			--ALL COPY-OPERATIONS
			format "The following files are copied to your system\n" to:readmeFile
			for i = 1 to mzpBuilderStruct.arrSource.count do format "\t% >> %\n" mzpBuilderStruct.arrSource[i] mzpBuilderStruct.arrDestination[i] to:readmeFile 
			format "\n" to:readmeFile	
			--ALL DROP-OPERATIONS
			if mzpBuilderStruct.dropIndices.count > 0 do
			(
				format "If dropped on the viewport, the following scripts are executed\n" to:readmeFile
				for i in mzpBuilderStruct.dropIndices do format "\t%\n" (filenameFromPath  mzpBuilderStruct.arrSource[i]) to:readmeFile 
				format "\n" to:readmeFile	
			)
			--ALL RUN-OPERATIONS
			if mzpBuilderStruct.runIndices.count > 0 do
			(
				format "If executed by the menu: MAXScript>>Run file... the following scripts are executed \n" to:readmeFile
				for i in mzpBuilderStruct.runIndices do format "\t%\n" (filenameFromPath  mzpBuilderStruct.arrSource[i]) to:readmeFile 
				format "\n" to:readmeFile	
			)
				
			flush readmeFile
			close readmeFile
			
			--return the path to the listfile
			readmeFilePath
		),
		
		function fn_makeZipList arrPath rootPath =
		(
			/*<FUNCTION>
			Description:
				Makes a tmp-file which serves as input for the zipping-process.
			Arguments:
				<array> arrPath: An array of filepaths.
				<string> rootPath: the basepath all files from the array share
			Return:
				a file on disk
				<string> the path to the generated file
			</FUNCTION>*/
			
			-- generate a temporary file with the list of files to be archived
			--TODO: check if an alternative folder is an option
			local theZipListPath = "C:/temp/" + "~mzpBuilderZipList.tmp" -- targetPath --need a path without any spaces!!
			if doesFileExist theZipListPath then deleteFile theZipListPath else makeDir (getFilenamePath  theZipListPath)-- delete old tmp file if it exists or create the folder
			
			local theZipList
			try (theZipList = createFile theZipListPath) catch (print "File: " + theZipListPath + "cannot be created"; return false)
			for i in arrPath do format "%\n" (rootPath + i) to:theZipList
			flush theZipList
			close theZipList
			
			--return the path to the listfile
			theZipListPath
		),
		
		function fn_dateStamp =
		(
			/*<FUNCTION>
			Description:
				Create a datestamp string.
			Arguments:
			Return:
				<string> a datestamp YYYY-MM-DD
			</FUNCTION>*/
			
			--a timestamp string
			local arrTime = getLocalTime()
			local theTime = "" as StringStream
			format "%-%-%" arrTime[1] (formattedprint arrTime[2] format:"02d") (formattedprint arrTime[4] format:"02d") to:theTime
			theTime as string
		),
		
		function fn_zipFiles mzpBuilderStruct =
		(
			/*<FUNCTION>
			Description:
				packages files together in a zipfile. Uses the max-native maxzip.exe to perform the zipping.
			Arguments:
				<mzpBuilder struct> mzpBuilderStruct: the struct which contains the relevant data bundled in a struct
			Return:
				<string> the path of the generated zipfile
			</FUNCTION>*/
			
			--create the ziplist. This is the list of files which need to be zipped
			local theTempFilePath = mzpBuilder.fn_makeZipList mzpBuilderStruct.arrSource mzpBuilderStruct.sourcerootpath
			
			local zipUtil = (getDir #maxRoot) + "maxzip.exe" --this is the zip-program. It's shipped with 3dsMax
			
			local zipFilePath = mzpBuilderStruct.buildfilepath + mzpBuilderStruct.buildfilename + "_" + mzpBuilder.fn_dateStamp() + "_" + (mzpBuilderStruct.version as string)+ ".mzp" --this is the zipfile we're creating
			if doesFileExist zipFilePath then deleteFile zipFilePath else makedir mzpBuilderStruct.buildfilepath-- delete old mzp file if it exists or create the folder
			
			--create a commandstring
			local cmd = "" as stringStream
			format "\"%\" \"%\" @%" zipUtil zipFilePath theTempFilePath to:cmd -- thanks to ofer_z--zipFile needs to be a mapped drive?
			
			local curDir = sysInfo.currentDir -- store current system dir
			sysInfo.currentDir = mzpBuilderStruct.sourcerootpath-- set system folder (zip tree begins here)
			(hiddendosCommand cmd exitcode:&exitcode) --EXECUTE THE ZIPPING
			sysInfo.currentDir = curDir -- restore old system dir
			
			--output the code returned by maxzip. For a list of possible codes, check here: http://www.info-zip.org/mans/zip.html#DIAGNOSTICS
			if exitcode == 0 then exitcode = "normal"
			format "zip-status: % \n" exitcode
			
			zipFilePath --return the path of the zipfile
		),
		
		function fn_execute iniPath =
		(
			/*<FUNCTION>
			Description:
				Execute the creation of the mzp-file.
			Arguments:
				<string> iniPath: the path to the ini-file which contains the data
			Return:
				<string> the path to the mzp-file
			</FUNCTION>*/
			
			
			mzpBuilder.fn_getDataFromIni iniPath --get all paths from the external file
			mzpBuilder.fn_writeRunFile mzpBuilder --create an mzp.run file
			local readmePath = mzpBuilder.fn_writeReadmeFile mzpBuilder --create the readme file
			append mzpBuilder.arrSource "mzp.run" --this file needs to be included when zipping
-- 			append mzpBuilder.arrSource (pathConfig.convertPathToRelativeTo readmePathmzpBuilder.sourcerootpath) --the readme also needs to be included when zipping
			mzpBuilder.fn_zipFiles mzpBuilder --create the mzp-file
			
		)
	)

	local mzpBuilder = mzpBuilder() --init the struct
	mzpBuilder.fn_execute theIniFile --create the mzp
)
