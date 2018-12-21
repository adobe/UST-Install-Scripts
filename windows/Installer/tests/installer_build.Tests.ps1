. "..\..\build.ps1"
Clear-Host
function Cleanup {
	try{ Remove-Item "directory with spaces" -Force -Recurse } catch {}
}

function Reset-Files(){	
		Cleanup		
		New-Item -Path ".\directory with spaces" -ItemType Directory -Force | Out-Null
		Copy-Item ".\testfiles\tar_file.tar.gz" ".\directory with spaces"
		Copy-Item ".\testfiles\zipped_file.zip" ".\directory with spaces"
}

function Compare-Hashtables($tableA,$tableB){
	try {
		foreach ($key in $tableA.Keys){		

			if ($tableA[$key].GetType() -eq [System.Collections.Hashtable]){
				return Compare-Hashtables $tableA[$key] $tableB[$key]			
			} else {
				if (!($tableA[$key] -eq $tableB[$key])){
					return $false
				}			
			}	 
		}
		return $true
	} catch {
		return $false
	}
}

$zipfile = "directory with spaces\zipped_file.zip"
$tarfile = "directory with spaces\tar_file.tar.gz"
$badfile = "directory with spaces\bad.zip.gz"
$outputDir = "directory with spaces"

$options['7zPath'] = '..\files\7zip\7z.exe'

Describe "Test Fetch Configurations" {		

	It "Tests api call and parser" {
		Reset-Files	
		$options['ust_version'] = "latest"

		$testSet = @{
			'USTVersion' = 'v2.3'
			'GUILink' = 'https://github.com/adobe/ust-configapp/releases/download/v1.0.3/Adobe.UST.Configuration.App.exe'
			'GUIVersion' = 'v1.0.3'
			'ExamplesLink' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/example-configurations.tar.gz'
			'Binaries' = @{
				'2.7' = @{'PythonLink' = 'https://www.python.org/ftp/python/2.7.15/python-2.7.15.amd64.msi'
						'USTLink' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-win64-py2715.tar.gz'}
				'3.6' = @{'PythonLink' = 'https://www.python.org/ftp/python/3.6.5/python-3.6.5-amd64.exe'
						'USTLink' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-win64-py365.tar.gz'}
			}			
		}		
			
		(Compare-Hashtables $testSet (Fetch)) | Should Be $true
	}
}

Describe "Test Fetch Old Configurations" {	
	Reset-Files	
	$options['ust_version'] = '2.0rc1'

	It "Old / no py or examples" {		

		$testSet = @{
			'USTVersion' = 'v2.0rc1'
			'GUILink' = 'https://github.com/adobe/ust-configapp/releases/download/v1.0.3/Adobe.UST.Configuration.App.exe'
			'GUIVersion' = 'v1.0.3'
			'ExamplesLink' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.0/example-configurations.tar.gz'
			'Binaries' = @{
				'2.7' = @{'PythonLink' = 'https://www.python.org/ftp/python/2.7.15/python-2.7.15.amd64.msi'
						'USTLink' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.0rc1/user-sync-2.0rc1-windows.tar.gz'}
			}			
		}

		(Compare-Hashtables $testSet (Fetch)) | Should Be $true
	}
}

Describe "Test Failuers" { 	
	Reset-Files	
	It "UST Data failed fetch" {		
		$options['uri_ust'] = "http://google.com"
		{ Fetch } | Should Throw
	}

	It "CFG Data failed fetch" {		
		$options['uri_cfg']  = "http://google.com"
		{ Fetch } | Should Throw
	}
}

Describe "Test Archive Extraction" {

	It "Test extracting an archive via multi" {
		Reset-Files

		ExpandArchive $zipfile $outputDir		
		"$outputDir\zipped_file.txt" | Should -Exist

		ExpandArchive $tarfile $outputDir
		"$outputDir\tar_file.txt" | Should -Exist

		try {
			ExpandArchive $badfile $outputDir
			Throw "Test should have thrown exception"
		} catch [System.FormatException]{
			# Pass
		}
    }
}

Describe "Test get resource"{	

	It "Tests resource downloading" {

		Reset-Files
		$ExamplesLink = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/example-configurations.tar.gz"
		$NonZip = "https://github.com/adobe/UST-Install-Scripts/blob/release/README.md"	

		GetResource $ExamplesLink $outputDir
		GetResource $NonZip $outputDir

		"$outputDir\examples" | Should -Exist
		"$outputDir\examples\config files - basic" | Should -Exist
		"$outputDir\README.md" | Should -Exist
	}
}

Describe "Remove All" { It "Cleans up" { Cleanup } }

