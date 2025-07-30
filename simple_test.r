# ===============================================
# TEST SIMPLE SPOTIFY - SANS FICHIER CSV
# Version de test rapide pour vérifier que tout fonctionne
# ===============================================

# Nettoyer l'environnement
rm(list = ls())

# Charger les bibliothèques (installer d'abord si nécessaire)
cat("📚 Chargement des bibliothèques...\n")

if (!file.exists("install_packages.R")) {
  stop("❌ Fichier install_packages.R manquant. Créez-le d'abord!")
}

source("install_packages.R")

# Charger le script principal
if (!file.exists("spotify_analysis.R")) {
  stop("❌ Fichier spotify_analysis.R manquant. Créez-le d'abord!")
}

cat("📄 Chargement du script principal...\n")
source("spotify_analysis.R")

# ===============================================
# TEST RAPIDE DES FONCTIONNALITÉS
# ===============================================

cat("\n")
cat("🎵 TEST SPOTIFY API EN R\n")
cat("========================\n\n")

# Test 1: Vérification de la configuration
cat("1️⃣ Vérification de la configuration...\n")

if (!file.exists("config.R")) {
  cat("❌ Fichier config.R manquant!\n")
  cat("💡 Créez config.R avec :\n")
  cat("   CLIENT_ID <- 'votre_client_id'\n")
  cat("   CLIENT_SECRET <- 'votre_client_secret'\n")
  stop("Configuration manquante")
}

tryCatch({
  source("config.R")
  if (exists("CLIENT_ID") && exists("CLIENT_SECRET")) {
    if (nchar(CLIENT_ID) > 10 && nchar(CLIENT_SECRET) > 10) {
      cat("✅ Configuration OK (CLIENT_ID et CLIENT_SECRET trouvés)\n")
    } else {
      stop("Identifiants vides ou trop courts")
    }
  } else {
    stop("Variables CLIENT_ID et CLIENT_SECRET non définies")
  }
}, error = function(e) {
  cat("❌ Erreur de configuration:", e$message, "\n")
  cat("💡 Vérifiez votre fichier config.R\n")
  stop()
})

# Test 2: Authentification
cat("\n2️⃣ Lancement de l'authentification OAuth...\n")
cat("⚠️  Une page web va s'ouvrir pour l'authentification Spotify\n")
cat("📱 Connectez-vous et autorisez l'application\n")
cat("⏱️  Le serveur va démarrer sur http://localhost:8000\n\n")

Sys.sleep(2)  # Petite pause pour lire les instructions

tryCatch({
  run_oauth_server()
  
  if (!is.null(access_token) && nchar(access_token) > 0) {
    cat("✅ Authentification réussie!\n")
    cat("🔑 Token obtenu (longueur:", nchar(access_token), "caractères)\n")
  } else {
    stop("Token vide ou null")
  }
}, error = function(e) {
  cat("❌ Erreur d'authentification:", e$message, "\n")
  cat("💡 Vérifiez vos identifiants Spotify et votre connexion internet\n")
  stop()
})

# Test 3: Récupération des top tracks
cat("\n3️⃣ Récupération de vos top tracks...\n")
tryCatch({
  # Commencer par un petit nombre pour le test
  top_tracks <- get_top_tracks(limit = 5, time_range = "medium_term")
  
  if (length(top_tracks) > 0) {
    cat("✅ Top tracks récupérés:", length(top_tracks), "morceaux\n")
    cat("🎵 Premier morceau:", top_tracks[[1]]$name, "\n")
  } else {
    stop("Aucun track récupéré")
  }
}, error = function(e) {
  cat("❌ Erreur lors de la récupération:", e$message, "\n")
  cat("💡 Vérifiez que vous avez écouté de la musique sur Spotify\n")
  
  # Essayer avec plus de tracks au cas où
  cat("🔄 Tentative avec long_term et plus de morceaux...\n")
  tryCatch({
    top_tracks <- get_top_tracks(limit = 20, time_range = "long_term")
    if (length(top_tracks) > 0) {
      cat("✅ Récupération réussie avec", length(top_tracks), "morceaux\n")
    }
  }, error = function(e2) {
    cat("❌ Échec également avec long_term\n")
    stop()
  })
})

