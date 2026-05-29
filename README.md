# Analyse du discours MGTOW sur Reddit
### Méthodes Algorithmiques S2 — M1 Sociologie Contemporaine | Sorbonne Université
**Professeure : Floriana Gargiulo (GEMASS-CNRS)**

---

## Question de recherche

> **« Quels sont les thèmes dominants dans le discours MGTOW sur Reddit, et quel registre émotionnel les accompagne ? »**

---

## Présentation du projet

Ce projet analyse les posts du subreddit **MGTOW** (*Men Going Their Own Way*) extraits de la base `sampleReddit.csv` (2019). Il mobilise les méthodes enseignées dans le cours de Floriana Gargiulo (*Python4SHS*), ici reproduites en R avec les packages équivalents.

MGTOW est une communauté en ligne appartenant à la « manosphère », caractérisée par un discours de désengagement masculin des relations hétérosexuelles (Ribeiro et al., 2021).

---

## Données

| Élément | Détail |
|---|---|
| Source | `sampleReddit.csv` — base multi-subreddits |
| Corpus retenu | Subreddit `MGTOW` uniquement |
| Période couverte | 2019 (majorité des posts) |
| Variable texte | `text_post` |
| Variable temporelle | `date_post` (timestamp Unix → converti en date) |

> 📂 Le fichier de données est disponible sur le dépôt public de la professeure : [FlorianaGargiulo/Python4SHS](https://github.com/FlorianaGargiulo/Python4SHS)

---

## Méthodes mobilisées

Chaque méthode R est mise en correspondance avec son équivalent du cours Python de Gargiulo (Notebook 9 — NLP).

| Étape | R (ce projet) | Python (cours Gargiulo) |
|---|---|---|
| Tokenisation | `unnest_tokens()` | `word_tokenize()` (NLTK) |
| Suppression stopwords | `anti_join(stop_words)` | `stopwords.words('english')` |
| Stemming | `wordStem()` (SnowballC) | `PorterStemmer()` (NLTK) |
| Bag-of-Words | `count()` + matrice termes-documents | `CountVectorizer` (scikit-learn) |
| Sentiment (score continu) | `get_sentiments("afinn")` | `SentimentIntensityAnalyzer` VADER |
| Sentiment (binaire) | `get_sentiments("bing")` | Approche lexicale positive/négative |
| Profil émotionnel | `get_sentiments("nrc")` | Catégories émotionnelles NRC |
| Contexte lexical | Fenêtre ± 5 mots + `inner_join()` | Co-occurrences (cours Gargiulo) |
| Visualisation | `ggplot2` | `matplotlib` / `seaborn` |

---

## Structure du dépôt

```
mgtow-reddit-analyse/
│
├── README.md                              ← Ce fichier
│
├── poster/
│   └── poster_mgtow_final.png             ← Poster final (Canva export)
│
├── scripts/
│   └── script_final_poster_algo.R        ← Script principal commenté
│
├── outputs/                               ← Graphiques produits par le script
│   ├── fig_frequence_mots.png
│   ├── fig_wordcloud_mgtow.png
│   ├── fig_sentiment_mots.png
│   ├── fig_distribution_sentiment.png
│   ├── fig_profil_emotionnel.png
│   ├── fig_sentiment_hebdomadaire.png
│   ├── fig_contexte_lexical.png
│   ├── fig_contexte_lexical_sans_repet.png
│   ├── fig_longueur_sentiment.png
│   ├── fig_longueur_sentiment_filtre.png
│   └── fig_longueur_sentiment_loess.png
│
└── fiches/
    └── fiche_methodes.md                  ← Description détaillée des méthodes
```

---

## Packages R requis

```r
install.packages(c(
  "tidyverse",    # manipulation de données (dplyr, ggplot2, tidyr...)
  "tidytext",     # tokenisation et analyse textuelle tidy
  "tm",           # text mining
  "wordcloud",    # nuages de mots
  "RColorBrewer", # palettes de couleurs
  "textdata",     # lexiques AFINN, Bing, NRC
  "SnowballC",    # stemming de Porter
  "scales",       # mise en forme des axes ggplot2
  "reshape2",     # transformation de matrices
  "lubridate"     # manipulation des dates
))
```

---

## Reproductibilité

1. Cloner ce dépôt
2. Placer `sampleReddit.csv` dans le répertoire de votre choix
3. Modifier la ligne suivante dans le script :

```r
chemin_fichier <- "C:/Sorbonne/Méthodes algorithmiques S2/sampleReddit.csv"
# → remplacer par votre chemin local
```

4. Exécuter `scripts/script_final_poster_algo.R` dans RStudio

---

## Visualisations produites

1. **Barplot des 20 mots les plus fréquents** — vocabulaire dominant du corpus
2. **Nuage de mots** — aperçu visuel du lexique MGTOW
3. **Mots positifs vs négatifs** (lexique Bing) — tonalité lexicale
4. **Distribution des scores de sentiment** (AFINN) — profil global du corpus
5. **Profil émotionnel** (NRC) — 8 émotions de base
6. **Évolution hebdomadaire du sentiment** (2019) — dynamique temporelle
7. **Contexte lexical des mots-clés** (*women*, *love*, *marriage*) — analyse KWIC
8. **Contexte lexical sans auto-occurrences** — version nettoyée de l'analyse KWIC
9. **Longueur des posts × intensité émotionnelle** — régression linéaire par tonalité
10. **Longueur des posts × intensité émotionnelle** — valeurs extrêmes exclues (top 1%)
11. **Longueur des posts × intensité émotionnelle** — courbe LOESS

---

## Références

- Gargiulo, F. — *Python4SHS*, Notebook 9 : NLP. Sorbonne Université / GEMASS-CNRS. [GitHub](https://github.com/FlorianaGargiulo/Python4SHS)
- Ribeiro, M. H. et al. (2021). « Auditing Radicalization Pathways on YouTube ». *ACM FAccT*.
- Mohammad, S. & Turney, P. (2013). « Crowdsourcing a Word-Emotion Association Lexicon ». *Computational Intelligence*.
- Silge, J. & Robinson, D. (2017). *Text Mining with R*. O'Reilly. [tidytextmining.com](https://www.tidytextmining.com/)

---

## Poster

![Poster MGTOW](poster/poster_mgtow_final.png)

---

*Projet réalisé dans le cadre du M1 Sociologie Contemporaine, Sorbonne Université, 2024-2025.*
