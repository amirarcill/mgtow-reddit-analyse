# Fiche technique — Méthodes mobilisées

## Projet : Analyse du discours MGTOW sur Reddit
*Méthodes Algorithmiques S2 — M1 Sociologie Contemporaine, Sorbonne Université*

---

## 1. Prétraitement du texte

### Objectif
Transformer les posts bruts en tokens exploitables pour l'analyse quantitative.

### Étapes appliquées

| Étape | Fonction R | Équivalent cours (Python) |
|---|---|---|
| Mise en minuscules | `tolower()` | `text.lower()` |
| Suppression URLs | `str_remove_all(texte, "https?://\\S+")` | `re.sub()` |
| Suppression mentions Reddit | `str_remove_all(texte, "r/\\w+")` | `re.sub()` |
| Suppression ponctuation | `str_remove_all(texte, "[^a-z\\s]")` | `re.sub(r'[^\w\s]', '', text)` |
| Tokenisation | `unnest_tokens(word, texte)` | `word_tokenize()` (NLTK) |
| Suppression stopwords | `anti_join(stop_words)` | `stopwords.words('english')` (NLTK) |
| Stemming | `wordStem(word, language="en")` | `PorterStemmer()` (NLTK) |

**Justification** : Ces étapes sont directement issues du Notebook 9 du cours de Gargiulo. Le package `tidytext` reproduit en R la logique « tidy » équivalente au pipeline NLTK enseigné en Python.

---

## 2. Analyse de fréquence (Bag-of-Words)

### Principe
Compter la fréquence de chaque token pour identifier le vocabulaire dominant.

```r
freq_mots <- tokens_mgtow %>% count(word, sort = TRUE)
```

**Équivalent cours** : `CountVectorizer` de scikit-learn (Notebook 9).

**Visualisations** : barplot des 20 mots les plus fréquents, nuage de mots.

---

## 3. Analyse de sentiment

### 3.1 Lexique AFINN — score continu

- Attribue un score de **-5 à +5** à chaque mot
- Score agrégé par post = **moyenne** des scores des mots reconnus
- **Équivalent cours** : score `compound` de VADER (SentimentIntensityAnalyzer)

```r
sentiment_afinn <- tokens_mgtow %>%
  inner_join(get_sentiments("afinn"), by = "word")
```

### 3.2 Lexique Bing — classification binaire

- Classe chaque mot en `positive` ou `negative`
- Score par post = somme (positive = +1, negative = -1)
- Plus simple que VADER mais même logique lexicale

### 3.3 Lexique NRC — profil émotionnel

- Identifie **8 émotions** : anger, anticipation, disgust, fear, joy, sadness, surprise, trust
- Permet une analyse émotionnelle plus fine que le binaire positif/négatif
- **Intérêt sociologique** : caractériser le registre émotionnel dominant du discours MGTOW

**Justification du choix AFINN + NRC** : AFINN est l'équivalent fonctionnel du score compound de VADER (enseigné en cours) ; NRC apporte une profondeur émotionnelle non disponible dans l'approche binaire seule.

---

## 4. Analyse temporelle

### Objectif
Observer l'évolution du sentiment hebdomadaire sur l'année 2019.

### Méthode
1. Conversion du timestamp Unix en date (`as.POSIXct()` + `as.Date()`)
2. Agrégation par semaine (`floor_date(date, unit="week")`)
3. Calcul du score moyen hebdomadaire
4. Visualisation par série temporelle

```r
semaine = floor_date(date, unit = "week", week_start = 1)
```

---

## 5. Contexte lexical (KWIC)

### Objectif
Analyser les mots apparaissant dans le voisinage immédiat de mots-clés sociologiquement pertinents (*women*, *love*, *marriage*).

### Méthode
- Fenêtre de **± 5 mots** autour du mot-clé
- Suppression des stopwords et mots trop courts dans la fenêtre
- Comptage des co-occurrences les plus fréquentes

```r
mots_autour <- tokens_position %>%
  inner_join(positions_mots_cles, by = "doc_id") %>%
  filter(position >= position_cle - 5, position <= position_cle + 5)
```

**Équivalent cours** : logique de co-occurrence enseignée dans le Notebook 9 (Gargiulo).

**Intérêt sociologique** : révéler les associations sémantiques autour des figures féminines et des relations dans le discours MGTOW.

---

## Références méthodologiques

- Gargiulo, F. — *Python4SHS*, Notebook 9. [GitHub](https://github.com/FlorianaGargiulo/Python4SHS)
- Silge, J. & Robinson, D. (2017). *Text Mining with R*. [tidytextmining.com](https://www.tidytextmining.com/)
- Mohammad, S. & Turney, P. (2013). NRC Word-Emotion Association Lexicon.
