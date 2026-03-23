# 🖥️ Automatisation d’image Windows (WIM) — Script PowerShell

## 🎯 Objectif

Ce projet propose un script PowerShell permettant d’automatiser le cycle de vie d’une image Windows (`.wim`) :

- Montage de l’image WIM
- Injection de mises à jour Windows (`.msu`)
- Vérification de l’installation des KB
- Commit et démontage sécurisé
- Génération d’une image WIM mise à jour
- Fractionnement en fichiers `.swm` (compatible FAT32)

👉 Ce script est destiné aux administrateurs systèmes et aux environnements de déploiement automatisé.

---

## ⚙️ Fonctionnalités

- 🔄 Processus entièrement automatisé
- 📦 Injection en masse de fichiers `.msu`
- ✅ Vérification des mises à jour installées (KB)
- 💾 Gestion sécurisée du montage / démontage (DISM)
- 📁 Organisation propre des fichiers de sortie
- 📀 Génération automatique de fichiers `.swm` (clé USB bootable)
- 🧱 Gestion des erreurs avec affichage console

---

## 🏗️ Structure du projet
- BaseWIM (pour mettre le fichier wim)
- Logs (pour le suivi de ce qui a été effectué)
- Mount (pour le montage temporaire de l'image Windows)
- Outputs (les fichiers crées doivent aller la)
- Scripts (lancer les scripts en cmd pour permettre l'elevation direct et le lancement via double clic)
- Updates (mettre les fichiers .msu ici)


Ameliorations possibles :
  - Prise en compte des fichier wim et swm (aussi bien dans la base que les fichiers crées)
