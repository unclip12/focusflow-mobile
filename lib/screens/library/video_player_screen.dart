import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:focusflow_mobile/screens/library/immersive_attachment_scaffold.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.filePath));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImmersiveAttachmentScaffold(
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: Video(
            controller: controller,
          ),
        ),
      ),
    );
  }
}
