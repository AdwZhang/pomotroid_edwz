<#
.SYNOPSIS
    Pomotroid automated build script
.DESCRIPTION
    Check environment (Node.js 22+, Rust stable), install if missing,
    verify again, then run npm install + tauri build.
#>

param(
    [switch]$SkipInstall,
    [switch]$Dev
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$MinNodeMajor = 22

# ============================================================
# Utility functions
# ============================================================

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
}

function Test-Command {
    param([string]$Name)
    $null = Get-Command $Name -ErrorAction SilentlyContinue
    return $?
}

function Get-NodeMajorVersion {
    try {
        $ver = & node --version 2>$null
        if ($ver -match '^v(\d+)') {
            return [int]$Matches[1]
        }
    } catch { }
    return 0
}

function Get-RustVersion {
    try {
        $ver = & rustc --version 2>$null
        if ($ver -match 'rustc (\d+\.\d+\.\d+)') {
            return $Matches[1]
        }
    } catch { }
    return $null
}

function Get-CargoVersion {
    try {
        $ver = & cargo --version 2>$null
        if ($ver -match 'cargo (\d+\.\d+\.\d+)') {
            return $Matches[1]
        }
    } catch { }
    return $null
}

# ============================================================
# Environment check
# ============================================================

function Test-Environment {
    $result = @{ Node = $false; Rust = $false; Cargo = $false }

    if (Test-Command "node") {
        $major = Get-NodeMajorVersion
        if ($major -ge $MinNodeMajor) {
            Write-Ok "Node.js v$major (>= $MinNodeMajor)"
            $result.Node = $true
        } else {
            Write-Warn "Node.js v$major too old, need >= $MinNodeMajor"
        }
    } else {
        Write-Warn "Node.js not found"
    }

    if (Test-Command "rustc") {
        $rustVer = Get-RustVersion
        Write-Ok "Rust $rustVer"
        $result.Rust = $true
    } else {
        Write-Warn "Rust (rustc) not found"
    }

    if (Test-Command "cargo") {
        $cargoVer = Get-CargoVersion
        Write-Ok "Cargo $cargoVer"
        $result.Cargo = $true
    } else {
        Write-Warn "Cargo not found"
    }

    return $result
}

# ============================================================
# Auto install
# ============================================================

function Install-NodeJS {
    Write-Step "Attempting to install Node.js..."

    if (Test-Command "winget") {
        Write-Host "  Using winget to install Node.js LTS..." -ForegroundColor Gray
        & winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Node.js installed via winget"
            return $true
        }
    }

    if (Test-Command "fnm") {
        Write-Host "  Using fnm to install Node.js 22..." -ForegroundColor Gray
        & fnm install 22
        & fnm use 22
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Node.js installed via fnm"
            return $true
        }
    }

    if (Test-Command "nvm") {
        Write-Host "  Using nvm to install Node.js 22..." -ForegroundColor Gray
        & nvm install 22
        & nvm use 22
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Node.js installed via nvm"
            return $true
        }
    }

    Write-Fail "Cannot auto-install Node.js. Please install manually: https://nodejs.org/"
    return $false
}

function Install-Rust {
    Write-Step "Attempting to install Rust..."

    if (Test-Command "winget") {
        Write-Host "  Using winget to install Rustup..." -ForegroundColor Gray
        & winget install Rustlang.Rustup --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Rust installed via winget"
            return $true
        }
    }

    $rustupUrl = "https://win.rustup.rs/x86_64"
    $rustupExe = Join-Path $env:TEMP "rustup-init.exe"

    Write-Host "  Downloading rustup-init.exe..." -ForegroundColor Gray
    try {
        Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupExe -UseBasicParsing
        Write-Host "  Running rustup-init (default install)..." -ForegroundColor Gray
        & $rustupExe -y
        if ($LASTEXITCODE -eq 0) {
            $cargobin = Join-Path $env:USERPROFILE ".cargo\bin"
            if (Test-Path $cargobin) {
                $env:PATH = "$cargobin;$env:PATH"
            }
            Write-Ok "Rust installed via rustup-init"
            return $true
        }
    } catch {
        Write-Fail "Failed to download rustup-init: $_"
    }

    Write-Fail "Cannot auto-install Rust. Please install manually: https://rustup.rs/"
    return $false
}

# ============================================================
# Refresh PATH after install
# ============================================================

function Update-Path {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:PATH = "$userPath;$machinePath"

    $cargobin = Join-Path $env:USERPROFILE ".cargo\bin"
    if ((Test-Path $cargobin) -and ($env:PATH -notlike "*$cargobin*")) {
        $env:PATH = "$cargobin;$env:PATH"
    }
}

# ============================================================
# Main
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor White
Write-Host "  Pomotroid Build Script" -ForegroundColor White
Write-Host "========================================" -ForegroundColor White

# --- First check ---
Write-Step "Round 1: Checking environment..."
$env1 = Test-Environment

$needInstall = (-not $env1.Node) -or (-not $env1.Rust) -or (-not $env1.Cargo)

if ($needInstall -and (-not $SkipInstall)) {

    if (-not $env1.Node) {
        $ok = Install-NodeJS
        if (-not $ok) {
            Write-Fail "Node.js install failed, aborting."
            exit 1
        }
    }

    if ((-not $env1.Rust) -or (-not $env1.Cargo)) {
        $ok = Install-Rust
        if (-not $ok) {
            Write-Fail "Rust install failed, aborting."
            exit 1
        }
    }

    # --- Refresh PATH ---
    Write-Step "Refreshing PATH..."
    Update-Path

    # --- Second check ---
    Write-Step "Round 2: Verifying after install..."
    $env2 = Test-Environment

    if ((-not $env2.Node) -or (-not $env2.Rust) -or (-not $env2.Cargo)) {
        Write-Host ""
        Write-Fail "Environment still not ready. Please fix manually:"
        if (-not $env2.Node) {
            Write-Fail "  - Node.js >= ${MinNodeMajor}: https://nodejs.org/"
        }
        if (-not $env2.Rust) {
            Write-Fail "  - Rust (rustc): https://rustup.rs/"
        }
        if (-not $env2.Cargo) {
            Write-Fail "  - Cargo: comes with Rust"
        }
        Write-Host ""
        Write-Host "  Hint: you may need to reopen the terminal to reload PATH" -ForegroundColor Yellow
        exit 1
    }

} elseif ($needInstall -and $SkipInstall) {
    Write-Fail "Environment not ready and -SkipInstall specified, aborting."
    exit 1
}

# --- npm install ---
Write-Step "Installing frontend dependencies (npm install)..."
Set-Location -LiteralPath $ProjectRoot
& npm install
if ($LASTEXITCODE -ne 0) {
    Write-Fail "npm install failed"
    exit 1
}
Write-Ok "npm install done"

# --- Build or Dev ---
if ($Dev) {
    Write-Step "Starting dev mode (npm run tauri dev)..."
    & npm run tauri dev
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "tauri dev failed"
        exit 1
    }
} else {
    Write-Step "Building release (npm run tauri build)..."
    & npm run tauri build
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "tauri build failed"
        exit 1
    }

    Write-Ok "Build complete!"
    Write-Host ""
    Write-Host "  Output: $ProjectRoot\src-tauri\target\release\bundle\" -ForegroundColor White
    Write-Host ""

    $bundlePath = Join-Path $ProjectRoot "src-tauri\target\release\bundle"
    if (Test-Path $bundlePath) {
        explorer.exe $bundlePath
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  All Done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
