import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/project.dart';
import '../domain/models/text_layer.dart';

class FirestoreHelper {
  static final FirestoreHelper instance = FirestoreHelper._init();
  FirestoreHelper._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the cloud projects collection
  CollectionReference get _projectsCollection => _firestore.collection('projects');

  // Save a project and its text layers to Cloud Firestore
  Future<void> saveProject(Project project) async {
    try {
      final projectMap = project.toMap();
      
      // Serialize text layers into a list of maps for NoSQL document storage
      projectMap['textLayers'] = project.textLayers.map((layer) => layer.toMap()).toList();
      
      // Upload to Firestore, using the project's unique UUID as the document ID
      await _projectsCollection.doc(project.id).set(projectMap);
      print('Project successfully synced to Cloud Firestore: ${project.id}');
    } catch (e) {
      print('Cloud Firestore sync failed: $e');
    }
  }

  // Delete a project from Cloud Firestore
  Future<void> deleteProject(String id) async {
    try {
      await _projectsCollection.doc(id).delete();
      print('Project successfully deleted from Cloud Firestore: $id');
    } catch (e) {
      print('Cloud Firestore delete failed: $e');
    }
  }

  // Fetch all projects belonging to a specific user from Cloud Firestore
  Future<List<Project>> getProjectsForUser(String userId) async {
    try {
      // Query the projects collection filtering by userId and sorting by updatedAt
      final querySnapshot = await _projectsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final List<Project> projects = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Deserialize text layers list
        final List<dynamic> layersList = data['textLayers'] as List<dynamic>? ?? [];
        final List<TextLayer> textLayers = layersList
            .map((l) => TextLayer.fromMap(Map<String, dynamic>.from(l as Map)))
            .toList();

        projects.add(Project.fromMap(data, textLayers));
      }

      // Sort in memory by updatedAt DESC (since composite indexes in Firestore are required for multi-field orderBys)
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      print('Successfully fetched ${projects.length} projects from Cloud Firestore');
      return projects;
    } catch (e) {
      print('Cloud Firestore fetch failed: $e');
      return [];
    }
  }
}
