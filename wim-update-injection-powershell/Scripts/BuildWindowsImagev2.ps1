# ============================================================
# MASTERISATION AUTOMATIQUE WIM + INJECTION DES MSU
# Tout dans Outputs, WIM complet + SWM garantis
# ============================================================

Clear-Host
Write-Host "=== MASTERISATION WIM AVEC LES KB DU DOSSIER Updates ===" -ForegroundColor Cyan

# ------------------------------------------------------------
# CHEMINS
# ------------------------------------------------------------
$BaseDir       = "C:\Users\adv_herrera\Desktop\W11"
$BaseWIMFolder = Join-Path $BaseDir "BaseWIM"
$UpdatesFolder = Join-Path $BaseDir "Updates"
$OutputDir     = Join-Path $BaseDir "Outputs"

# Taille max pour SWM fractionné (en Mo)
$SplitSizeMB = 3900  # sûr pour FAT32

# Créer le dossier Outputs s'il n'existe pas
if (-Not (Test-Path $OutputDir)) { New-Item -Path $OutputDir -ItemType Directory | Out-Null }

# ------------------------------------------------------------
# DETECTION DU WIM
# ------------------------------------------------------------
$WIMFileOriginal = Join-Path $BaseWIMFolder "install.wim"
if (-Not (Test-Path $WIMFileOriginal)) {
    Write-Host "ERREUR : Aucun install.wim dans BaseWIM" -ForegroundColor Red
    exit 1
}

Write-Host "WIM original trouvé : $WIMFileOriginal" -ForegroundColor Green

# ------------------------------------------------------------
# COPIE DU WIM POUR MODIFICATION DANS OUTPUT
# ------------------------------------------------------------
$WIMWorking = Join-Path $OutputDir "install_work.wim"
Copy-Item -Path $WIMFileOriginal -Destination $WIMWorking -Force
Write-Host "Copie du WIM original vers Output pour modification : $WIMWorking" -ForegroundColor Green

# ------------------------------------------------------------
# CREATION D'UN DOSSIER MOUNT TEMPORAIRE DANS OUTPUT
# ------------------------------------------------------------
$MountPath = Join-Path $OutputDir "Mount"
if (Test-Path $MountPath) { Remove-Item $MountPath -Recurse -Force }
New-Item -Path $MountPath -ItemType Directory | Out-Null
Write-Host "Dossier Mount temporaire créé dans Outputs ✅" -ForegroundColor Green

# ------------------------------------------------------------
# MONTAGE WIM
# ------------------------------------------------------------
Write-Host "`nMontage de l'image WIM pour modifications..." -ForegroundColor Cyan
try {
    dism /Mount-Wim /WimFile:$WIMWorking /index:1 /MountDir:$MountPath
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
# RENOMMER LE WIM FINAL DANS OUTPUT
# ------------------------------------------------------------
$OutputWIM = Join-Path $OutputDir "install_updated.wim"
Rename-Item -Path $WIMWorking -NewName "install_updated.wim" -Force
Write-Host "`nWIM final disponible dans Outputs ✅ : $OutputWIM" -ForegroundColor Green

# ------------------------------------------------------------
# CREATION DES SWM (toujours)
# ------------------------------------------------------------
Write-Host "`nCréation des SWM fractionnés..." -ForegroundColor Cyan
& dism /Split-Wim /WimFile:$OutputWIM /FileSize:${SplitSizeMB}000 /SWMFile:$OutputDir\install_updated.swm
Write-Host "✅ SWM fractionnés créés dans $OutputDir" -ForegroundColor Green

Write-Host "`n=== MASTERISATION TERMINEE ===" -ForegroundColor Cyan
Write-Host "Tout (WIM complet, SWM, Mount temporaire, copie de travail) est dans $OutputDir"