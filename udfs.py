from math import radians, cos, sin, asin, sqrt
from pig_util import outputSchema
import nltk

import nltk, json
from nltk.tag.brill import *

from nltk.corpus import brown
brown_train = list(brown.tagged_sents(categories='news'))
from nltk.corpus import treebank
treebank_train = list(treebank.tagged_sents())
training_data = brown_train + treebank_train

from nltk.tag.sequential import RegexpTagger
regexp_tagger = RegexpTagger(
     [(r'^-?[0-9]+(.[0-9]+)?$', 'CD'),   # cardinal numbers
      (r'(The|the|A|a|An|an)$', 'AT'),   # articles
      (r'.*able$', 'JJ'),                # adjectives
      (r'.*ness$', 'NN'),                # nouns formed from adjectives
      (r'.*ly$', 'RB'),                  # adverbs
      (r'.*s$', 'NNS'),                  # plural nouns
      (r'.*ing$', 'VBG'),                # gerunds
      (r'.*ed$', 'VBD'),                 # past tense verbs
      (r'.*', 'NN')                      # nouns (default)
])

unigram_tagger_2 = nltk.UnigramTagger(brown_train, backoff=regexp_tagger)
templates = [
     SymmetricProximateTokensTemplate(ProximateTagsRule, (1,1)),
     SymmetricProximateTokensTemplate(ProximateTagsRule, (2,2)),
     SymmetricProximateTokensTemplate(ProximateTagsRule, (1,2)),
     SymmetricProximateTokensTemplate(ProximateTagsRule, (1,3)),
     SymmetricProximateTokensTemplate(ProximateWordsRule, (1,1)),
     SymmetricProximateTokensTemplate(ProximateWordsRule, (2,2)),
     SymmetricProximateTokensTemplate(ProximateWordsRule, (1,2)),
     SymmetricProximateTokensTemplate(ProximateWordsRule, (1,3)),
     ProximateTokensTemplate(ProximateTagsRule, (-1, -1), (1,1)),
     ProximateTokensTemplate(ProximateWordsRule, (-1, -1), (1,1)),
     ]
trainer = FastBrillTaggerTrainer(initial_tagger=unigram_tagger_2,
                                  templates=templates, trace=3,
                                  deterministic=True)
brill_tagger = trainer.train(training_data, max_rules=10)

@outputSchema("tokens:chararray")
def adjectives(paragraph):
    adjectives = []
    sentences = nltk.sent_tokenize(paragraph)
    print sentences
    for sentence in sentences:
        words = nltk.word_tokenize(sentence)
        tagged = brill_tagger.tag(words)
        for tag in tagged:
            if tag[1].startswith('JJ'):# | tag[1].startswith('RB'): # Adjectives or adverbs
                adjectives.append(tag[0].lower())
    if adjectives:
        try:
            return " ".join(adjectives)
        except UnicodeEncodeError:
            return "ERROR"
            pass

@outputSchema("distance:double")
def haversine(lon1, lat1, lon2, lat2):
    """
    Calculate the great circle distance between two points
    on the earth (specified in decimal degrees)
    """
    # convert decimal degrees to radians
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    # haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    km = 6367 * c
    return km
