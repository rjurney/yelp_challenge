from math import radians, cos, sin, asin, sqrt
from pig_util import outputSchema
import nltk

from nltk.stem.wordnet import WordNetLemmatizer
lmtzr = WordNetLemmatizer()

from nltk.corpus import stopwords
stopwords = stopwords.words('english')

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

@outputSchema("phrases:bag{t:tuple(phrase:chararray)}")
def noun_phrases(paragraph):
    grammar = r"""
        NBAR:
            {<NN.*|JJ>*<NN.*>}  # Nouns and Adjectives, terminated with Nouns

        NP:
            {<NBAR>}
            {<NBAR><IN><NBAR>}  # Above, connected with in/of/etc...
    """
    chunker = nltk.RegexpParser(grammar)
    sent_detector = nltk.data.load('tokenizers/punkt/english.pickle')
    sentences = sent_detector.tokenize(paragraph.strip())
    words = []
    for sentence in sentences:
        tokens = nltk.word_tokenize(sentence)
        tagged = nltk.pos_tag(tokens)
        tree = chunker.parse(tagged)
        for subtree in tree.subtrees(filter=lambda t: t.node == 'NP'):
            # print the noun phrase as a list of part-of-speech tagged words
            for word in subtree.leaves():
                word = lmtzr.lemmatize(word[0])
                word = word.lower()
                words.append(word)
    words = [word for word in words if len(word) > 3]
    return words
