param (
    [string]$Fork = "0", 
    [string]$CsvPath = ".\repos.txt",
    [string]$GithubUser = "")
Write-Host "Params val "
Write-Host $Fork
Write-Host $CsvPath
Write-Host $GithubUser
if (-not $GithubUser) {
    Write-Host "❌ Please provide your GitHub username with -GithubUser"
    exit 1
}

# Load repos from CSV
$repos = Import-Csv -Path $CsvPath

foreach ($repo in $repos) {
    $url = $repo.repo_url
     Write-Host $url
    if (-not $url) {
        Write-Host "⚠️ Skipping empty row"
        continue
    }

    # Extract owner and repo name from URL
    if ($url -match "github\.com[:/](?<owner>[^/]+)/(?<name>[^/]+?)(?:\.git)?$") {
        $owner = $matches['owner']
        $name  = $matches['name']
    } else {
        Write-Host "❌ Invalid repo URL format: $url"
        continue
    }

    Write-Host "➡️ Processing $owner/$name"

if ($Fork -eq "1") {
    # Create fork under your account
    Write-Host "🔄 Creating fork..."
    gh repo fork $url --clone=false --remote=false | Out-Null
}
    # Clone the fork
    $forkUrl = "https://github.com/$GithubUser/$name.git"
    if (-not (Test-Path $name)) {
        Write-Host "📥 Cloning fork: $forkUrl"
        git clone $forkUrl
    } else {
        Write-Host "⚠️ Folder $name already exists, skipping clone"
    }

    # Add as submodule in current directory
    if (-not (Test-Path ".gitmodules")) {
        Write-Host "📌 Initializing submodules tracking"
        git submodule init
    }

    Write-Host "➕ Adding submodule: $forkUrl"
    git submodule add $forkUrl $name
    git submodule update --init --recursive $name

    Write-Host "✅ Done with $name"
    Write-Host "-----------------------------------"
}
