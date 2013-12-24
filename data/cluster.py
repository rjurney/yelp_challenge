from pylab import plot,show
import numpy as np
from numpy import vstack,array
from numpy.random import rand
from scipy.cluster.vq import kmeans,vq

X = []
f = open('yelp_phoenix_academic_dataset/locations.tsv/part-m-00000')
for line in f:
    business_id, latitude, longitude = line.rstrip().split('\t')
    X.append([float(latitude), float(longitude)])
data = np.array(X)
data


# computing K-Means with K = 2 (2 clusters)
centroids,_ = kmeans(data,2)
# assign each sample to a cluster
idx,_ = vq(data,centroids)

# some plotting using numpy's logical indexing
plot(data[idx==0,0],data[idx==0,1],'ob',
     data[idx==1,0],data[idx==1,1],'or')
plot(centroids[:,0],centroids[:,1],'sg',markersize=8)
# From example at http://scikit-learn.org/stable/auto_examples/cluster/plot_dbscan.html#example-cluster-plot-dbscan-py
from sklearn.cluster import DBSCAN
from sklearn import metrics
from sklearn.datasets.samples_generator import make_blobs
from sklearn.preprocessing import StandardScaler

X = StandardScaler().fit_transform(X)
X
db = DBSCAN(eps=0.3, min_samples=10).fit(X)
core_samples = db.core_sample_indices_
core_samples
labels = db.labels_
labels
n_clusters_ = len(set(labels)) - (1 if -1 in labels else 0)
n_clusters_
unique_labels = set(labels)
import pylab as pl
colors = pl.cm.Spectral(np.linspace(0, 1, len(unique_labels)))
for k, col in zip(unique_labels, colors):
    if k == -1:
        # Black used for noise.
        col = 'k'
        markersize = 6
    class_members = [index[0] for index in np.argwhere(labels == k)]
    cluster_core_samples = [index for index in core_samples
                            if labels[index] == k]
    for index in class_members:
        x = X[index]
        if index in core_samples and k != -1:
            markersize = 14
        else:
            markersize = 6
        pl.plot(x[0], x[1], 'o', markerfacecolor=col,
                markeredgecolor='k', markersize=markersize)
pl.title('Estimated number of clusters: %d' % n_clusters_)