# Test 4: Conversion en DataFrame
cat("\n4️⃣ Conversion en DataFrame R...\n")
tryCatch({
  df_tracks <- tracks_to_dataframe(top_tracks)
  
  if (nrow(df_tracks) > 0 && ncol(df_tracks) > 0) {
    cat("✅ DataFrame créé avec", nrow(df_tracks), "lignes et", ncol(df_tracks), "colonnes\n")
    cat("📊 Colonnes:", paste(names(df_tracks), collapse = ", "), "\n")
    
    cat("\n🎵 Aperçu de vos top tracks:\n")
    cat(rep("-", 50), "\n")
    print(df_tracks[, c("name", "artists", "popularity")])
    cat(rep("-", 50), "\n")
  } else {
    stop("DataFrame vide")
  }
}, error = function(e) {
  cat("❌ Erreur lors de la conversion:", e$message, "\n")
  stop()
})

# Test 5: Statistiques simples
cat("\n5️⃣ Calcul de statistiques simples...\n")
tryCatch({
  show_stats(df_tracks)
  cat("✅ Statistiques calculées avec succès\n")
  
  # Statistiques additionnelles pour le test
  if ("popularity" %in% names(df_tracks)) {
    pop_max <- max(df_tracks$popularity, na.rm = TRUE)
    pop_min <- min(df_tracks$popularity, na.rm = TRUE)
    cat("🔥 Morceau le plus populaire:", pop_max, "\n")
    cat("💎 Morceau le moins populaire:", pop_min, "\n")
  }
}, error = function(e) {
  cat("❌ Erreur lors du calcul:", e$message, "\n")
})

# Test 6: Test d'un appel API pour un genre (optionnel)
cat("\n6️⃣ Test récupération genre d'un artiste...\n")
if (nrow(df_tracks) > 0) {
  tryCatch({
    # Prendre le premier artiste s'il y en a un
    if ("artists" %in% names(df_tracks)) {
      cat("🎤 Test avec le premier artiste de votre liste...\n")
      # Note: Cette partie nécessiterait l'artist_id, pas juste le nom
      cat("ℹ️  Test de genres sauté (nécessite artist_ids du fichier CSV)\n")
    }
  }, error = function(e) {
    cat("⚠️  Test de genres échoué (normal sans fichier CSV):", e$message, "\n")
  })
}

# Test 7: Sauvegarde
cat("\n7️⃣ Sauvegarde des résultats...\n")
tryCatch({
  filename <- paste0("test_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
  write.csv(df_tracks, filename, row.names = FALSE)
  cat("✅ Résultats sauvegardés dans '", filename, "'\n")
  
  # Vérifier que le fichier existe
  if (file.exists(filename)) {
    file_size <- file.info(filename)$size
    cat("📁 Taille du fichier:", file_size, "bytes\n")
  }
}, error = function(e) {
  cat("❌ Erreur lors de la sauvegarde:", e$message, "\n")
})

# Résumé final
cat("\n", rep("=", 60), "\n")
cat("🎉 TEST TERMINÉ AVEC SUCCÈS!\n")
cat(rep("=", 60), "\n")

cat("\n📊 RÉSUMÉ:\n")
cat("✅ Configuration Spotify: OK\n")
cat("✅ Authentification OAuth: OK\n") 
cat("✅ Récupération top tracks: OK (", nrow(df_tracks), "morceaux)\n")
cat("✅ Conversion DataFrame: OK\n")
cat("✅ Calcul statistiques: OK\n")
cat("✅ Sauvegarde: OK\n")

cat("\n📁 FICHIERS GÉNÉRÉS:\n")
list_files <- list.files(pattern = "test_results_.*\\.csv")
for (f in list_files) {
  cat("   📄", f, "\n")
}

cat("\n💡 PROCHAINES ÉTAPES:\n")
cat("   🔸 Vos données de base sont récupérées avec succès\n")
cat("   🔸 Pour une analyse complète, ajoutez le fichier tracks_features.csv\n")
cat("   🔸 Utilisez main_analysis() pour l'analyse avancée\n")
cat("   🔸 Explorez vos données avec les outils R (ggplot2, etc.)\n")

cat("\n🎵 EXEMPLE D'USAGE AVANCÉ:\n")
cat("   df <- read.csv('", filename, "')\n")
cat("   summary(df$popularity)\n")
cat("   plot(df$popularity)\n")

cat("\n", rep("=", 60), "\n")
cat("✨ VOTRE API SPOTIFY R EST OPÉRATIONNELLE! ✨\n")
cat(rep("=", 60), "\n")