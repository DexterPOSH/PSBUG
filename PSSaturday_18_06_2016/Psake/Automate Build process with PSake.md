## Automate Build process with PSake
#### Notes from the PluralSight PowerShell course by Jim Christopher.

Build process starts out simple but can grow complex as the project progresses on.
For Example - Writing a PowerShell module, after some time you start putting unit tests & integration tests which should not make it to the artifacts uploaded to a PowerShell/Nuget repo.

Psake simplifies the build process by breaking it into tasks.
- inspired by rake (ruby build system), hence we know this will be simpler and awesome to use.
- differs from complicated build systems like MSbuild

Psake pronounced as 'sake' (as in the Japanese rice wine)

Install Psake
- discover Psake on the PowerShell gallery
```PowerShell
Find-Module -name Psake
```
- install Psake from the gallery
```PowerShell
Install-Module -name Psake -Scope CurrentUser -Verbose
```

## Tasks 

Build Script - comprises of tasks, which are an atomic unit of work done during the build process.

### Task formats :
```PowerShell
task -name Task1  -Action {
	# PowerShell script block used as an action for the task.
}
```

 A task may depend on other tasks, which is specified in below way:

```PowerShell
task -name Task2 -depends Task1 -Action { }
```

**Note each Psake build script must define a default task (with not action block) which should depend on one or more tasks defined in the build script.**

Invoke-Psake used to invoke the build script, by default it assumes that the build script is in current directory named default.ps1 and the default task is default.

One can specify different build script and task while calling invoke-Psake function. Note the depends task are run in order specified in the depends parameter for the task.

- Each Psake task will be run at most once during a build.
- Task execution order depends on -
	1. tasks passed in order to Invoke-Psake function
	2. tasks dependency tree specified in the build script.
	
## Building Visual Studio Projects

Below is an example of Psake script to automate build process for VS projects

```PowerShell
#buildproject.ps1
# psake script to build VS projects

task -Name Build -Description 'Builds artifacts' -action {
	# delegate task to msbuild here
	exec {
		msbuild.exe ./VSProject/VSProject.sln /t:Build
	}
}

task -Name Clean -Description 'Clean artifacts' -action {
	# delegate task to msbuild here
	exec {
		msbuild.exe ./VSProject/VSProject.sln /t:Clean
	}
}

task -Name Rebuild -Description 'Rebuilds artifacts, first cleans then builds.' -Depends Clean,Build
task -Name Default -Depends Build
```

Note that call to each msbuild is wrapped around Exec {}, Exec is a helper to run command line programs and can validate those programs succeeded.
General usage syntax is :

```PowerShell
	exec -Cmd {msbuild ./VSProject.sln}
```

## PackageZip Build Task
- Create a Zip archive of the project output.
- Add tasks to a Psake build.
- Extend the build using available PowerShell modules & features.

```PowerShell
#buildproject.ps1
# psake script to build VS projects

task -Name PackageZip -Description 'produces a zip archive of the build output' -Depends Build -Action {
	import-Module -name PSCX
	Get-ChildItem ./VSProject/bin/Debug | Write-Zip -Output	VSPorject.zip
}

task -Name Build -Description 'Builds artifacts' -action {
	# delegate task to msbuild here
	exec {
		msbuild.exe ./VSProject/VSProject.sln /t:Build
	}
}

task -Name Clean -Description 'Clean artifacts' -action {
	# delegate task to msbuild here
	exec {
		msbuild.exe ./VSProject/VSProject.sln /t:Clean
	}
}

task -Name Rebuild -Description 'Rebuilds artifacts, first cleans then builds.' -Depends Clean,Build
task -Name Default -Depends Build
```

## Configuring the Build
- Add a configurable property to the build script using the properties of the Psake statement.
- Modify existing build tasks to use the new property.
- Specify values for the new property at runtime.
- Use the Psake Assert statement to provide checkpoints during the build process.


```PowerShell
#buildproject.ps1
# psake script to build VS projects

properties {
	$config = 'debug'; # debug or release
}

task -Name PackageZip -Description 'produces a zip archive of the build output' -Depends Build -Action {
	import-Module -name PSCX
	Get-ChildItem ./VSProject/bin/$config | Write-Zip -Output	VSPorject.zip
}

task -Name Build -Description 'Builds artifacts' -action {
	# delegate task to msbuild here
	exec {
		msbuild.exe ./VSProject/VSProject.sln /t:Build /p:Configuration=$config
	}
}

task -Name Clean -Description 'Clean artifacts' -action {
	# delegate task to msbuild here
	exec {
		msbuild.exe ./VSProject/VSProject.sln /t:Clean
	}
}

task -Name Rebuild -Description 'Rebuilds artifacts, first cleans then builds.' -Depends Clean,Build
task -Name Default -Depends Build
```

Now to specify a different property at runtime, invoke psake using below syntax:
```PowerShell
Invoke-Psake -BuildFile ./VSProject.ps1 -properties @{'Config'='Release'}
```


There is a issue with the above build script, if someone invokes the Psake like below with wrong config value.
```PowerShell
Invoke-Psake -BuildFile ./VSProject.ps1 -properties @{'Config'='Unknown'}
```

So we will put assert statment inside the build script.


```PowerShell
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
```


## Psake inside a CI Server.

Make these changes before using psake inside a CI server :

```PowerShell
Import-Module -Name Psake
$psake.use_exit_on_error = $True # this allows psake to interact with CI build steps.
Invoke-Psake -BuildFile ./VSPorject.ps1

```


# testing Psake with local Git hooks.

## pre-commit

The below one does not work in the pre-commit as the current location is set to the User's PowerShell (e.g C:\Users\Deepak_Dhami\Documents\WindowsPowerShell) directory when using powershell.exe -command parameter

```PowerShell
exec powershell.exe -ExecutionPolicy Bypass -Command  'Import-Module -Name Psake -ErrorAction Stop; 
$psake.use_exit_on_error = $True ; Get-location;
Invoke-Psake -BuildFile .\pre-commit-hook.ps1; exit 99'
```

Below works

```
exec powershell.exe -ExecutionPolicy Bypass -File '.\.git\hooks\pre-commit-hook.ps1'
```
Now the pre-commit-hook.ps1 will call the psake module and use default.ps1 as the build file.

Contents of the pre-commit-hook.ps1 file. Note that need to enter the hooks directory.

```
Write-Host -Object 'Pre-Commit-Hook.ps1'
Import-Module -Name Psake -ErrorAction Stop; 
$psake.use_exit_on_error = $True ; 
Set-location -Path .\Git\Hooks;
Write-Host -Object '<Pre-Commit-Hook.ps1> - calling Invoke-Psake'
TRY {
    Invoke-Psake # trigger the dfault.ps1
}
CATCH {
    $PSitem | Format-List -Property * -Force
    exit 12
}
```

