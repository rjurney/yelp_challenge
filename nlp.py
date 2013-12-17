
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

f = open('yelp_phoenix_academic_dataset/yelp_academic_dataset_review.json')
lines = f.readlines()

sent_detector = nltk.data.load('tokenizers/punkt/english.pickle')

for line in lines:
    review = json.loads(line)
    sentences = sent_detector.tokenize(review['text'])
    words = nltk.word_tokenize(sentences[0])
    tagged = brill_tagger.tag(words)
    adjectives = []
    for tag in tagged:
        if tag[1].startswith('JJ'):
            adjectives.append(tag[0].lower())
    if adjectives:
        try:
            print review['business_id'] + "\t" + " ".join(adjectives)
        except UnicodeEncodeError:
            pass

