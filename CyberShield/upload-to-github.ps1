$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  ____ _   _ ____  _____ ____  ____  _   _ ___ _____ _     ____  " -ForegroundColor Cyan
Write-Host " / ___| | | | __ )| ____|  _ \\/ ___|| | | |_ _| ____| |   |  _ \ " -ForegroundColor Cyan
Write-Host "| |   | | | |  _ \|  _| | |_) \___ \| |_| || ||  _| | |   | | | |" -ForegroundColor Green
Write-Host "| |___| |_| | |_) | |___|  _ < ___) |  _  || || |___| |___| |_| |" -ForegroundColor Green
Write-Host " \____|\___/|____/|_____|_| \_\____/|_| |_|___|_____|_____|____/ " -ForegroundColor Cyan
Write-Host "               GitHub repository setup" -ForegroundColor DarkGray
Write-Host ""

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git was not found. Install Git for Windows, then reopen PowerShell." -ForegroundColor Red
    exit 1
}

$repoUrl = Read-Host "Paste your NEW GitHub repository URL (or press Enter to set up locally only)"
if (-not (Test-Path ".git")) {
    git init
    if ($LASTEXITCODE -ne 0) { throw "git init failed" }
}

git add README.md Win10_Update_Disable_AllInOne.bat
if ($LASTEXITCODE -ne 0) {
    Write-Host "Could not stage files. Make sure README.md and the .bat file are in this folder." -ForegroundColor Red
    exit 1
}

git status --short
Write-Host ""
Write-Host "Review the staged files above before continuing." -ForegroundColor Yellow
$confirm = Read-Host "Create the initial commit? Type YES to continue"
if ($confirm -cne "YES") {
    Write-Host "Stopped before commit. Your files remain unchanged; staged files can be reviewed." -ForegroundColor Yellow
    exit 0
}

git commit -m "Add CyberShield Windows utility project"
if ($LASTEXITCODE -ne 0) { throw "Commit failed. Configure git user.name and user.email if needed." }

if ([string]::IsNullOrWhiteSpace($repoUrl)) {
    Write-Host "Local Git repository created. Add a GitHub remote later when ready." -ForegroundColor Green
    exit 0
}

if ($repoUrl -notmatch '^https://github\.com/[^/]+/[^/]+(?:\.git)?/?$') {
    Write-Host "That URL doesn't look like a standard GitHub HTTPS repository URL. No remote was added." -ForegroundColor Red
    exit 1
}

$existing = git remote
if ($existing -contains "origin") {
    git remote set-url origin $repoUrl
} else {
    git remote add origin $repoUrl
}
if ($LASTEXITCODE -ne 0) { throw "Could not configure origin remote" }

git branch -M main
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "Push did not complete. Check GitHub repository access and authentication, then retry." -ForegroundColor Yellow
    exit 1
}

Write-Host "Project pushed to GitHub." -ForegroundColor Green
