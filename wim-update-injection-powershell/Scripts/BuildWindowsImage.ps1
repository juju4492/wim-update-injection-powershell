# ============================================================
# MASTERISATION AUTOMATIQUE WIM + INJECTION DES MSU
# Workflow complet : WIM + SWM
# ============================================================

Clear-Host
Write-Host "=== MASTERISATION WIM AVEC LES KB DU DOSSIER Updates ===" -ForegroundColor Cyan

# ------------------------------------------------------------
# CHEMINS
# ------------------------------------------------------------
$BaseDir       = "C:\Users\adv_herrera\Desktop\W11"
$BaseWIMFolder = Join-Path $BaseDir "BaseWIM"
$MountPath     = Join-Path $BaseDir "Mount"
$UpdatesFolder = Join-Path $BaseDir "Updates"
$OutputDir     = Join-Path $BaseDir "Outputs"
$LogDir        = Join-Path $BaseDir "Logs"

# Taille max pour SWM fractionné (en Mo)
$SplitSizeMB = 3900  # sûr pour FAT32

# Créer les dossiers si manquants
foreach ($dir in @($MountPath, $OutputDir, $LogDir)) {
    if (-Not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory | Out-Null }
}

# ------------------------------------------------------------
# DETECTION DU WIM
# ------------------------------------------------------------
$WIMFile = Join-Path $BaseWIMFolder "install.wim"
if (-Not (Test-Path $WIMFile)) {
    Write-Host "ERREUR : Aucun install.wim dans BaseWIM" -ForegroundColor Red
    exit 1
}

Write-Host "WIM trouvé : $WIMFile" -ForegroundColor Green

# ------------------------------------------------------------
# DEMONTAGE ET NETTOYAGE DU DOSSIER MOUNT
# ------------------------------------------------------------
Write-Host "`nVérification et nettoyage du dossier Mount..." -ForegroundColor Yellow
try {
    # Tente de démonter si un WIM est monté
    dism /Unmount-Wim /MountDir:$MountPath /Discard | Out-Null
} catch {
    # Ignore l'erreur si aucune image n'était montée
}
# Nettoyage du Mount, en ignorant les fichiers protégés
Get-ChildItem $MountPath -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object {
        try { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
Write-Host "✅ Dossier Mount prêt et vide" -ForegroundColor Green

# ------------------------------------------------------------
# MONTAGE WIM
# ------------------------------------------------------------
Write-Host "`nMontage de l'image WIM..." -ForegroundColor Cyan
try {
    dism /Mount-Wim /WimFile:$WIMFile /index:1 /MountDir:$MountPath
    Write-Host "✅ Montage réussi" -ForegroundColor Green
} catch {
    Write-Host "ERREUR : impossible de monter l'image, arrêt du script" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# INJECTION DES MSU
# ------------------------------------------------------------
$MSUs = Get-ChildItem -Path $UpdatesFolder -Filter *.msu
if ($MSUs.Count -eq 0) {
    Write-Host "Aucun fichier MSU trouvé dans $UpdatesFolder" -ForegroundColor Yellow
} else {
    foreach ($msu in $MSUs) {
        Write-Host "`nInjection de $($msu.Name)..." -ForegroundColor Cyan
        try {
            dism /Image:$MountPath /Add-Package /PackagePath:"$($msu.FullName)"
            Write-Host "✅ Injection réussie pour $($msu.Name)" -ForegroundColor Green
        } catch {
            Write-Host "ERREUR : injection de $($msu.Name) échouée" -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------
# VERIFICATION DES PACKAGES INJECTES
# ------------------------------------------------------------
Write-Host "`nVérification des packages injectés..." -ForegroundColor Cyan
foreach ($msu in $MSUs) {
    if ($msu.BaseName -match "KB\d+") { $KB = $matches[0] } else { $KB = $msu.BaseName }
    $check = dism /Image:$MountPath /Get-Packages | Select-String $KB
    if ($check) { Write-Host "$($msu.Name) bien injectée ✅" -ForegroundColor Green }
    else { Write-Host "⚠️ $($msu.Name) non détectée ❌" -ForegroundColor Red }
}

# ------------------------------------------------------------
# DEMONTAGE ET COMMIT
# ------------------------------------------------------------
Write-Host "`nDémontage de l'image WIM avec commit..." -ForegroundColor Cyan
try {
    dism /Unmount-Wim /MountDir:$MountPath /Commit
    Write-Host "✅ Démontage et commit réussis" -ForegroundColor Green
} catch {
    Write-Host "ERREUR : impossible de démonter et commit" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# SORTIE : WIM + SWM
# ------------------------------------------------------------
$OutputWIM = Join-Path $OutputDir "install_updated.wim"

# Copie du WIM final
Copy-Item -Path $WIMFile -Destination $OutputWIM -Force
Write-Host "`nWIM final copié dans $OutputDir ✅" -ForegroundColor Green

# Fractionnement pour FAT32 si nécessaire
$FileSizeMB = (Get-Item $OutputWIM).Length / 1MB
if ($FileSizeMB -gt $SplitSizeMB) {
    Write-Host "Taille du WIM > $SplitSizeMB Mo, création des SWM fractionnés..." -ForegroundColor Cyan
    & dism /Split-Wim /WimFile:$OutputWIM /FileSize:${SplitSizeMB}000 /SWMFile:$OutputDir\install_updated.swm
    Write-Host "SWM fractionnés créés dans $OutputDir ✅" -ForegroundColor Green
}

Write-Host "`n=== MASTERISATION TERMINEE ===" -ForegroundColor Cyan
Write-Host "WIM complet et SWM (si fractionné) sont disponibles dans $OutputDir"