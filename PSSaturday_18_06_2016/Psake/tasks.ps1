#buildproject.ps1
# psake script to build VS projects

properties {
	$config = 'debug'; # debug or release
}
task -name validateConfig -Action {
	assert ('debug','release' -contains $config) "Invalid Config: $Config, Valid values are debug and release"
}

task -Name PackageZip -Description 'produces a zip archive of the build output' -Depends Build -Action {
	import-Module -name PSCX
	Get-ChildItem ./VSProject/bin/$config | Write-Zip -Output	VSPorject.zip
}

task -Name Build -Depends validateConfig -Description 'Builds artifacts' -action {
	# delegate task to msbuild here
	exec {
		msbuild.exe ./VSProject/VSProject.sln /t:Build /p:Configuration=$config
	}
}

task -Name Clean -Depends validateConfig -Description 'Clean artifacts' -action {
	# delegate task to msbuild here
	exec {
		msbuild.exe ./VSProject/VSProject.sln /t:Clean
	}
}

task -Name Rebuild -Description 'Rebuilds artifacts, first cleans then builds.' -Depends Clean,Build
task -Name Default -Depends Build