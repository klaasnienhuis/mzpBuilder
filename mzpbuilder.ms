/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-11-26
Last Updated: 2012-11-26
Version: 1

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	Create mzp-files from a list of files
Usage:
	specifiy a list of files and a list of destinations and run the script to create an mzp-file from it

Features:

Wishlist:
Changelog:
	2012-11-26: first setup, used the zip-methods from teh sketchfab script
	2012-11-26: added fn_writeRunFile method to write a runfile
	2012-11-27: added mzpBuilder struct to hold data and retrieve it from an ini-file
	2012-11-27: refactoring. Combined all methods in a single struct. Moved more settings to the ini-file
</SCRIPTFILE>
*******************************************************************************************************/

/*
Script Outline

	compile scripts, art and other files to a maxscript mzp-file

	specify paths of the needed files
	create a mzp.run-file
	enter the correct commands in the mzp.run file
	zip the files
	rename the zip extension to mzp
*/

struct mzpBuilder
(
	arrSource = #(),
	arrDestination = #(),
	rootpath = "",
	targetPath = "",
	zipName = "",
	runIndices = #(),
	name = "scriptname",
	description = "A short description of the script",
	version = 0,
	
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
		Arguments:
			<string> theIniFile: the path to the ini-file which contains the data
		Return:
			<struct> an mzpBuilder struct
		</FUNCTION>*/
		
		arrSource = for n in (GetINISetting theIniFile "Source") collect GetINISetting theIniFile "Source" n
		arrDestination = for n in (GetINISetting theIniFile "Destination") collect GetINISetting theIniFile "Destination" n
		rootpath = GetINISetting theIniFile "root" "rootpath"
		targetpath = GetINISetting theIniFile "Mzp" "targetpath"
		zipName = GetINISetting theIniFile "Mzp" "name"
		runIndices = for n in (GetINISetting theIniFile "RunIndices") collect (GetINISetting theIniFile "RunIndices" n) as integer
		name = GetINISetting theIniFile "Header" "name"
		description = GetINISetting theIniFile "Header" "description"
		version = (GetINISetting theIniFile "Header" "version") as integer
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
		
		local theRunFilePath = mzpBuilderStruct.rootPath + "mzp.run" --destination path
		makeDir (getFilenamePath  theRunFilePath)
		if doesFileExist theRunFilePath do deleteFile theRunFilePath --delete old run file if it exists
		
		local theRunFile
		try (theRunFile = createFile theRunFilePath) catch (print "File: " + theRunFilePath + "cannot be created"; return false)
		
		--format the content to the file
		format "name \"%\"\ndescription \"%\"\nversion %\n\n" mzpBuilderStruct.name mzpBuilderStruct.description mzpBuilderStruct.version to:theRunFile --the header
		
		for i = 1 to mzpBuilderStruct.arrSource.count do format "copy \"%\" to \"%\"\n" mzpBuilderStruct.arrSource[i] mzpBuilderStruct.arrDestination[i] to:theRunFile --all copy-operations
		format "\n" to:theRunFile	
		for i in mzpBuilderStruct.runIndices do format "run %\n" (mzpBuilderStruct.arrDestination[i] + (filenameFromPath  mzpBuilderStruct.arrSource[i])) to:theRunFile --all run-operations
			
		format "\nclear temp on MAX exit" to:theRunFile
		flush theRunFile
		close theRunFile
		
		--return the path to the listfile
		theRunFilePath
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
		makeDir (getFilenamePath  theZipListPath)
		if doesFileExist theZipListPath do deleteFile theZipListPath -- delete old tmp file if exist
		
		local theZipList
		try (theZipList = createFile theZipListPath) catch (print "File: " + theZipListPath + "cannot be created"; return false)
		for i in arrPath do format "%\n" (rootPath + i) to:theZipList
		flush theZipList
		close theZipList
		
		--return the path to the listfile
		theZipListPath
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
		local theTempFilePath = mzpBuilder.fn_makeZipList mzpBuilderStruct.arrSource mzpBuilderStruct.rootPath
		
		local zipUtil = (getDir #maxRoot) + "maxzip.exe" --this is the zip-program. It's shipped with 3dsMax
		local zipFilePath = mzpBuilderStruct.targetPath + mzpBuilderStruct.zipName + ".mzp" --this is the zipfile we're creating
		
		--create a commandstring
		local cmd = "" as stringStream
		format "\"%\" \"%\" @%" zipUtil zipFilePath theTempFilePath to:cmd -- thanks to ofer_z--zipFile needs to be a mapped drive?
		
		local curDir = sysInfo.currentDir -- store current system dir
		sysInfo.currentDir = mzpBuilderStruct.rootPath-- set system folder (zip tree begins here)
		(hiddendosCommand cmd exitcode:&exitcode) --EXECUTE THE ZIPPING
		sysInfo.currentDir = curDir -- restore old system dir
		
		--output the code returned by maxzip. For a list of possible codes, check here: http://www.info-zip.org/mans/zip.html#DIAGNOSTICS
		if exitcode == 0 then exitcode = "normal"
		format "zip-status: % \n" exitcode
		
		zipFilePath --return the path of the zipfile
	)	
)

(
	mzpBuilder = mzpBuilder() --init the struct
	mzpBuilder.fn_getDataFromIni @"N:\GitHub\mzpBuilder\mzpbuilder_list.ini" --get all paths from the external file
	mzpBuilder.fn_writeRunFile mzpBuilder --create an mzp.run file
	append mzpBuilder.arrSource "mzp.run" --this file needs to be included when zipping
	mzpBuilder.fn_zipFiles mzpBuilder --create the mzp-file
)
