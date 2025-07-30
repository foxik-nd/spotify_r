# Liste des packages nécessaires
required_packages <- c(
  "httr",         # Pour les requêtes HTTP (équivalent de requests Python)
  "jsonlite",     # Pour manipuler JSON
  "base64enc",    # Pour l'encodage base64
  "dplyr",        # Pour la manipulation de données (équivalent de pandas)
  "httpuv",       # Pour créer un serveur HTTP local (OAuth callback)
  "readr",        # Pour lire les fichiers CSV
  "stringr"       # Pour manipuler les chaînes de caractères
)

# Fonction pour installer les packages manquants
install_missing_packages <- function(packages) {
  for (package in packages) {
    if (!require(package, character.only = TRUE, quietly = TRUE)) {
      cat("📦 Installation du package:", package, "\n")
      install.packages(package, dependencies = TRUE, repos = "https://cran.r-project.org/")
      
      # Vérifier que l'installation a réussi
      if (require(package, character.only = TRUE, quietly = TRUE)) {
        cat("✅", package, "installé avec succès\n")
      } else {
        cat("❌ Échec de l'installation de", package, "\n")
      }
    } else {
      cat("✅", package, "déjà installé\n")
    }
  }
}

# Vérifier la version de R
cat("🔍 Vérification de l'environnement R...\n")
cat("Version R:", R.version.string, "\n")

if (as.numeric(R.version$major) < 4) {
  warning("⚠️  Version R < 4.0 détectée. Certains packages peuvent ne pas fonctionner correctement.")
}

# Installer les packages
cat("\n📚 Vérification et installation des packages requis...\n")
cat("Cela peut prendre quelques minutes la première fois...\n\n")

install_missing_packages(required_packages)

# Vérification finale
cat("\n🧪 Test de chargement des packages...\n")
all_loaded <- TRUE

for (package in required_packages) {
  if (require(package, character.only = TRUE, quietly = TRUE)) {
    cat("✅", package, "chargé correctement\n")
  } else {
    cat("❌", package, "échec du chargement\n")
    all_loaded <- FALSE
  }
}

if (all_loaded) {
  cat("\n🎉 TOUS LES PACKAGES SONT PRÊTS!\n")
  cat("Vous pouvez maintenant exécuter votre script principal.\n")
  cat("\nCommandes suivantes :\n")
  cat("  source('spotify_analysis.R')    # Charger le script principal\n")
  cat("  source('simple_test.R')         # Test rapide\n")
} else {
  cat("\n❌ PROBLÈME DÉTECTÉ\n")
  cat("Certains packages n'ont pas pu être installés.\n")
  cat("Essayez d'installer manuellement :\n")
  cat("  install.packages(c('httr', 'jsonlite', 'httpuv'))\n")
}

cat("\n" , rep("=", 60), "\n")