# ===============================================
# SPOTIFY DATA ANALYSIS - VERSION R
# Conversion du notebook Python vers R
# ===============================================

# Chargement des librairies nécessaires
library(httr)
library(jsonlite)
library(base64enc)
library(dplyr)
library(httpuv)

# Charger la configuration
source("config.R")

# ===============================================
# CONFIGURATION SPOTIFY
# ===============================================

REDIRECT_URI <- "http://localhost:8000/callback"
AUTH_BASE_URL <- "https://accounts.spotify.com"
API_BASE_URL <- "https://api.spotify.com/v1"

# Variable globale pour stocker le token
access_token <- NULL

# ===============================================
# CLASSE SPOTIFY AUTH CLIENT (équivalent Python)
# ===============================================

SpotifyAuthClient <- list(
  client_id = CLIENT_ID,
  client_secret = CLIENT_SECRET,
  redirect_uri = REDIRECT_URI,
  auth_base_url = AUTH_BASE_URL,
  api_base_url = API_BASE_URL,
  
  # Méthode get_auth_url
  get_auth_url = function(scope = NULL) {
    params <- list(
      client_id = CLIENT_ID,
      response_type = "code",
      redirect_uri = REDIRECT_URI,
      scope = ifelse(is.null(scope), "", scope)
    )
    
    query_string <- paste(mapply(function(k, v) paste0(k, "=", URLencode(v)), 
                                names(params), params), 
                         collapse = "&")
    
    return(paste0(AUTH_BASE_URL, "/authorize?", query_string))
  },
  
  # Méthode get_token
  get_token = function(code) {
    auth_string <- paste0(CLIENT_ID, ":", CLIENT_SECRET)
    auth_header <- paste0("Basic ", base64encode(charToRaw(auth_string)))
    
    response <- POST(
      paste0(AUTH_BASE_URL, "/api/token"),
      add_headers(
        Authorization = auth_header,
        `Content-Type` = "application/x-www-form-urlencoded"
      ),
      body = list(
        grant_type = "authorization_code",
        code = code,
        redirect_uri = REDIRECT_URI
      ),
      encode = "form"
    )
    
    if (status_code(response) == 200) {
      return(content(response, "parsed"))
    } else {
      stop(paste("Erreur lors de la récupération du token:", content(response, "text")))
    }
  }
)

# ===============================================
# FONCTION POUR DÉMARRER LE SERVEUR OAUTH
# ===============================================

run_oauth_server <- function(scope = "user-read-private user-read-email user-top-read") {
  # Générer l'URL d'authentification
  auth_url <- SpotifyAuthClient$get_auth_url(scope)
  cat("Ouvrez cette URL dans votre navigateur :\n", auth_url, "\n")
  
  # Démarrer le serveur local pour recevoir le callback
  server <- startServer("127.0.0.1", 8000, list(
    call = function(req) {
      if (grepl("/callback", req$PATH_INFO)) {
        # Extraire le code de la query string
        query <- req$QUERY_STRING
        code_match <- regmatches(query, regexpr("code=([^&]*)", query))
        if (length(code_match) > 0) {
          code <- gsub("code=", "", code_match)
          
          # Échanger le code contre un token
          tryCatch({
            token_info <- SpotifyAuthClient$get_token(code)
            access_token <<- token_info$access_token
            cat("Token d'accès obtenu avec succès!\n")
            cat("Token:", access_token, "\n")
          }, error = function(e) {
            cat("Erreur lors de l'obtention du token:", e$message, "\n")
          })
        }
        
        # Réponse HTML simple
        list(
          status = 200L,
          headers = list('Content-Type' = 'text/html'),
          body = "<h1>Authentification réussie!</h1><p>Vous pouvez fermer cette fenêtre.</p>"
        )
      } else {
        list(status = 404L, body = "Page non trouvée")
      }
    }
  ))
  
  cat("Serveur en attente du callback...\n")
  cat("Appuyez sur Ctrl+C pour arrêter le serveur une fois authentifié.\n")
  
  # Attendre l'authentification
  service()
  
  # Arrêter le serveur
  stopServer(server)
}

