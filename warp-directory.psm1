# Warp Directory PowerShell Module

function Get-WarpConfigPath {
    return "$HOME\.warprc"
}

function Get-WarpPoints {
    if (-Not (Test-Path (Get-WarpConfigPath))) { return @{} }
    $warpPoints = @{}
    Get-Content (Get-WarpConfigPath) | ForEach-Object {
        $parts = $_ -split ":", 2
        if ($parts.Count -eq 2) {
            $warpPoints[$parts[0]] = $parts[1]
        }
    }
    return $warpPoints
}

function Save-WarpPoints {
    param([hashtable]$WarpPoints)
    $WarpPoints.GetEnumerator() | ForEach-Object { "$($_.Key):$($_.Value)" } | 
    Set-Content (Get-WarpConfigPath)
}

function Set-Warp {
    param([string]$Name)

    $warpPoints = Get-WarpPoints
    if ($warpPoints.ContainsKey($Name)) {
        $targetDir = $warpPoints[$Name]
        if (Test-Path $targetDir -PathType Container) {
            Set-Location $targetDir
        } else {
            Write-Host "Error: Directory '$targetDir' does not exist." -ForegroundColor Red
        }
    } else {
        Write-Host "Warp point '$Name' not found." -ForegroundColor Red
    }
}

function New-Warp {
    param(
        [string]$Name,
        [string]$Directory = (Get-Location).Path
    )

    if (-Not $Name) { $Name = Split-Path -Leaf $Directory }

    if ($Name -match ":") {
        Write-Host "Error: Warp name cannot contain ':'" -ForegroundColor Red
        return
    }

    if (-Not (Test-Path $Directory -PathType Container)) {
        Write-Host "Error: Directory does not exist." -ForegroundColor Red
        return
    }

    $warpPoints = Get-WarpPoints
    $warpPoints[$Name] = $Directory
    Save-WarpPoints $warpPoints
    Write-Host "Warp point '$Name' added for '$Directory'" -ForegroundColor Green
}

function Get-Warps {
    $warpPoints = Get-WarpPoints
    if ($warpPoints.Count -eq 0) {
        Write-Host "No warp points found." -ForegroundColor Yellow
        return
    }

    $maxLength = ($warpPoints.Keys | Measure-Object -Property Length -Maximum).Maximum

    $warpPoints.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $name = $_.Key.PadRight($maxLength)
        Write-Host -NoNewline ($name)
        Write-Host -NoNewline " -> " -ForegroundColor DarkGray
        Write-Host $_.Value 
    }
}

function Get-WarpPath {
    param([string]$Name)

    $warpPoints = Get-WarpPoints
    if ($warpPoints.ContainsKey($Name)) {
        Write-Output $warpPoints[$Name]
    } else {
        Write-Host "Warp point '$Name' not found." -ForegroundColor Red
    }
}

function Get-WarpsForCurrentDir {
    $currentDir = (Get-Location).Path
    $warpPoints = Get-WarpPoints
    $matches = $warpPoints.GetEnumerator() | Where-Object { $_.Value -eq $currentDir }

    if ($matches.Count -eq 0) {
        Write-Host "No warp points found for the current directory." -ForegroundColor Yellow
    } else {
        $matches | ForEach-Object { Write-Host "$($_.Key) -> $($_.Value)" }
    }
}

function Remove-Warp {
    param([string]$Name)

    $warpPoints = Get-WarpPoints
    if ($warpPoints.ContainsKey($Name)) {
        $warpPoints.Remove($Name)
        Save-WarpPoints $warpPoints
        Write-Host "Warp point '$Name' removed." -ForegroundColor Green
    } else {
        Write-Host "Warp point '$Name' not found." -ForegroundColor Red
    }
}

function Clear-Warps {
    param([switch]$Force)

    $warpPoints = Get-WarpPoints
    $invalidWarps = $warpPoints.Keys | Where-Object { -Not (Test-Path $warpPoints[$_]) }

    if (-Not $invalidWarps) {
        Write-Host "No invalid warp points found." -ForegroundColor Green
        return
    }

    if (-Not $Force) {
        Write-Host "Invalid warp points:" -ForegroundColor Yellow
        $invalidWarps | ForEach-Object { Write-Host $_ }
        if ((Read-Host "Remove them? (y/n)") -ne "y") { return }
    }

    foreach ($warp in $invalidWarps) { $warpPoints.Remove($warp) }
    Save-WarpPoints $warpPoints
    Write-Host "Invalid warp points removed." -ForegroundColor Green
}

function Get-WarpFiles {
    param([string]$Name)

    $warpPoints = Get-WarpPoints
    if ($warpPoints.ContainsKey($Name)) {
        Get-ChildItem $warpPoints[$Name]
    } else {
        Write-Host "Warp point '$Name' not found." -ForegroundColor Red
    }
}

function Show-Help {
    Write-Host "Warp Directory CLI - PowerShell Edition"
    Write-Host "Usage: wd <command> [options]"
    Write-Host "Commands:"
    Write-Host "  <warp-name>         Warp to the specified directory"
    Write-Host "  add <name>          Add current directory as warp point"
    Write-Host "  addcd <dir> [name]  Add warp point for specific directory"
    Write-Host "  rm <name>           Remove warp point"
    Write-Host "  list                List all warp points"
    Write-Host "  ls <name>           List files in given warp point"
    Write-Host "  path <name>         Show path of given warp point"
    Write-Host "  show                List warp points for the current directory"
    Write-Host "  clean [--force]     Remove warp points to non-existent directories"
    Write-Host "  --version           Show version information"
}

function wd {
    param(
        [string]$Command,
        [string]$Arg1,
        [string]$Arg2
    )

    $warpPoints = Get-WarpPoints

    switch ($Command) {
        "add" { if ($Arg1) { New-Warp -Name $Arg1 } else { Write-Host "Error: Missing warp name." -ForegroundColor Red } }
        "addcd" { if ($Arg1) { New-Warp -Directory $Arg1 -Name $(if ($Arg2 -and $Arg2 -ne '') { $Arg2 } else { Split-Path -Leaf $Arg1 }) } else { Write-Host "Error: Missing directory path." -ForegroundColor Red } }
        "rm" { if ($Arg1) { Remove-Warp -Name $Arg1 } else { Write-Host "Error: Missing warp name." -ForegroundColor Red } }
        "list" { Get-Warps }
        "ls" { if ($Arg1) { Get-WarpFiles -Name $Arg1 } else { Write-Host "Error: Missing warp name." -ForegroundColor Red } }
        "path" { if ($Arg1) { Get-WarpPath -Name $Arg1 } else { Write-Host "Error: Missing warp name." -ForegroundColor Red } }
        "show" { Get-WarpsForCurrentDir }
        "clean" { if ($Arg1 -eq "--force") { Clear-Warps -Force } else { Clear-Warps } }
        "--version" { Write-Host "Warp Directory CLI v1.0" }
        default { 
            if (-Not $Command) { Show-Help }
            elseif ($warpPoints.ContainsKey($Command)) { Set-Warp -Name $Command }
            else { Write-Host "Unknown command: $Command" -ForegroundColor Red; Show-Help }
        }
    }
}

Export-ModuleMember -Function New-Warp, Remove-Warp, Get-Warps, Get-WarpFiles, Get-WarpPath, Get-WarpsForCurrentDir, Clear-Warps, Set-Warp, Show-Help, wd
