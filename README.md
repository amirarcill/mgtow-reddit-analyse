# Analyse du discours MGTOW sur Reddit
### Méthodes Algorithmiques S2 — M1 Sociologie Contemporaine | Sorbonne Université
**Professeure : Floriana Gargiulo (GEMASS-CNRS)**

---

## Auteurs

- **Amira Rodriguez Cilleruelo** — M1 Sociologie Contemporaine, Sorbonne Université
- **Bastien Gautron** — M1 Sociologie Contemporaine, Sorbonne Université

---

## Question de recherche

> **« Quels sont les thèmes dominants dans le discours MGTOW sur Reddit, et quel registre émotionnel les accompagne ? »**

---

## Présentation du projet

Ce projet analyse les posts du subreddit **MGTOW** (*Men Going Their Own Way*) extraits de la base `sampleReddit.csv` (2019). Il mobilise les méthodes enseignées dans le cours de Floriana Gargiulo (*Python4SHS*), ici reproduites en R avec les packages équivalents.

MGTOW est une communauté en ligne appartenant à la « manosphère », caractérisée par un discours de désengagement masculin des relations hétérosexuelles. Elle a été bannie de Reddit en 2021 pour contenus haineux, après avoir compté plusieurs centaines de milliers de membres à son apogée.

---

## Données

| Élément | Détail |
|---|---|
| Source | `sampleReddit.csv` — base multi-subreddits |
| Corpus retenu | Subreddit `MGTOW` uniquement |
| Volume | 30 606 posts — 7 variables |
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

## Notes méthodologiques

### Modification de la Figure 5 — suite à l'évaluation

La visualisation *Longueur des posts × Intensité émotionnelle* a été révisée après retour du professeur. La version initiale utilisait une courbe **LOESS** (régression locale non-paramétrique). Elle a été remplacée par une **régression sur axe logarithmique** (`scale_x_log10()`) pour mieux rendre compte de la distribution asymétrique des longueurs de posts, dont la majorité est courte avec quelques valeurs très élevées.

La version LOESS reste disponible dans le script sous le nom `p_longueur_loess`.

### Limite commune aux trois lexiques de sentiment

Les lexiques AFINN, Bing et NRC partagent une limite fondamentale : ils ne comprennent pas le contexte. Un mot comme "love" est toujours codé positivement, quelle que soit la phrase dans laquelle il apparaît. Cette contrainte est particulièrement sensible dans un corpus idéologique comme MGTOW, où des termes codés positivement ("free", "trust", "love") peuvent exprimer des logiques de retrait et d'opposition. Les résultats doivent donc être lus avec précaution et gagneraient à être complétés par une analyse qualitative.

---

## Structure du dépôt

```
mgtow-reddit-analyse/
│
├── README.md                              ← Ce fichier
│
├── scripts/
│   └── script_final_poster_algo.R        ← Script principal commenté
│
├── poster/
│   └── discours_MGTOW_sur_Reddit.png     ← Poster final présenté en cours
│
├── outputs/                              ← Graphiques produits par le script
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
    └── fiche_methodes.md                 ← Description détaillée des méthodes
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

Les graphiques seront automatiquement sauvegardés dans le dossier `outputs/`.

---

## Visualisations produites

| # | Fichier | Description |
|---|---|---|
| 1 | `fig_frequence_mots.png` | Barplot des 20 mots les plus fréquents |
| 2 | `fig_wordcloud_mgtow.png` | Nuage de mots du corpus |
| 3 | `fig_sentiment_mots.png` | Mots positifs vs négatifs (Bing) |
| 4 | `fig_distribution_sentiment.png` | Distribution des scores AFINN par post |
| 5 | `fig_profil_emotionnel.png` | Profil des 8 émotions NRC |
| 6 | `fig_sentiment_hebdomadaire.png` | Évolution hebdomadaire du sentiment (2019) |
| 7 | `fig_contexte_lexical.png` | Contexte lexical de *women*, *love*, *marriage* |
| 8 | `fig_contexte_lexical_sans_repet.png` | Idem, sans auto-occurrences du mot-clé |
| 9 | `fig_longueur_sentiment.png` | Longueur × intensité émotionnelle (version initiale) |
| 10 | `fig_longueur_sentiment_filtre.png` | Idem, valeurs extrêmes exclues (top 1%) |
| 11 | `fig_longueur_sentiment_loess.png` | Idem, courbe LOESS (version pré-révision) |

---

## Références

- Gargiulo, F. — *Python4SHS*, Notebook 9 : NLP. Sorbonne Université / GEMASS-CNRS. [GitHub](https://github.com/FlorianaGargiulo/Python4SHS)
- Jones, C., Trott, V., & Wright, S. (2019). Salopes et garçons efféminés : MGTOW et la production de harcèlement misogyne en ligne. *New Media & Society*, 22(10). https://doi.org/10.1177/1461444819887141
- Wright, S., Trott, V., & Jones, C. (2020). « La chatte n'en vaut pas la peine, mec » : analyse du discours et de la structure du mouvement MGTOW. *Information, Communication & Society*, 908–925. https://doi.org/10.1080/1369118X.2020.1751867
- Fowler, J. (2025). The masculinities and emotions of men going their own way. *Journal of Right-Wing Studies*, 3(1).
- Mohammad, S. & Turney, P. (2013). Crowdsourcing a Word-Emotion Association Lexicon. *Computational Intelligence*.
- Silge, J. & Robinson, D. (2017). *Text Mining with R*. O'Reilly. [tidytextmining.com](https://www.tidytextmining.com/)

---

*Projet réalisé par Amira Rodriguez Cilleruelo et Bastien Gautron dans le cadre du M1 Sociologie Contemporaine, Sorbonne Université, 2024-2025.*