# ===============================================
# FONCTIONS POUR RÉCUPÉRER LES DONNÉES SPOTIFY
# ===============================================

# Fonction pour récupérer les top tracks
get_top_tracks <- function(limit = 50, time_range = "long_term") {
  if (is.null(access_token)) {
    stop("Erreur : Aucun token d'accès disponible. Authentifiez-vous d'abord")
  }
  
  url <- paste0(API_BASE_URL, "/me/top/tracks")
  
  response <- GET(
    url,
    add_headers(Authorization = paste0("Bearer ", access_token)),
    query = list(time_range = time_range, limit = limit)
  )
  
  if (status_code(response) == 200) {
    data <- content(response, "parsed")
    top_tracks <- data$items
    
    cat("Votre top tracks :\n")
    for (i in seq_along(top_tracks)) {
      track <- top_tracks[[i]]
      artists <- sapply(track$artists, function(x) x$name)
      cat(sprintf("%d. %s - %s\n", i, track$name, paste(artists, collapse = ", ")))
    }
    
    return(top_tracks)
  } else {
    stop(paste("Erreur:", status_code(response), content(response, "text")))
  }
}

# Fonction pour obtenir les genres d'un artiste
get_genres_for_artist <- function(artist_id) {
  if (is.null(access_token)) {
    cat("Erreur : Aucun token d'accès disponible. Authentifiez-vous d'abord\n")
    return(character(0))
  }
  
  url <- paste0(API_BASE_URL, "/artists/", artist_id)
  
  response <- GET(
    url,
    add_headers(Authorization = paste0("Bearer ", access_token))
  )
  
  if (status_code(response) == 200) {
    artist_data <- content(response, "parsed")
    return(artist_data$genres %||% character(0))
  } else {
    cat("Erreur pour l'artiste", artist_id, ":", status_code(response), "\n")
    return(character(0))
  }
}

# ===============================================
# FONCTIONS DE TRAITEMENT DES DONNÉES
# ===============================================

# Convertir les top tracks en DataFrame
tracks_to_dataframe <- function(top_tracks) {
  tracks_data <- data.frame(
    name = character(0),
    artists = character(0),
    album = character(0),
    popularity = numeric(0),
    id_track = character(0),
    stringsAsFactors = FALSE
  )
  
  for (track in top_tracks) {
    artists <- sapply(track$artists, function(x) x$name)
    
    track_info <- data.frame(
      name = track$name,
      artists = paste(artists, collapse = ", "),
      album = track$album$name,
      popularity = track$popularity,
      id_track = track$id,
      stringsAsFactors = FALSE
    )
    
    tracks_data <- rbind(tracks_data, track_info)
  }
  
  return(tracks_data)
}

# Ajouter les genres au DataFrame
add_genres_to_dataframe <- function(df) {
  if (!"artist_ids" %in% names(df)) {
    cat("La colonne 'artist_ids' est manquante\n")
    return(df)
  }
  
  df$genres <- character(nrow(df))
  
  for (i in 1:nrow(df)) {
    # Parser les IDs d'artistes (format: "['id1', 'id2']")
    artist_ids_str <- df$artist_ids[i]
    artist_ids_str <- gsub("\\[|\\]|'", "", artist_ids_str)
    artist_ids <- trimws(strsplit(artist_ids_str, ",")[[1]])
    
    # Récupérer les genres pour chaque artiste
    track_genres <- character(0)
    for (artist_id in artist_ids) {
      if (nchar(artist_id) > 0) {
        genres <- get_genres_for_artist(artist_id)
        track_genres <- c(track_genres, genres)
      }
    }
    
    # Supprimer les doublons et joindre
    track_genres <- unique(track_genres)
    df$genres[i] <- paste(track_genres, collapse = ", ")
  }
  
  return(df)
}

# ===============================================
# SCRIPT PRINCIPAL
# ===============================================

