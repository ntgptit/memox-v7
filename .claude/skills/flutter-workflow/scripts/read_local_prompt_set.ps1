[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SourceRoot,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
    [string] $FeatureName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string] $ImplementationSha256,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string] $ArchitectureReviewSha256,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string] $UiUxReviewSha256,

    [string] $TargetRoot,

    [switch] $VerifyOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExactGitWorktreeRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Role
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Role worktree root does not exist: $Path"
    }

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $gitOutput = & git -C $resolved rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "$Role path is not inside a Git worktree: $resolved`n$gitOutput"
    }

    $reportedRoot = ($gitOutput | Select-Object -Last 1).ToString().Trim()
    $gitRoot = (Resolve-Path -LiteralPath $reportedRoot).Path
    if ($resolved -ine $gitRoot) {
        throw "$Role path must be the exact worktree root. Received: $resolved; root: $gitRoot"
    }

    return $gitRoot
}

if ([string]::IsNullOrWhiteSpace($TargetRoot)) {
    $TargetRoot = (Get-Location).Path
}

$sourceWorktree = Resolve-ExactGitWorktreeRoot -Path $SourceRoot -Role 'Source'
$targetWorktree = Resolve-ExactGitWorktreeRoot -Path $TargetRoot -Role 'Target'

if ($sourceWorktree -ieq $targetWorktree) {
    throw 'Source and target worktrees must differ. Run implementation from the feature worktree, not the prompt-authoring worktree.'
}

$promptDirectory = Join-Path $sourceWorktree "docs/prompt/$FeatureName"
$specifications = @(
    [pscustomobject]@{
        Name = 'implementation.md'
        ExpectedHash = $ImplementationSha256.ToUpperInvariant()
    },
    [pscustomobject]@{
        Name = 'recursive-architecture-logic-review.md'
        ExpectedHash = $ArchitectureReviewSha256.ToUpperInvariant()
    },
    [pscustomobject]@{
        Name = 'recursive-ui-ux-review.md'
        ExpectedHash = $UiUxReviewSha256.ToUpperInvariant()
    }
)

$verifiedPrompts = @()
foreach ($specification in $specifications) {
    $path = Join-Path $promptDirectory $specification.Name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing prompt file: $path"
    }

    $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($actualHash -cne $specification.ExpectedHash) {
        throw "SHA-256 mismatch for $path. Expected $($specification.ExpectedHash); actual $actualHash"
    }

    $verifiedPrompts += [pscustomobject]@{
        Name = $specification.Name
        Path = $path
        Hash = $actualHash
    }
}

Write-Output 'PROMPT_HANDOFF_VERIFIED'
Write-Output "Source worktree: $sourceWorktree"
Write-Output "Target worktree: $targetWorktree"
foreach ($prompt in $verifiedPrompts) {
    Write-Output "Verified: $($prompt.Name) [$($prompt.Hash)]"
}

if ($VerifyOnly) {
    return
}

foreach ($prompt in $verifiedPrompts) {
    Write-Output "===== BEGIN LOCAL PROMPT: $($prompt.Name) ====="
    Get-Content -Raw -LiteralPath $prompt.Path -Encoding utf8
    Write-Output "===== END LOCAL PROMPT: $($prompt.Name) ====="
}

