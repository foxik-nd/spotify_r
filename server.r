library(plumber)
library(httr)
library(jsonlite)
library(base64enc)

# Configuration
CLIENT_ID <- ''
CLIENT_SECRET <- ''
REDIRECT_URI <- "http://localhost:8000/callback"
AUTH_URL <- "https://accounts.spotify.com/authorize"
TOKEN_URL <- "https://accounts.spotify.com/api/token"

current_token <- NULL

# home page
function() {
  list(
    message = "Bienvenue",
    login_url = "/login"
  )
}

# Redirection vers l'authentification Spotify
function(res) {
  params <- list(
    client_id = CLIENT_ID,
    response_type = "code",
    redirect_uri = REDIRECT_URI,
    scope = "user-read-private user-read-email user-top-read"
  )
  
  # Construire l'URL avec les paramètres
  auth_url_with_params <- paste0(AUTH_URL, "?", 
                                paste(mapply(function(k, v) paste0(k, "=", URLencode(v)), 
                                           names(params), params), 
                                      collapse = "&"))
  
  # Redirection HTTP
  res$status <- 302
  res$setHeader("Location", auth_url_with_params)
  return()
}

#* Callback après authentification
#* @get /callback
#* @param code:str Code d'autorisation de Spotify
function(code) {
  if (missing(code) || is.null(code)) {
    stop("Code d'autorisation manquant")
  }
  
  # Préparer l'en-tête d'autorisation
  auth_string <- paste0(CLIENT_ID, ":", CLIENT_SECRET)
  auth_header <- paste0("Basic ", base64encode(charToRaw(auth_string)))
  
  # Préparer les données pour l'échange du token
  token_data <- list(
    grant_type = "authorization_code",
    code = code,
    redirect_uri = REDIRECT_URI
  )
  
  # Req
  response <- POST(
    TOKEN_URL,
    add_headers(Authorization = auth_header),
    body = token_data,
    encode = "form"
  )
  
  if (status_code(response) == 200) {
    current_token <<- content(response, "parsed")
    
    return(list(
      message = "Authentification réussie",
      token_info = current_token
    ))
  } else {
    stop("Erreur lors de l'échange du token")
  }
}

#* Obtenir les informations de l'utilisateur
#* @get /me
function() {
  if (is.null(current_token)) {
    stop("Non authentifié")
  }
  
  # Faire la requête à l'API Spotify
  response <- GET(
    "https://api.spotify.com/v1/me",
    add_headers(Authorization = paste0("Bearer ", current_token$access_token))
  )
  
  if (status_code(response) == 200) {
    return(content(response, "parsed"))
  } else {
    stop(paste("Erreur API Spotify, code:", status_code(response)))
  }
}

# Run serveur
#* @plumber
function(pr) {
  pr %>%
    pr_set_error(function(req, res, err) {
      list(error = err$message)
    })
}
