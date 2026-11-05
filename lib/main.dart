import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const PersianStudio());
}

class PersianStudio extends StatelessWidget {
  const PersianStudio({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'استودیو تدوین فارسی',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101713),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123B2A),
          brightness: Brightness.dark,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: StudioHome(),
      ),
    );
  }
}

class StudioHome extends StatefulWidget {
  const StudioHome({super.key});

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  VideoPlayerController? video;
  String subtitle = 'زیرنویس فارسی شما';

  Future<void> addVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null || result.files.single.path == null) return;

    final next = VideoPlayerController.file(
      File(result.files.single.path!),
    );

    await next.initialize();
    await video?.dispose();

    if (!mounted) {
      await next.dispose();
      return;
    }

    setState(() => video = next);
  }

  @override
  void dispose() {
    video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF123B2A),
        title: const Text('استودیو تدوین فارسی'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'به استودیوی تدوین فارسی خوش آمدید 🇮🇷',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: video?.value.isInitialized == true
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(video!),
                        Positioned(
                          bottom: 12,
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 5,
                                )
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              video!.value.isPlaying
                                  ? video!.pause()
                                  : video!.play();
                            });
                          },
                          icon: Icon(
                            video!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 45,
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        size: 60,
                        color: Colors.amber,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: addVideo,
            icon: const Icon(Icons.video_library),
            label: const Text('انتخاب ویدیو'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              final controller = TextEditingController(text: subtitle);
              final value = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('زیرنویس فارسی'),
                  content: TextField(
                    controller: controller,
                    maxLines: 3,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('انصراف'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        controller.text,
                      ),
                      child: const Text('ذخیره'),
                    ),
                  ],
                ),
              );
              if (value != null) {
                setState(() => subtitle = value);
              }
            },
            icon: const Icon(Icons.subtitles),
            label: const Text('ویرایش زیرنویس'),
          ),
        ],
      ),
    );
  }
}