main_analysis <- function() {
  cat("=== ANALYSE SPOTIFY EN R ===\n\n")
  
  # 1. Authentification
  cat("1. Démarrage de l'authentification OAuth...\n")
  run_oauth_server()
  
  if (is.null(access_token)) {
    stop("Échec de l'authentification. Arrêt du script.")
  }
  
  # 2. Récupération des top tracks
  cat("\n2. Récupération de vos top tracks...\n")
  top_tracks <- get_top_tracks()
  
  # 3. Conversion en DataFrame
  cat("\n3. Conversion des données en DataFrame...\n")
  df_tracks <- tracks_to_dataframe(top_tracks)
  print(head(df_tracks))
  
  # 4. Lecture du fichier tracks_features.csv (si disponible)
  cat("\n4. Lecture du fichier tracks_features.csv...\n")
  if (file.exists("tracks_features.csv")) {
    tracks_features <- read.csv("tracks_features.csv", stringsAsFactors = FALSE)
    
    # Renommer la colonne id en id_track
    if ("id" %in% names(tracks_features)) {
      names(tracks_features)[names(tracks_features) == "id"] <- "id_track"
    }
    
    cat("Aperçu du fichier tracks_features:\n")
    print(head(tracks_features, 5))
    
    # 5. Fusion des données
    cat("\n5. Fusion des DataFrames...\n")
    df_tracks_all <- merge(df_tracks, tracks_features, by = "id_track", all.x = TRUE)
    cat("Données fusionnées - Dimensions:", dim(df_tracks_all), "\n")
    
    # 6. Sélection des colonnes pour l'analyse
    audio_features <- c('popularity', 'danceability', 'energy', 'key', 'loudness',
                       'mode', 'speechiness', 'acousticness', 'instrumentalness', 
                       'liveness', 'valence', 'tempo')
    
    df_tracks_clean <- df_tracks_all[, intersect(names(df_tracks_all), audio_features), drop = FALSE]
    
    # 7. Ajout des genres (si artist_ids disponible)
    if ("artist_ids" %in% names(df_tracks_all)) {
      cat("\n6. Ajout des genres musicaux...\n")
      df_tracks_all <- add_genres_to_dataframe(df_tracks_all)
      df_tracks_clean$genres <- df_tracks_all$genres[match(rownames(df_tracks_clean), rownames(df_tracks_all))]
    }
    
    cat("\n7. Résultats finaux:\n")
    print(head(df_tracks_clean))
    
    # Sauvegarder les résultats
    write.csv(df_tracks_clean, "spotify_analysis_results.csv", row.names = FALSE)
    cat("\nRésultats sauvegardés dans 'spotify_analysis_results.csv'\n")
    
    return(df_tracks_clean)
    
  } else {
    cat("Fichier tracks_features.csv non trouvé. Analyse limitée aux top tracks.\n")
    return(df_tracks)
  }
}

# ===============================================
# FONCTIONS UTILITAIRES
# ===============================================

# Fonction pour afficher des statistiques sur les données
show_stats <- function(df) {
  cat("\n=== STATISTIQUES DES DONNÉES ===\n")
  cat("Dimensions:", dim(df), "\n")
  cat("Colonnes:", paste(names(df), collapse = ", "), "\n")
  
  if ("popularity" %in% names(df)) {
    cat("Popularité moyenne:", round(mean(df$popularity, na.rm = TRUE), 2), "\n")
  }
  
  if ("energy" %in% names(df)) {
    cat("Énergie moyenne:", round(mean(df$energy, na.rm = TRUE), 3), "\n")
  }
  
  if ("valence" %in% names(df)) {
    cat("Valence moyenne:", round(mean(df$valence, na.rm = TRUE), 3), "\n")
  }
}

# ===============================================
# EXÉCUTION
# ===============================================

# Décommenter la ligne suivante pour exécuter l'analyse complète
# results <- main_analysis()

# Ou exécuter étape par étape :
cat("Script R prêt à l'exécution!\n")
cat("Utilisez main_analysis() pour lancer l'analyse complète\n")
cat("Ou exécutez les fonctions individuellement selon vos besoins\n")