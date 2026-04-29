from sklearn.neighbors import KNeighborsClassifier

centroids = [
    (17, 83), (50, 83), (83, 83),  # High Compliance row
    (17, 50), (50, 50), (83, 50),  # Mid Compliance row
    (17, 17), (50, 17), (83, 17),  # Low Compliance row
]

classes = [
           "Compliant", "Nervous", "Volatile",
           "Calm", "Guarded", "Hostile",
           "Distant", "Defiant", "Explosive",
]

x, y = zip(*centroids)
x, y = list(x), list(y)

knn = KNeighborsClassifier(n_neighbors=1)

knn.fit(centroids, classes)

def getMood(aggression: int, compliance: int):
    prediction = knn.predict([[aggression, compliance]])
    return prediction[0]