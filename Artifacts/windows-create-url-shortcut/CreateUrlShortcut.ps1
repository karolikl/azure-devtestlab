<##################################################################################################

    Description
    ===========

    - This script creates a .url (web) shortcut according to user's specifications. 

    - The following logs are generated on the machine - 
        - This script's log : $PSScriptRoot\url-shortcut-creator folder.


    Prerequisite
    ============

    - Ensure that the powershell execution policy is set to unrestricted or bypass.

    - Ensure that powershell is run elevated.


    Known issues / Caveats
    ======================
    
    - No known issues.


    Coming soon / planned work
    ==========================
    
    - N/A.

##################################################################################################>

#
# Optional arguments to this script file.
#

Param(
    # 
    [ValidateNotNullOrEmpty()]
    $ShortcutName,

    # 
    [ValidateNotNullOrEmpty()]
    $ShortcutTargetPath
)

##################################################################################################

#
# Powershell Configurations
#

# Note: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.  
$ErrorActionPreference = "stop"

Enable-PSRemoting –Force -SkipNetworkProfileCheck

# Ensure that current process can run scripts. 
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force 

###################################################################################################

#
# Custom Configurations
#

# Location of the log files
$ShortcutCreatorFolder = Join-Path $PSScriptRoot -ChildPath $("Url-Shortcut-Creator-" + [System.DateTime]::Now.ToString("yyyy-MM-dd-HH-mm-ss"))
$ScriptLogFolder = Join-Path -Path $ShortcutCreatorFolder -ChildPath "Logs"
$ScriptLog = Join-Path -Path $ScriptLogFolder -ChildPath "ShortcutCreator.log"

##################################################################################################

# 
# Description:
#  - Displays the script argument values (default or user-supplied).
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - Please ensure that the Initialize() method has been called at least once before this 
#    method. Else this method can only write to console and not to log files. 
#

function DisplayArgValues
{
    WriteLog "========== Configuration =========="
    WriteLog $("ShortcutName : " + $ShortcutName)
    WriteLog $("ShortcutTargetPath : " + $ShortcutTargetPath) 
    WriteLog "========== Configuration =========="
}

##################################################################################################

# 
# Description:
#  - Creates the folder structure which'll be used for dumping logs generated by this script and
#    the logon task.
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function InitializeFolders
{
    if ($false -eq (Test-Path -Path $ShortcutCreatorFolder))
    {
        New-Item -Path $ShortcutCreatorFolder -ItemType directory | Out-Null
    }

    if ($false -eq (Test-Path -Path $ScriptLogFolder))
    {
        New-Item -Path $ScriptLogFolder -ItemType directory | Out-Null
    }
}

##################################################################################################

# 
# Description:
#  - Writes specified string to the script log (indicated by $ScriptLog).
#
# Parameters:
#  - $message: The string to write.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function WriteLog
{
    Param(
        <# Can be null or empty #> $message
    )

    $timestampedMessage = $("[" + [System.DateTime]::Now + "] " + $message) | % {
        Out-File -InputObject $_ -FilePath $ScriptLog -Append
    }
}

##################################################################################################

#
#
#

try
{
    #
    InitializeFolders

    #
    DisplayArgValues
    
    # some pre-condition checks
    if ([string]::IsNullOrEmpty($ShortcutName))
    {
        $errMsg = $("Error! The shortcut name has not been specified.")
        WriteLog $errMsg
        Write-Error $errMsg 
    }
    if ([string]::IsNullOrEmpty($ShortcutTargetPath))
    {
        $errMsg = $("Error! The shortcut targetpath has not been specified.")
        WriteLog $errMsg
        Write-Error $errMsg 
    }

    # now prep the shortcut 
    $newShortcutPath = $([System.Environment]::GetFolderPath("CommonDesktopDirectory") + "\" + $ShortcutName + ".url")
            
    # create the shortcut only if one doesn't already exist.
    if ($false -eq (Test-Path -Path $newShortcutPath))
    {
        # create the wshshell obhect
        $shell = New-Object -ComObject wscript.shell
        
        $newShortcut = $shell.CreateShortcut($newShortcutPath)
        $newShortcut.TargetPath = $ShortcutTargetPath

        # save the shortcut
        WriteLog "Creating specified shortcut..."
        WriteLog $("Shortcut file: '" + $newShortcutPath + "'")
        WriteLog $("Shortcut targetpath: '" + $newShortcut.TargetPath + "'")

        $newShortcut.Save()

        WriteLog "Success."
    }
    else
    {
        WriteLog $("Specified shortcut already exists: '" + $newShortcutPath + "'")
    }
}
catch
{
    if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message))
    {
        $errMsg = $Error[0].Exception.Message
        WriteLog $errMsg
        Write-Host $errMsg
    }

    # Important note: Throwing a terminating error (using $ErrorActionPreference = "stop") still returns exit 
    # code zero from the powershell script. The workaround is to use try/catch blocks and return a non-zero 
    # exit code from the catch block. 
    exit -1
}
