# =============================================================================
# PROJET : Méthodes Algorithmiques S2 — M1 Sociologie Contemporaine
# =============================================================================

# QUESTION DE RECHERCHE :
# « Quels sont les thèmes dominants dans le discours MGTOW sur Reddit,
#   et quel registre émotionnel les accompagne ? »

# NOTE : Python (scikit-learn, NLTK, VADER),
# mais nous reproduisons ici la même logique en R, avec les packages
# équivalents : tidytext, topicmodels, textdata, ggplot2.


# Ce script utilise le "tidyverse" (dialecte R moderne) qui ressemble à pandas.
# Principaux équivalents :
#   Python                  →  R (tidyverse)
#   df.filter()             →  filter()
#   df['col']               →  df$col ou select(col)
#   df.groupby().agg()      →  group_by() %>% summarise()
#   df.merge()              →  left_join(), inner_join()
#   L'opérateur %>% (pipe)  =  "puis" (chaîne les opérations)
# =============================================================================



# ─────────────────────────────────────────────────────────────────────────────
# PARTIE 0 : INSTALLATION DES PACKAGES
# ─────────────────────────────────────────────────────────────────────────────

# install.packages(c(
#   "tidyverse",      # manipulation de données (dplyr, ggplot2, tidyr...)
#   "tidytext",       # tokenisation et analyse textuelle tidy
#   "tm",             # outils de text mining (DocumentTermMatrix)
#   "wordcloud",      # nuages de mots
#   "RColorBrewer",   # palettes de couleurs
#   "textdata",       # lexiques de sentiment (AFINN, Bing, NRC)
#   "SnowballC",      # stemming / lemmatisation
#   "scales",         # mise en forme des axes dans ggplot2
#   "reshape2",       # pour transformer des matrices en format long
#   "lubridate"       # manipulation des dates
# ))

# Charger les librairies
library(tidyverse)
library(tidytext)
library(topicmodels)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(textdata)
library(SnowballC)
library(scales)
library(reshape2)
library(lubridate)
library(dplyr)
library(stringr)
library(lubridate)
library(ggplot2)



# ─────────────────────────────────────────────────────────────────────────────
# PARTIE 1 : CHARGEMENT ET NETTOYAGE DES DONNÉES
# ─────────────────────────────────────────────────────────────────────────────


# 1.1 Charger la base de données complète

# Le fichier sampleReddit.csv contient des posts de plusieurs subreddits.
# objectif : extraire uniquement les posts du subreddit MGTOW.

chemin_fichier <- "C:/Sorbonne/Méthodes algorithmiques S2/sampleReddit.csv"
df_complet <- read.csv(chemin_fichier, sep = ";", stringsAsFactors = FALSE)

# 1.2 Explorer la base
head(df_complet)
str(df_complet)


# 1.3 Identifier la colonne du subreddit

# On regarde les subreddits disponibles pour comprendre la structure
# (en Python on ferait : df['subreddit'].value_counts())
table_subreddits <- sort(table(df_complet$subreddit), decreasing = TRUE)
print(table_subreddits)


# 1.4 Filtrer uniquement le subreddit MGTOW

# C'est ici qu'on crée notre corpus de travail : on ne garde que MGTOW.
# MGTOW = "Men Going Their Own Way", communauté masculiniste/antiféministe
# faisant partie de la « manosphère » (cf. Ribeiro et al., 2021).

df_mgtow <- df_complet %>%
  filter(subreddit == "MGTOW")

head(df_mgtow)



# NOTE IMPORTANTE POUR PYTHON :
# L'opérateur %>% ("pipe") est l'équivalent de .method_chaining en pandas
# Exemple :
#   Python:  df.filter().groupby().mean()
#   R:       df %>% filter() %>% group_by() %>% summarise(mean())




# 1.5 Sauvegarder la base nettoyée
write.csv(df_mgtow,
          "C:/Sorbonne/Méthodes algorithmiques S2/mgtow-reddit-analyse/outputs/mgtow_corpus.csv",
          row.names = FALSE)




