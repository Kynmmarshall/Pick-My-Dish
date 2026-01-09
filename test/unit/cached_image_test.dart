import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_dish/widgets/cached_image.dart';

class _FakeImageProvider extends ImageProvider<_FakeImageProvider> {
  const _FakeImageProvider();

  @override
  Future<_FakeImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _FakeImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.white);
    final picture = recorder.endRecording();
    final imageFuture = picture.toImage(1, 1);
    return OneFrameImageStreamCompleter(
      imageFuture.then((image) => ImageInfo(image: image)),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CachedProfileImage', () {
    testWidgets('renders CircleAvatar for asset paths', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CachedProfileImage(
            imagePath: 'assets/login/noPicture.png',
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('renders injected image provider for profile pictures', (tester) async {
      const provider = _FakeImageProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: CachedProfileImage(
            imagePath: 'uploads/profile.png',
            testImageProvider: provider,
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('renders non-profile container with decoration', (tester) async {
      const provider = _FakeImageProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: CachedProfileImage(
            key: const Key('rect-image'),
            imagePath: 'uploads/cover.png',
            isProfilePicture: false,
            width: 120,
            height: 80,
            testImageProvider: provider,
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byKey(const Key('rect-image')), findsOneWidget);
    });

    testWidgets('can force placeholder rendering for tests', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CachedProfileImage(
            imagePath: 'uploads/loading.png',
            testShowPlaceholder: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('can force error widget rendering for tests', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CachedProfileImage(
            imagePath: 'uploads/error.png',
            testShowError: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });
  });
}
