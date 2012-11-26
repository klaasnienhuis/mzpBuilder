/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-11-26
Last Updated: 2012-11-26
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	Create mzp-files from a list of files
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	date: change
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

arrPath = #(
	@"Foto klaas uitnodiging.jpg",
	@"Foto klaas uitnodigingWeb.jpg",
	@"IMG_9970_pasfoto.jpg",
	@"IMG_9970_pasfoto_klein.jpg",
 	@"Submapje\Klaas_crop.jpg"
)

--an array of destinations corresponding to the array of paths. These go into the mzp.run file
arrDest = #(
	@"$userScripts\KlaasTools\Sketchfab\",
	@"$userScripts\KlaasTools\Sketchfab\",
	@"$userScripts\KlaasTools\Sketchfab\",
	@"$userScripts\KlaasTools\Sketchfab\",
	@"$userScripts\KlaasTools\Sketchfab\Submapje\"
)

runIndices = #(2,5)

rootPath = @"N:\GitHub\mzpBuilder\Demo_files\"

function fn_writeRunFile arrPath arrDest pathDest runIndices:#() = 
(
	/*<FUNCTION>
	Description:
		Creates a mzp.run file based on two arrays of strings and some template content
	Arguments:
		<array> arrPath: an array of source files
		<array> arrDest: an array of destination paths
		<string> pathDest: the location where the run-file has to go.
		<array> runIndices: an array of integers indicating the files which need to be run (when the mzp is executed that is) besides being copied
	Return:
		<string> the path to the mzp.run file
	</FUNCTION>*/
	
	local theRunFilePath = pathDest + "mzp.run" --destination path
	makeDir (getFilenamePath  theRunFilePath)
	if doesFileExist theRunFilePath do deleteFile theRunFilePath --delete old run file if it exists
	
	local theRunFile
	try (theRunFile = createFile theRunFilePath) catch (print "File: " + theRunFilePath + "cannot be created"; return false)
	
	--format the content to the file
	format "name \"Sketchfab\"\ndescription \"Klaas Nienhuis Scripts\"\nversion 7\n\n" to:theRunFile --the header
	
	for i = 1 to arrPath.count do format "copy \"%\" to \"%\"\n" arrPath[i] arrDest[i] to:theRunFile--(substituteString i sourcePath "") to:theZipList --slice off the common root. Only possible when working from a drive-letter, not a unc-path. Why? Unknown!
		
	for i in runIndices do
	(
		format "run %\n" (arrDest[i] + arrPath[i]) to:theRunFile
	)
	format "\nclear temp on MAX exit" to:theRunFile
	flush theRunFile
	close theRunFile
	
	--return the path to the listfile
	theRunFilePath
)
	
struct zipStruct
(
	--http://forums.cgsociety.org/showthread.php?t=800618
	--based on code by Rene Baca/MerlinEl
	/* Functionality:
	-add files from a folder in to zip
	-add also subfolder files if subdirs sets to true
	-delete old files if deleteOld sets to true */			
	all_dirs = #(),
	all_files = #(),
	
	fn getDirTree dir =
	(
		all_dirs += curr_dirs = getDirectories (dir+"*")
		for i in curr_dirs do getDirTree i
	),
	
	fn getAllFiles dirs =
	(
		for d in dirs do all_files += getFiles (d + "*")
	),
	
	fn deleteOldFiles files =
	(
		for i in files do try deleteFile i catch (format "The file: %\tcannot be deleted.\n" i)
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
		for i in arrPath do format "%\n" (rootPath + i) to:theZipList--(substituteString i sourcePath "") to:theZipList --slice off the common root. Only possible when working from a drive-letter, not a unc-path. Why? Unknown!
		flush theZipList
		close theZipList
		
		--return the path to the listfile
		theZipListPath
	),
	
	function fn_zipFiles rootPath: sourcePath: targetPath: zipName: useSubdirs:true deleteOld:false arrPath:#() =
	(
		/*<FUNCTION>
		Description:
			packages files together in a zipfile. Uses the max-native maxzip.exe to perform the zipping.
		Arguments:
			<string> rootPath: this is the root of the files which need to be zipped. Zipfile will include subfolders leading up to the zipped files if needed.
			<string> sourcePath: the path to the folder from which the contents needs to be zipped
			<string> targetPath: the folder where the zipfile has to be stored
			<string> zipName: the name of the zipfile
		Return:
			<string> the path of the generated zipfile
		</FUNCTION>*/
		
/* 		--reset the file and dir-containers
		all_files = #()
		all_dirs = #()
		
		--error check to see if the specified path exists
		if not doesFileExist sourcePath or not doesFileExist targetPath do return false
			
		--collecting files with full path
		all_files = getFiles (sourcePath + "*")   -- root dir files
		if useSubdirs do --also collect files from subdirs, recursively
		(
			getDirTree sourcePath --collect all subdirs in dir in to local all_dirs
			if all_dirs.count != 0 do getAllFiles all_dirs -- collect files from subdirs
		)
		print all_files
		format "Number of files: %\n" all_files.count
		
		if all_files.count == 0 do return false
 */		

		
		all_files = arrPath
		
		--create the ziplist. This is the list of files which need to be zipped
		local theTempFilePath = fn_makeZipList all_files rootPath
		
		local zipUtil = (getDir #maxRoot) + "maxzip.exe" --this is the zip-program. It's shipped with 3dsMax
		local zipFilePath = targetPath + zipName + ".zip" --this is the zipfile we're creating
		
		--create a commandstring
		local cmd = "" as stringStream
		format "\"%\" \"%\" @%" zipUtil zipFilePath theTempFilePath to:cmd -- thanks to ofer_z--zipFile needs to be a mapped drive?
		
		local curDir = sysInfo.currentDir -- store current system dir
		sysInfo.currentDir = rootPath-- set system folder (zip tree begins here)
		(hiddendosCommand cmd exitcode:&exitcode) --EXECUTE THE ZIPPING
		sysInfo.currentDir = curDir -- restore old system dir

		--delete old files if is true
		if deleteOld do deleteOldFiles all_files
		
		--output the code returned by maxzip. For a list of possible codes, check here: http://www.info-zip.org/mans/zip.html#DIAGNOSTICS
		if exitcode == 0 then exitcode = "normal"
		format "zip-status: % \n" exitcode
		
		zipFilePath --return the path of the zipfile
	)
)

zipStruct = zipStruct()
zipStruct.fn_zipFiles rootPath:rootPath targetPath:@"N:\GitHub\mzpBuilder\Demo_files\" zipName:"Bingo" arrPath:arrPath

fn_writeRunFile arrPath arrDest rootPath runIndices:runIndices