# ─────────────────────────────────────────────────────────────────────────────
# PARTIE 2 : PRÉTRAITEMENT DU TEXTE (TEXT PREPROCESSING)
# ─────────────────────────────────────────────────────────────────────────────
# Étapes :
#   1. Mettre en minuscules (text.lower() en Python)
#   2. Supprimer les caractères spéciaux (re.sub() en Python)
#   3. Tokenisation (word_tokenize() en Python, unnest_tokens() en R)
#   4. Suppression des stopwords (NLTK stopwords en Python)
#   5. Lemmatisation / stemming (WordNetLemmatizer en Python)

# En R, le package tidytext fait tout ça de manière « tidy » (une ligne = un token).



# 2.1 Identifier la colonne de texte
# On essaie de trouver la colonne contenant le texte des posts
colonnes_texte <- c("text_post")
col_texte <- intersect(colonnes_texte, names(df_mgtow))



# 2.2 Nettoyage du texte brut

# text = text.lower()
# text = re.sub(r'[^\w\s]', '', text)
# En R, on fait la même chose avec mutate() et des expressions régulières.

df_mgtow <- df_mgtow %>%
  mutate(
    # Créer un identifiant unique pour chaque post
    doc_id = row_number(),
    
    # Récupérer le texte depuis la colonne identifiée
    texte_brut = get(col_texte),
    
    # Étape 1 : Mettre en minuscules (cf. text.lower())
    texte_propre = tolower(texte_brut),
    
    # Étape 2 : Supprimer les URLs
    texte_propre = str_remove_all(texte_propre, "https?://\\S+"),
    
    # Étape 3 : Supprimer les mentions de subreddits et utilisateurs
    texte_propre = str_remove_all(texte_propre, "r/\\w+"),
    texte_propre = str_remove_all(texte_propre, "u/\\w+"),
    
    # Étape 4 : Supprimer les caractères spéciaux et la ponctuation
    # (cf. re.sub(r'[^\w\s]', '', text) dans le cours)
    texte_propre = str_remove_all(texte_propre, "[^a-z\\s]"),
    
    # Étape 5 : Supprimer les espaces multiples
    texte_propre = str_squish(texte_propre)
  ) %>%
  # Supprimer les posts vides ou trop courts (moins de 10 caractères)
  filter(nchar(texte_propre) > 10)



# SYNTAXE R vs PYTHON :
# mutate() = créer/modifier des colonnes (comme df['new_col'] = ... en pandas)
# filter() = filtrer les lignes (comme df[df['col'] > 0] en pandas)
# select() = sélectionner des colonnes (comme df[['col1', 'col2']] en pandas)




# 2.3 Tokenisation et suppression des stopwords

#   tokens = word_tokenize(text)
#   tokens = [t for t in tokens if t not in stop_words]

# En R avec tidytext, on utilise unnest_tokens() qui :
#   - tokenise automatiquement
#   - met en minuscules par défaut
# Puis anti_join() pour supprimer les stopwords.
# anti_join() = garder seulement les lignes de tokens_mgtow 
#               qui ne sont PAS dans stop_words
# En Python/pandas : df[~df['word'].isin(stop_words)]


# Tokenisation : chaque mot devient une ligne (format « tidy text »)
tokens_mgtow <- df_mgtow %>%
  select(doc_id, texte_propre) %>%
  unnest_tokens(word, texte_propre)


# Suppression des stopwords anglais
# (cf. stopwords.words('english') dans NLTK)
tokens_mgtow <- tokens_mgtow %>%
  anti_join(stop_words, by = "word")




# 2.4 Suppression des mots trop courts et stemming
# WordNetLemmatizer() en Python.
# En R, wordStem() du package SnowballC (stemming de Porter).

tokens_mgtow <- tokens_mgtow %>%
  filter(nchar(word) > 2) %>%                          # Mots de 3+ lettres
  mutate(word_stem = wordStem(word, language = "en"))   # Stemming anglais


# 2.5 Fréquence des mots
# on calcule la fréquence
# des mots pour avoir une première idée du vocabulaire dominant.

freq_mots <- tokens_mgtow %>%
  count(word, sort = TRUE)

print(head(freq_mots, 20))






