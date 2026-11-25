$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$Remote = 'https://github.com/harshit8650-netizen/close-quarters-hd.git'
function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw "Git command failed (exit $LASTEXITCODE). Check the message above." }
}
try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Install Git for Windows first: https://git-scm.com/download/win' }
    if (-not (Test-Path '.github/workflows/android.yml') -or -not (Test-Path 'game/project.godot')) { throw 'Extract the complete ZIP first, including hidden folders.' }
    Write-Host "Destination: $Remote"
    Write-Host 'Create an EMPTY repository at https://github.com/new named close-quarters-hd under harshit8650-netizen before continuing.'
    if (-not (Test-Path '.git')) { Invoke-Git init -b main }
    $branch = (git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') { throw 'This script expects the main branch. Use a freshly extracted folder.' }
    $remotes = @(git remote)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to list Git remotes.' }
    if ($remotes -contains 'origin') {
        $existing = (git remote get-url origin).Trim()
        if ($LASTEXITCODE -ne 0 -or $existing -ne $Remote) { throw 'An unrelated origin is configured. Use a freshly extracted folder; no remote was overwritten.' }
    } else { Invoke-Git remote add origin $Remote }
    $name = git config user.name
    if (-not $name) { $name = Read-Host 'Git commit author name'; if (-not $name.Trim()) { throw 'Author name required.' }; Invoke-Git config --local user.name $name }
    $email = git config user.email
    if (-not $email) { $email = Read-Host 'Git commit email (GitHub verified or noreply address)'; if (-not $email.Trim()) { throw 'Author email required.' }; Invoke-Git config --local user.email $email }
    Invoke-Git add --all
    $changes = @(git status --porcelain)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect Git status.' }
    if ($changes.Count -gt 0) { Invoke-Git commit -m 'Close Quarters HD v2.0 - Android game and APK workflow' }
    Invoke-Git push -u origin main
    Write-Host 'Push successful. Open https://github.com/harshit8650-netizen/close-quarters-hd/actions to monitor the APK build.' -ForegroundColor Green
    exit 0
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host 'No force-push is used. If the remote already contains commits, resolve the history manually or use a new empty repository.'
    exit 1
}
