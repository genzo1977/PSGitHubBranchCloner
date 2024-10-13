Add-Type -AssemblyName System.Windows.Forms

# Function to create the GUI
function Show-DownloadGui {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PSGitHubBranchCloner"
    $form.Size = New-Object System.Drawing.Size(400, 250)
    $form.StartPosition = "CenterScreen"

    # Label for GitHub URL input
    $urlLabel = New-Object System.Windows.Forms.Label
    $urlLabel.Text = "GitHub Repo URL:"
    $urlLabel.Location = New-Object System.Drawing.Point(10, 20)
    $urlLabel.Size = New-Object System.Drawing.Size(120, 20)
    $form.Controls.Add($urlLabel)

    # TextBox for GitHub URL input
    $urlInput = New-Object System.Windows.Forms.TextBox
    $urlInput.Location = New-Object System.Drawing.Point(140, 20)
    $urlInput.Size = New-Object System.Drawing.Size(230, 20)
    $form.Controls.Add($urlInput)

    # Label for output directory
    $dirLabel = New-Object System.Windows.Forms.Label
    $dirLabel.Text = "Output Directory:"
    $dirLabel.Location = New-Object System.Drawing.Point(10, 60)
    $dirLabel.Size = New-Object System.Drawing.Size(120, 20)
    $form.Controls.Add($dirLabel)

    # TextBox for output directory
    $dirInput = New-Object System.Windows.Forms.TextBox
    $dirInput.Location = New-Object System.Drawing.Point(140, 60)
    $dirInput.Size = New-Object System.Drawing.Size(230, 20)
    $form.Controls.Add($dirInput)

    # Button to browse for folder
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = "Browse..."
    $browseButton.Location = New-Object System.Drawing.Point(300, 90)
    $browseButton.Size = New-Object System.Drawing.Size(70, 25)
    $browseButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderBrowser.ShowDialog() -eq "OK") {
            $dirInput.Text = $folderBrowser.SelectedPath
        }
    })
    $form.Controls.Add($browseButton)

    # Download button
    $downloadButton = New-Object System.Windows.Forms.Button
    $downloadButton.Text = "Download"
    $downloadButton.Location = New-Object System.Drawing.Point(140, 130)
    $downloadButton.Size = New-Object System.Drawing.Size(100, 30)
    $downloadButton.Add_Click({
        $repoUrl = $urlInput.Text
        $outputDir = $dirInput.Text

        if (-not [string]::IsNullOrEmpty($repoUrl) -and -not [string]::IsNullOrEmpty($outputDir)) {
            Download-GitHubRepo -repoUrl $repoUrl -outputDir $outputDir
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please fill out both the GitHub URL and output directory.")
        }
    })
    $form.Controls.Add($downloadButton)

    # Show the form
    $form.Topmost = $true
    $form.Add_Shown({$form.Activate()})
    [void] $form.ShowDialog()
}

# Function to download all branches of a GitHub repository
function Download-GitHubRepo {
    param (
        [string]$repoUrl,
        [string]$outputDir
    )

    # Check if git is installed
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show("Git is not installed. Please install Git and try again.")
        return
    }

    # Clone the repository
    $gitCloneCommand = "git clone $repoUrl $outputDir"
    Write-Host "Running: $gitCloneCommand"
    Invoke-Expression $gitCloneCommand

    # Navigate to the repo directory
    Set-Location -Path "$outputDir"

    # Fetch all remote branches
    $gitFetchAllCommand = "git fetch --all"
    Write-Host "Running: $gitFetchAllCommand"
    Invoke-Expression $gitFetchAllCommand

    # Get the remote URL for cloning individual branches
    $remoteUrl = (git config --get remote.origin.url)
    Write-Host "Remote URL: $remoteUrl"

    # Get all remote branches except HEAD and master
    $branches = git branch --all | Where-Object { $_ -notmatch 'HEAD|master' } | ForEach-Object { ($_ -replace 'remotes/origin/', '').Trim() }

    Write-Host "Branches to clone: $branches"

    foreach ($branch in $branches) {
        $branchCloneCommand = "git clone -b $branch $remoteUrl $branch"
        Write-Host "Running: $branchCloneCommand"
        Invoke-Expression $branchCloneCommand
    }

    [System.Windows.Forms.MessageBox]::Show("All branches cloned successfully.")
}

# Run the GUI
Show-DownloadGui