# ─────────────────────────────────────────────────────────────────────────────
# PARTIE 3 : VISUALISATION EXPLORATOIRE
# ─────────────────────────────────────────────────────────────────────────────

# 3.1 Barplot des 20 mots les plus fréquents
# (équivalent d'un barplot matplotlib dans le cours Python)

p_freq <- freq_mots %>%
  head(20) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(x = n, y = word, fill = n)) +
  geom_col(show.legend = FALSE) +
  scale_fill_gradient(low = "#56B4E9", high = "#D55E00") +
  labs(
    title = "Les 20 mots les plus fréquents dans le subreddit MGTOW",
    subtitle = "Après nettoyage, suppression des stopwords et stemming",
    x = "Fréquence",
    y = NULL,
    caption = "Source : sampleReddit.csv"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

print(p_freq)

# Sauvegarder le graphique pour le poster
ggsave("C:/Sorbonne/Méthodes algorithmiques S2/mgtow-reddit-analyse/outputs/fig_frequence_mots.png",
       p_freq, width = 10, height = 6, dpi = 300)



# 3.2 Nuage de mots (Wordcloud)

png("C:/Sorbonne/Méthodes algorithmiques S2/mgtow-reddit-analyse/outputs/fig_wordcloud_mgtow.png",
    width = 800, height = 800)
wordcloud(
  words = freq_mots$word,
  freq = freq_mots$n,
  min.freq = 5,
  max.words = 100,
  random.order = FALSE,
  colors = brewer.pal(8, "Set2"),
  scale = c(4, 0.5)
)
title(main = "Nuage de mots (Subreddit MGTOW)", cex.main = 1.5)
dev.off()







# ─────────────────────────────────────────────────────────────────────────────
# PARTIE 4 : ANALYSE DE SENTIMENT
# ─────────────────────────────────────────────────────────────────────────────

#   1. L'approche lexicale (dictionnaire de sentiment — ex. VADER)
#   2. L'approche par modèle pré-entraîné (BERT)

# En R, on utilise l'approche lexicale avec les lexiques, l'équivalent R de VADER :
#   - Bing : classifie chaque mot comme "positive" ou "negative"
#   - AFINN : attribue un score numérique de -5 à +5 à chaque mot
#   - NRC : classifie les émotions (anger, fear, joy, sadness, trust...)




# 4.1 Analyse avec le lexique Bing (positive / negative)
# Le lexique Bing est le plus simple : chaque mot est classé en 2 catégories.

sentiment_bing <- tokens_mgtow %>%
  inner_join(get_sentiments("bing"), by = "word")


# get_sentiments("bing") télécharge automatiquement le lexique si nécessaire
# En Python, cela équivaudrait à :
#   from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
#   analyzer = SentimentIntensityAnalyzer()
# Bing est plus simple que VADER : juste positif/négatif (pas de score continu)



# Compter les mots positifs et négatifs
compte_sentiment <- sentiment_bing %>%
  count(sentiment, sort = TRUE)
print(compte_sentiment)

# Ratio positif / négatif
ratio <- compte_sentiment %>%
  pivot_wider(names_from = sentiment, values_from = n) %>%
  mutate(ratio = positive / negative)

# Les mots les plus fréquents par sentiment
top_mots_sentiment <- sentiment_bing %>%
  count(word, sentiment, sort = TRUE) %>%
  group_by(sentiment) %>%
  slice_max(n, n = 10) %>%
  ungroup()

# Graphique des mots de sentiment
p_sentiment_mots <- top_mots_sentiment %>%
  mutate(word = reorder_within(word, n, sentiment)) %>%
  ggplot(aes(x = n, y = word, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ sentiment, scales = "free_y") +
  scale_y_reordered() +
  scale_fill_manual(values = c("negative" = "#D55E00", "positive" = "#009E73")) +
  labs(
    title = "Mots positifs et négatifs les plus fréquents",
    subtitle = "Analyse de sentiment",
    x = "Fréquence",
    y = NULL,
    caption = "Source : sampleReddit.csv | Lexique Bing"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", size = 12)
  )

print(p_sentiment_mots)
ggsave("C:/Sorbonne/Méthodes algorithmiques S2/mgtow-reddit-analyse/outputs/fig_sentiment_mots.png",
       p_sentiment_mots, width = 10, height = 6, dpi = 300)



# 4.2 Analyse avec le lexique AFINN (score numérique)

# AFINN est plus proche de VADER car il donne un score continu.
# VADER produit un score « compound » entre -1 et +1.
# AFINN donne un score par mot de -5 à +5, qu'on peut agréger par document.

sentiment_afinn <- tokens_mgtow %>%
  inner_join(get_sentiments("afinn"), by = "word")


# Calculer le score moyen de sentiment par document
score_par_doc <- sentiment_afinn %>%
  group_by(doc_id) %>%
  summarise(
    score_sentiment = mean(value),     # Score moyen (comme le compound de VADER)
    nb_mots_sentiment = n(),           # Nombre de mots avec sentiment
    .groups = "drop"
  )


# Distribution du sentiment
p_distrib_sentiment <- score_par_doc %>%
  ggplot(aes(x = score_sentiment)) +
  geom_histogram(binwidth = 0.5, fill = "#56B4E9", color = "white", alpha = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.8) +
  geom_text(aes(x = 0.3, y = Inf, label = "Neutre"),        # ← remplace annotate()
            vjust = 2, color = "red", inherit.aes = FALSE) +
  labs(
    title = "Distribution du score de sentiment dans le corpus MGTOW",
    subtitle = "Score de -5 à +5 par mot, agrégé par post",
    x = "Score de sentiment moyen par post",
    y = "Nombre de posts",
    caption = "Source : sampleReddit.csv | Lexique AFINN"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

print(p_distrib_sentiment)
ggsave("C:/Sorbonne/Méthodes algorithmiques S2/mgtow-reddit-analyse/outputs/fig_distribution_sentiment.png",
       p_distrib_sentiment, width = 10, height = 6, dpi = 300)




# 4.3 Analyse émotionnelle avec le lexique NRC

# Le lexique NRC va plus loin que positif/négatif : il identifie
# 8 émotions (anger, anticipation, disgust, fear, joy, sadness,
# surprise, trust) + positive/negative.
# C'est intéressant sociologiquement pour comprendre le registre
# émotionnel du discours MGTOW.

sentiment_nrc <- tokens_mgtow %>%
  inner_join(get_sentiments("nrc"), by = "word") %>%
  filter(!sentiment %in% c("positive", "negative"))  # Garder seulement les émotions

# Compter les émotions
emotions_count <- sentiment_nrc %>%
  count(sentiment, sort = TRUE)

print(emotions_count)

# Graphique du profil émotionnel
p_emotions <- emotions_count %>%
  mutate(sentiment = reorder(sentiment, n)) %>%
  ggplot(aes(x = n, y = sentiment, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  scale_fill_brewer(palette = "Spectral") +
  labs(
    title = "Profil émotionnel du discours MGTOW",
    subtitle = "Fréquence des 8 émotions de base identifiées dans le corpus",
    x = "Fréquence",
    y = "Émotion",
    caption = "Source : sampleReddit.csv | Lexique NRC (Mohammad & Turney, 2013)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

print(p_emotions)
ggsave("C:/Sorbonne/Méthodes algorithmiques S2/mgtow-reddit-analyse/outputs/fig_profil_emotionnel.png",
       p_emotions, width = 10, height = 6, dpi = 300)




# =============================================================================
# RÉSUMÉ DES VISUALISATIONS CRÉÉES
# =============================================================================

# Cette partie a produit les graphiques suivants :
# 1. fig_frequence_mots.png           - Barplot des 20 mots les plus fréquents
# 2. fig_wordcloud_mgtow.png          - Nuage de mots du corpus MGTOW
# 3. fig_sentiment_mots.png           - Mots positifs vs négatifs (lexique Bing)
# 4. fig_distribution_sentiment.png   - Histogramme des scores AFINN par post
# 5. fig_profil_emotionnel.png        - Barplot des 8 émotions NRC

# NOTA BENE pour la reproductibilité :
# - Pour une utilisation sur un autre ordinateur, modifier la variable "chemin_fichier"
# - Ou utiliser setwd() au début pour définir le répertoire de travail










# ==========================================
# CONTEXTE LEXICAL DES MOTS-CLÉS
# ==========================================

# Tokenisation avec position des mots, on découpe chaque post mots par mots, en conservant leur ordre.
# tokens = word_tokenize(text, language = "english") sur Python.
# La fonction unnest_tokens() découpe les posts en mots. row_number() attribue une position.
# Ceci permet d'ensuite analyser le contexte lexical et les occurences autour des mots clés.

tokens_position <- df_mgtow %>%
  select(doc_id, texte_propre) %>%
  unnest_tokens(word, texte_propre) %>%
  group_by(doc_id) %>%
  mutate(position = row_number()) %>%
  ungroup()


# Mots-clés à analyser, choisit sur la base du contexte du subreddit (désengagement des hommes dans les relations hommes-femmes).
# Équivalent Python :
# tokens_position[tokens_position["word"].isin(mots_cles)]
# La fonction : .isin() de pandas joue le même rôle que %in% dans R.

mots_cles <- c("women", "woman", "love", "marriage", "freedom")


# Position des mots-clés : Repérer dans chaque post la position du mot clé.

positions_mots_cles <- tokens_position %>%
  filter(word %in% mots_cles) %>%
  select(doc_id, mot_cle = word, position_cle = position)


# On récupère les mots situés dans une fenêtre de 5 mots (précédent ou succédant) autour du mot clé.
# On supprime le mot clé lui-même et les mots trop courts aussi.
# Équivalent Python :
# pd.merge(tokens_position, positions_mots_cles, on="doc_id")

mots_autour <- tokens_position %>%
  inner_join(positions_mots_cles, by = "doc_id") %>%
  filter(
    position >= position_cle - 5,
    position <= position_cle + 5,
    position != position_cle
  ) %>%
  anti_join(stop_words, by = "word") %>%
  filter(nchar(word) > 2)


# On garde les 3 mots clés les plus important et filtre quelque mots alentours non pertinent pour l'analyse.
# On recense les mots les plus fréquent autour de chauqe mots clés.
# Équivalent Python :
# mots_autour.groupby(["mot_cle", "word"]).size()

top_mots_clean <- mots_autour %>%
  filter(mot_cle %in% c("women", "love", "marriage")) %>%
  filter(!word %in% c("dont", "deleted", "ampxb")) %>%
  count(mot_cle, word, sort = TRUE) %>%
  group_by(mot_cle) %>%
  slice_max(order_by = n, n = 5, with_ties = FALSE) %>%
  ungroup()


#On visualise les mots les plus fréquents dans le contexte de chaque mots clés.
# Equivalent Python : 
# matplotlib.pyplot.bar() ou pandas.DataFrame.plot.bar()

p_clean <- top_mots_clean %>%
  mutate(word = reorder_within(word, n, mot_cle)) %>%
  ggplot(aes(x = n, y = word, fill = mot_cle)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ mot_cle, scales = "free_y") +
  scale_y_reordered() +
  labs(
    title = "Contexte lexical des mots-clés dans le discours MGTOW",
    subtitle = "Top 5 occurrences locales, fenêtre ± 5 mots",
    x = "Fréquence",
    y = NULL
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )


# Affiche les mots clés sélectionnés et quelles sont les occurences les plus présentes
# Interprétation : contexte fortement lié aux normes hétéros et formes de tensions (divorces). La figure féminine est principalement associée à la relation
# et aux situations perçues comme problématique
# Le contexte lexical est très lié aux relations hétérosexuelles (kids, women...) et aux tensions conjugales.
# Celà semble suggérer que la figure féminine y est associée, c'est à dire à des relations vues comme problématiques.

print(p_clean)


# ============================================================
# ÉVOLUTION HEBDOMADAIRE DU SENTIMENT MGTOW EN 2019 
# ==========================================================


# On supprime les anciennes colonnes de sentiment elles existent. 
# Cela évite les problèmes techniques.

df_mgtow <- df_mgtow %>%
  select(-any_of(c("score_bing", "score_bing.x", "score_bing.y")))


# On prépare les variables nécessaires : identifiant du post, le texte nettoyé, la date, l'année, la semaine.
# Équivalent Python :
# text = text.lower()
# text = re.sub(r'[^\w\s]', '', text)
# Les variables temporelles sont créées à partir des dates de publication. Les posts trop court sont supprimés.

df_mgtow <- df_mgtow %>%
  mutate(
    doc_id = row_number(),
    text_post = ifelse(is.na(text_post), "", text_post),
    
    text_clean = text_post %>%
      str_remove_all("http\\S+|www\\S+") %>%
      str_remove_all("[^a-zA-Z\\s]") %>%
      str_to_lower() %>%
      str_squish(),
    
    date = as.POSIXct(date_post, origin = "1970-01-01", tz = "UTC"),
    date = as.Date(date),
    annee = year(date),
    semaine = floor_date(date, unit = "week", week_start = 1)
  ) %>%
  filter(!is.na(date), nchar(text_clean) > 10)

# On charge le lexique "Bing", ceci permet de classer les mots en deux catégories (positif ou négatif).
# Équivalent Python :
# Dans le notebook, le principe est similaire avec VADER :
# analyzer = SentimentIntensityAnalyzer()

bing <- get_sentiments("bing")


# On calcule le score de sentiment par post. Chaque mot positif correspond à "+1", les mots négatif à "-1".
# Le score correspond à la somme de ces valeurs pour chaque post.
# Équivalent Python :
# Approche lexicale similaire avec VADER :
# scores = analyzer.polarity_scores(phrase)
# La logique entre Bing et Vader est similaire, bing produit un score en additionnat les mots négatifs et positifs,


sentiment_posts <- df_mgtow %>%
  select(doc_id, text_clean) %>%
  unnest_tokens(word, text_clean) %>%
  inner_join(bing, by = "word") %>%
  mutate(score = ifelse(sentiment == "positive", 1, -1)) %>%
  group_by(doc_id) %>%
  summarise(
    score_bing_new = sum(score),
    .groups = "drop"
  )

# On rattache les scores de sentiment à la base de données.
# Les posts sans mot reconnu par le lexique "Bing" reçoivent un score de 0.
# Équivalent Python :
# df_mgtow = df_mgtow.merge(sentiment_posts, on="doc_id", how="left")
# df_mgtow["score_bing"] = df_mgtow["score_bing_new"].fillna(0)

df_mgtow <- df_mgtow %>%
  left_join(sentiment_posts, by = "doc_id") %>%
  mutate(score_bing = ifelse(is.na(score_bing_new), 0, score_bing_new)) %>%
  select(-score_bing_new)


# On garde uniquement l'année 2019, car elle accumule le plus de posts.

df_2019 <- df_mgtow %>%
  filter(annee == 2019)


# On agrège par semaine le score moyen de sentiment ainsi que le nombre de post.

sentiment_2019_semaine <- df_2019 %>%
  group_by(semaine) %>%
  summarise(
    score_moyen = mean(score_bing, na.rm = TRUE),
    n_posts = n(),
    .groups = "drop"
  ) %>%
  arrange(semaine)


# Affichage de la série temporelle hebdomadaire.

print(sentiment_2019_semaine, n = 60)


#On visualise l'évolution hebdomadaire sur la période où des données sont disponibles, la taille des points représente la taille des posts.

p_2019_semaine <- ggplot(sentiment_2019_semaine, aes(x = semaine, y = score_moyen)) +
  geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.7) +
  geom_line(linewidth = 1.1) +
  geom_point(aes(size = n_posts), alpha = 0.8) +
  scale_x_date(
    date_labels = "%d %b",
    date_breaks = "2 weeks"
  ) +
  labs(
    title = "Sentiment hebdomadaire des posts MGTOW en 2019",
    subtitle = "Score moyen par semaine ; taille des points = nombre de posts",
    x = "Semaine",
    y = "Score moyen de sentiment",
    size = "Nombre de posts"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

# Visualisation du graphique.

print(p_2019_semaine)


#Liste des mots à exclure de l'analyse lexicale.

mots_a_exclure <- c("deleted", "ampxb", "im", "dont", "mgtow")


# Fonction qui permet d'identifier la semaine au sentiment moyen le plus positif ou négatif,
# puis d'afficher les 15 mots les plus fréquents dans les posts de cette semaine.
# En Python : idxmax() / idxmin(), puis value_counts().

analyser_pic <- function(type_pic = c("positif", "negatif")) {
  
  type_pic <- match.arg(type_pic)
  
  semaine_pic <- sentiment_2019_semaine %>%
    {if (type_pic == "positif") slice_max(., score_moyen, n = 1)
      else slice_min(., score_moyen, n = 1)} %>%
    pull(semaine)
  
  cat("\n============================\n")
  cat("Pic", type_pic, ":", as.character(semaine_pic), "\n")
  cat("============================\n")
  
  df_2019 %>%
    filter(semaine == semaine_pic) %>%
    unnest_tokens(word, text_clean) %>%
    anti_join(stop_words, by = "word") %>%
    filter(!word %in% mots_a_exclure,
           nchar(word) > 2) %>%
    count(word, sort = TRUE) %>%
    head(15)
}


# Application de la fonction aux pics positif et négatif.

analyser_pic("negatif")
analyser_pic("positif")




# ============================================================
# Version SANS répétition du mot-clé
# On garde mots_autour intact pour l'ancien graphique
# ============================================================


# Suppression des occurences où le mot clé est identique au mot du contexte.
# Équivalent Python :
# mots_autour_sans_repet = mots_autour[mots_autour["word"] != mots_autour["mot_cle"]]

mots_autour_sans_repet <- mots_autour %>%
  filter(word != mot_cle)


#On recompte les mots faisant contexte sans cette répétition.
# Equivalent Python
# mots_autour_sans_repet.groupby(["mot_cle", "word"]).size()
# puis sélection des 5 fréquences les plus élevées pour chaque mot-clé.

top_mots_clean_sans_repet <- mots_autour_sans_repet %>%
  filter(mot_cle %in% c("women", "love", "marriage")) %>%
  filter(!word %in% c("dont", "deleted", "ampxb")) %>%
  count(mot_cle, word, sort = TRUE) %>%
  group_by(mot_cle) %>%
  slice_max(order_by = n, n = 5, with_ties = FALSE) %>%
  ungroup()


# Représentation graphique des contextes lexicaus après la suppresion des auto-occurences.

p_clean_sans_repet <- top_mots_clean_sans_repet %>%
  mutate(word = reorder_within(word, n, mot_cle)) %>%
  ggplot(aes(x = n, y = word, fill = mot_cle)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ mot_cle, scales = "free_y") +
  scale_y_reordered() +
  labs(
    title = "Contexte lexical des mots-clés dans le discours MGTOW",
    subtitle = "Top 5 occurrences locales, fenêtre ± 5 mots — sans répétition du mot-clé",
    x = "Fréquence",
    y = NULL
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )


# Affichage du graphique.

print(p_clean_sans_repet)



# ============================================================
# LONGUEUR DU POST × INTENSITÉ ÉMOTIONNELLE 
# ============================================================



# Création des variables nécessaires à l'analyse sans exclure les
# valeurs extrêmes.
# En Python : .str.len(), .abs() et np.where().

df_plot <- df_mgtow %>%
  mutate(
    longueur_post = nchar(text_post),
    intensite_sentiment = abs(score_bing),
    sentiment = case_when(
      score_bing < 0 ~ "négatif",
      score_bing > 0 ~ "positif",
      TRUE ~ "neutre"
    )
  ) %>%
  filter(longueur_post > 0)

# Visualisation du lien entre longueur des posts et intensité du sentiment.
# En Python : matplotlib.pyplot.scatter() ou seaborn.regplot().
# Une droite de régression est estimée pour chacun des types de tonalité.

p_longueur <- ggplot(
  df_plot,
  aes(
    x = longueur_post,
    y = intensite_sentiment,
    color = sentiment
  )
) +
  geom_point(alpha = 0.35, size = 1.8) +
  geom_smooth(
    aes(group = sentiment, color = sentiment),
    method = "lm",
    se = TRUE,
    linewidth = 1.1
  ) +
  scale_color_manual(
    values = c(
      "négatif" = "red",
      "neutre" = "black",
      "positif" = "green"
    )
  ) +
  labs(
    title = "Longueur des posts et intensité émotionnelle",
    subtitle = "Analyse computationnelle du discours MGTOW",
    x = "Longueur du post (nombre de caractères)",
    y = "Intensité du sentiment",
    color = "Tonalité"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

# Affichage du graphique.

print(p_longueur)




# ===================================================================
# LONGUEUR DU POST × INTENSITÉ ÉMOTIONNELLE sans valeurs aberrantes
# ===================================================================


# On crée des variables nécessaire à l'analyse (la longueur du post en nombre de caractère, l'intensité émotionnelle,
# tonalité générale). L'intensité correspond à la valeur absolue du score Bing.
# En Python : .str.len(), .abs() et np.where().

df_plot <- df_mgtow %>%
  mutate(
    longueur_post = nchar(text_post),
    intensite_sentiment = abs(score_bing),
    sentiment = case_when(
      score_bing < 0 ~ "négatif",
      score_bing > 0 ~ "positif",
      TRUE ~ "neutre"
    )
  ) %>%
  filter(longueur_post > 0)


# On retire les 1% de post les plus long pour avoir une meilleure lisbilité du graphique.
# En Python :
# df_plot_clean = df_plot[df_plot["longueur_post"] <=
#                         df_plot["longueur_post"].quantile(0.99)]

df_plot_clean <- df_plot %>%
  filter(longueur_post <= quantile(longueur_post, 0.99, na.rm = TRUE))


# Visualisation du lien entre longueur des posts et intensité du sentiment.
# En Python : matplotlib.pyplot.scatter() ou seaborn.regplot().
# Les valeurs extrême sont exclues pour une meilleure lisibilité.

p_longueur_filtre <- ggplot(
  df_plot_clean,
  aes(
    x = longueur_post,
    y = intensite_sentiment,
    color = sentiment
  )
) +
  geom_point(alpha = 0.35, size = 1.8) +
  geom_smooth(
    method = "lm",
    se = TRUE,
    linewidth = 1.1
  ) +
  scale_color_manual(
    values = c(
      "négatif" = "red",
      "neutre" = "grey",
      "positif" = "green"
    )
  ) +
  labs(
    title = "Longueur des posts et intensité émotionnelle",
    subtitle = "Valeurs extrêmes exclues (top 1%)",
    x = "Longueur du post (nombre de caractères)",
    y = "Intensité du sentiment",
    color = "Tonalité"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )


# Affichage du graphique.
print(p_longueur_filtre)




# ============================================================
# LONGUEUR DU POST × INTENSITÉ ÉMOTIONNELLE (COURBE LOESS)
# ============================================================



# Nouvelle visualisation du lien entre longueur des posts et intensité du sentiment.
# En Python : matplotlib.pyplot.scatter() et seaborn.regplot(lowess = TRUE).
# Contrairement à une régression linéaire, la courbe LOESS ne suppose pas
# une relation droite entre les variables. Elle permet d'observer une tendance
# sans modifier l'axe en logarithme.

p_longueur_loess <- ggplot(
  df_plot_clean,
  aes(
    x = longueur_post,
    y = intensite_sentiment,
    color = sentiment
  )
) +
  geom_point(alpha = 0.35, size = 1.8) +
  geom_smooth(
    aes(group = sentiment, color = sentiment),
    method = "loess",
    se = TRUE,
    linewidth = 1.1
  ) +
  scale_color_manual(
    values = c(
      "négatif" = "red",
      "neutre" = "grey",
      "positif" = "green"
    )
  ) +
  labs(
    title = "Longueur des posts et intensité émotionnelle",
    subtitle = "Courbe LOESS, valeurs extrêmes exclues (top 1%)",
    x = "Longueur du post (nombre de caractères)",
    y = "Intensité du sentiment",
    color = "Tonalité"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

# Affichage du graphique.
print(p_longueur_loess)


# ================================
# Raccourcis des graphs
# ================================

print(p_clean)
print(p_clean_sans_repet)
print(p_2019_semaine)
print(p_longueur_filtre)
print(p_longueur)
print(p_longueur_loess)