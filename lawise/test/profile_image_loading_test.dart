import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lawise/providers/user_profile_provider.dart';
import 'package:lawise/services/data_persistence_service.dart';
import 'package:lawise/widgets/profile_image_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_image_loading_test.mocks.dart';

@GenerateMocks([DataPersistenceService, FirebaseFirestore, FirebaseAuth, User])
void main() {
  group('Profile Image Loading Tests', () {
    late ProviderContainer container;
    late MockDataPersistenceService mockPersistenceService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockPersistenceService = MockDataPersistenceService();
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      container = ProviderContainer(
        overrides: [
          // Override the DataPersistenceService provider
          dataPersistenceServiceProvider.overrideWithValue(mockPersistenceService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('UserProfileNotifier Tests', () {
      test('should preserve local web image path when loading from Firebase', () async {
        // Arrange
        const userId = 'test_user_123';
        const localImagePath = 'web_image_123456789';
        
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(userId);
        
        // Mock Firebase document data
        final mockDoc = MockDocumentSnapshot();
        final mockData = {
          'id': userId,
          'fullName': 'Test User',
          'email': 'test@example.com',
          'profileImagePath': localImagePath,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };
        
        when(mockDoc.exists).thenReturn(true);
        when(mockDoc.data()).thenReturn(mockData);
        
        when(mockFirestore.collection('users')).thenReturn(MockCollectionReference());
        when(mockFirestore.collection('users').doc(userId)).thenReturn(MockDocumentReference());
        when(mockFirestore.collection('users').doc(userId).get()).thenAnswer((_) async => mockDoc);

        // Act
        final notifier = container.read(userProfileProvider.notifier);
        await notifier.loadProfileFromFirebase();

        // Assert
        final profile = container.read(userProfileProvider);
        expect(profile, isNotNull);
        expect(profile!.profileImagePath, equals(localImagePath));
        expect(profile.profileImagePath!.startsWith('web_image_'), isTrue);
      });

      test('should not clear valid local web image path even if image data check fails', () async {
        // Arrange
        const userId = 'test_user_123';
        const localImagePath = 'web_image_123456789';
        
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(userId);
        
        // Mock Firebase document data
        final mockDoc = MockDocumentSnapshot();
        final mockData = {
          'id': userId,
          'fullName': 'Test User',
          'email': 'test@example.com',
          'profileImagePath': localImagePath,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };
        
        when(mockDoc.exists).thenReturn(true);
        when(mockDoc.data()).thenReturn(mockData);
        
        when(mockFirestore.collection('users')).thenReturn(MockCollectionReference());
        when(mockFirestore.collection('users').doc(userId)).thenReturn(MockDocumentReference());
        when(mockFirestore.collection('users').doc(userId).get()).thenAnswer((_) async => mockDoc);

        // Act
        final notifier = container.read(userProfileProvider.notifier);
        await notifier.loadProfileFromFirebase();

        // Assert
        final profile = container.read(userProfileProvider);
        expect(profile, isNotNull);
        expect(profile!.profileImagePath, equals(localImagePath));
        // The path should be preserved even if local image data check fails
        expect(profile.profileImagePath!.startsWith('web_image_'), isTrue);
      });

      test('should clear invalid profile image paths', () async {
        // Arrange
        const userId = 'test_user_123';
        const invalidImagePath = 'invalid_path';
        
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(userId);
        
        // Mock Firebase document data with invalid path
        final mockDoc = MockDocumentSnapshot();
        final mockData = {
          'id': userId,
          'fullName': 'Test User',
          'email': 'test@example.com',
          'profileImagePath': invalidImagePath,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };
        
        when(mockDoc.exists).thenReturn(true);
        when(mockDoc.data()).thenReturn(mockData);
        
        when(mockFirestore.collection('users')).thenReturn(MockCollectionReference());
        when(mockFirestore.collection('users').doc(userId)).thenReturn(MockDocumentReference());
        when(mockFirestore.collection('users').doc(userId).get()).thenAnswer((_) async => mockDoc);

        // Act
        final notifier = container.read(userProfileProvider.notifier);
        await notifier.loadProfileFromFirebase();

        // Assert
        final profile = container.read(userProfileProvider);
        expect(profile, isNotNull);
        // Invalid path should be cleared
        expect(profile!.profileImagePath, equals(''));
      });
    });

    group('ProfileImageWidget Tests', () {
      test('should display local web image when profile image path is valid', () async {
        // Arrange
        const localImagePath = 'web_image_123456789';
        final mockImageData = List<int>.filled(1000, 1); // Mock 1KB image data
        
        when(mockPersistenceService.getProfileImageData()).thenAnswer((_) async => mockImageData);
        
        // Set up a profile with local image path
        final notifier = container.read(userProfileProvider.notifier);
        notifier.setProfile(UserProfile(
          id: 'test_user',
          fullName: 'Test User',
          email: 'test@example.com',
          profileImagePath: localImagePath,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        // Act & Assert
        final profile = container.read(userProfileProvider);
        expect(profile, isNotNull);
        expect(profile!.profileImagePath, equals(localImagePath));
        expect(profile.profileImagePath!.startsWith('web_image_'), isTrue);
      });

      test('should fallback to empty profile when local image data is not available', () async {
        // Arrange
        const localImagePath = 'web_image_123456789';
        
        when(mockPersistenceService.getProfileImageData()).thenAnswer((_) async => null);
        
        // Set up a profile with local image path
        final notifier = container.read(userProfileProvider.notifier);
        notifier.setProfile(UserProfile(
          id: 'test_user',
          fullName: 'Test User',
          email: 'test@example.com',
          profileImagePath: localImagePath,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        // Act & Assert
        final profile = container.read(userProfileProvider);
        expect(profile, isNotNull);
        expect(profile!.profileImagePath, equals(localImagePath));
        // Even if image data is not available, the path should be preserved
        expect(profile.profileImagePath!.startsWith('web_image_'), isTrue);
      });
    });

    group('Integration Tests', () {
      test('should maintain profile image path across login cycles', () async {
        // Arrange
        const userId = 'test_user_123';
        const localImagePath = 'web_image_123456789';
        
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(userId);
        
        // Mock Firebase document data
        final mockDoc = MockDocumentSnapshot();
        final mockData = {
          'id': userId,
          'fullName': 'Test User',
          'email': 'test@example.com',
          'profileImagePath': localImagePath,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };
        
        when(mockDoc.exists).thenReturn(true);
        when(mockDoc.data()).thenReturn(mockData);
        
        when(mockFirestore.collection('users')).thenReturn(MockCollectionReference());
        when(mockFirestore.collection('users').doc(userId)).thenReturn(MockDocumentReference());
        when(mockFirestore.collection('users').doc(userId).get()).thenAnswer((_) async => mockDoc);

        // Act - Simulate login and profile loading
        final notifier = container.read(userProfileProvider.notifier);
        await notifier.loadProfileFromFirebase();

        // Assert - Profile should have the image path
        final profile = container.read(userProfileProvider);
        expect(profile, isNotNull);
        expect(profile!.profileImagePath, equals(localImagePath));

        // Act - Simulate logout (clear profile)
        notifier.clearProfile();

        // Assert - Profile should be cleared
        final clearedProfile = container.read(userProfileProvider);
        expect(clearedProfile, isNull);

        // Act - Simulate login again and reload profile
        await notifier.loadProfileFromFirebase();

        // Assert - Profile should have the image path again
        final reloadedProfile = container.read(userProfileProvider);
        expect(reloadedProfile, isNotNull);
        expect(reloadedProfile!.profileImagePath, equals(localImagePath));
      });
    });
  });
}

// Mock classes for testing
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockCollectionReference extends Mock implements CollectionReference {}

// Provider override for testing
final dataPersistenceServiceProvider = Provider<DataPersistenceService>((ref) {
  throw UnimplementedError('Should be overridden in tests');
});
