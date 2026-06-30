from sklearn.cluster import KMeans


def assign_behavior_cluster(feature_matrix):
    model = KMeans(n_clusters=3, n_init=10, random_state=42)
    labels = model.fit_predict(feature_matrix)
    return labels.tolist()
