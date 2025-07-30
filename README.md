# Spotify Data Analysis - en R


## 📋 Prérequis

### Configuration Spotify
1. Créez une application sur [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Ajoutez `http://localhost:8000/callback` dans les Redirect URIs
3. Récupérez votre `Client ID` et `Client Secret`

### Installation R
Assurez-vous d'avoir R installé (version 4.0+) avec les packages suivaires :

```r
source("install_packages.R")
```

## 🚀 Configuration

1. **Copiez le fichier de configuration** :
   ```bash
   cp config.example.R config.R
   ```

2. **Éditez `config.R`** avec vos identifiants Spotify :
   ```r
   CLIENT_ID <- "votre_client_id_ici"
   CLIENT_SECRET <- "votre_client_secret_ici"
   ```

3. **Assurez-vous que `config.R` est dans votre `.gitignore`**

## 📁 Structure du projet

```
spotify_r/
├── spotify_analysis.R      # Script principal (notebook converti)
├── install_packages.R      # Installation des dépendances
├── config.R               # Vos identifiants (ignoré par Git)
├── config.example.R       # Exemple de configuration
├── tracks_features.csv    # Dataset (optionnel, ignoré par Git)
└── .gitignore            # Fichiers à ignorer
```

## 🎯 Utilisation

### Méthode 1 : Analyse complète automatique
```r
source("spotify_analysis.R")
results <- main_analysis()
```

### Méthode 2 : Étape par étape
```r
source("spotify_analysis.R")

# 1. Authentification OAuth
run_oauth_server()

# 2. Récupérer vos top tracks
top_tracks <- get_top_tracks(limit = 50)

# 3. Convertir en DataFrame
df_tracks <- tracks_to_dataframe(top_tracks)

# 4. Afficher les statistiques
show_stats(df_tracks)
```

## 🔄 Principales conversions Python → R

| Python | R | Description |
|--------|---|-------------|
| `requests` | `httr` | Requêtes HTTP |
| `pandas` | `dplyr` | Manipulation de données |
| `base64` | `base64enc` | Encodage base64 |
| `http.server` | `httpuv` | Serveur HTTP local |
| `pd.DataFrame()` | `data.frame()` | Structures de données |
| `pd.merge()` | `merge()` | Fusion de DataFrames |
| `df.head()` | `head(df)` | Aperçu des données |

## 📊 Fonctionnalités

✅ **Authentification OAuth Spotify**  
✅ **Récupération des top tracks**  
✅ **Conversion en DataFrame R**  
✅ **Fusion avec dataset externe**  
✅ **Récupération des genres musicaux**  
✅ **Analyse des caractéristiques audio**  
✅ **Export des résultats en CSV**  

## 🛠️ Fonctions principales

- `run_oauth_server()` : Lance l'authentification OAuth
- `get_top_tracks()` : Récupère vos morceaux préférés
- `tracks_to_dataframe()` : Convertit les données en DataFrame
- `get_genres_for_artist()` : Récupère les genres d'un artiste
- `add_genres_to_dataframe()` : Ajoute les genres au DataFrame
- `main_analysis()` : Lance l'analyse complète
- `show_stats()` : Affiche les statistiques

## 🔍 Données récupérées

### Métadonnées des morceaux
- Nom, artiste, album
- Popularité
- ID Spotify

### Caractéristiques audio (si tracks_features.csv disponible)
- Danceability, Energy, Valence
- Tempo, Key, Mode
- Acousticness, Speechiness
- Liveness, Instrumentalness

### Genres musicaux
- Récupérés via l'API Spotify Artists

## 📈 Résultats

Les résultats sont sauvegardés dans `spotify_analysis_results.csv` et contiennent :
- Toutes les caractéristiques audio
- Les genres associés
- Données prêtes pour l'analyse statistique

## 🚨 Problèmes courants

### Token expiré
```r
# Relancez l'authentification
run_oauth_server()
```

### Fichier CSV volumineux
```r
# Le fichier tracks_features.csv est optionnel
# L'analyse fonctionne sans lui (fonctionnalités limitées)
```

### Erreur de packages
```r
# Réinstallez les dépendances
source("install_packages.R")
```

## 🎨 Personnalisation

Vous pouvez modifier :
- Le nombre de tracks récupérés (paramètre `limit`)
- La période d'analyse (`short_term`, `medium_term`, `long_term`)
- Les colonnes analysées dans `audio_features`

## 📝 Notes

- Le serveur OAuth se lance automatiquement sur le port 8000
- Les données sont traitées en mémoire (pas de stockage persistant des tokens)
- Compatible avec RStudio et R en ligne de commande
- Respecte les limites de l'API Spotify

## 🤝 Contribution

N'hésitez pas à améliorer le code et proposer des fonctionnalités supplémentaires !

---

**Happy coding! 🎵✨**