
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:saver_gallery/saver_gallery.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PersianStudio());
}

class PersianStudio extends StatelessWidget {
  const PersianStudio({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'استودیو تدوین فارسی',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101713),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123B2A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
  String? videoPath;

  String subtitle = 'زیرنویس فارسی شما';
  Color subtitleColor = Colors.white;
  double subtitleSize = 22;

  Future<void> importVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;

    try {
      final next = VideoPlayerController.file(File(path));
      await next.initialize();

      await video?.dispose();

      if (!mounted) {
        await next.dispose();
        return;
      }

      setState(() {
        video = next;
        videoPath = path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ویدیو با موفقیت انتخاب شد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در باز کردن ویدیو: $e')),
      );
    }
  }

  Future<void> editSubtitle() async {
    final controller = TextEditingController(text: subtitle);

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ویرایش زیرنویس فارسی'),
        content: TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'متن زیرنویس را بنویسید',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    if (value != null) {
      setState(() => subtitle = value);
    }
  }

  Future<void> openTrimmer() async {
    if (videoPath == null || video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ابتدا یک ویدیو انتخاب کن'),
        ),
      );
      return;
    }

    if (!video!.value.isInitialized ||
        video!.value.duration.inMilliseconds < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مدت ویدیو مناسب برش نیست')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrimPage(
          videoPath: videoPath!,
          duration: video!.value.duration,
        ),
      ),
    );
  }

  @override
  void dispose() {
    video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = video;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF123B2A),
        title: const Text(
          'استودیو تدوین فارسی',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: importVideo,
            icon: const Icon(Icons.video_library),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1C5039),
                  Color(0xFF123B2A),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD4AD53),
              ),
            ),
            child: const Text(
              'استودیوی خلاقیت ایرانی 🇮🇷\nویدیوهای خود را حرفه‌ای تدوین کنید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'پیش‌نمایش ویدیو',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: player?.value.isInitialized == true
                ? player!.value.aspectRatio
                : 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: player?.value.isInitialized == true
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(player!),
                        Positioned(
                          bottom: 15,
                          left: 8,
                          right: 8,
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: subtitleColor,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () {
                            setState(() {
                              if (player.value.isPlaying) {
                                player.pause();
                              } else {
                                player.play();
                              }
                            });
                          },
                          icon: Icon(
                            player.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        size: 65,
                        color: Color(0xFFD4AD53),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _button(
            'انتخاب ویدیو',
            Icons.video_library,
            importVideo,
          ),
          _button(
            'ویرایش زیرنویس فارسی',
            Icons.subtitles,
            editSubtitle,
          ),
          _button(
            'رنگ زیرنویس',
            Icons.palette,
            () {
              setState(() {
                subtitleColor = subtitleColor == Colors.white
                    ? const Color(0xFFD4AD53)
                    : Colors.white;
              });
            },
          ),
          const Text('اندازه زیرنویس'),
          Slider(
            value: subtitleSize,
            min: 14,
            max: 42,
            onChanged: (value) {
              setState(() => subtitleSize = value);
            },
          ),
          const Divider(),
          const Text(
            'ابزارهای تدوین',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _button(
            'برش واقعی ویدیو',
            Icons.content_cut,
            openTrimmer,
          ),
          const SizedBox(height: 10),
          const Text(
            'برش ویدیو، حفظ صدای اصلی و ذخیره خروجی MP4 در گالری',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(
    String title,
    IconData icon,
    VoidCallback action,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton.icon(
        onPressed: action,
        icon: Icon(icon),
        label: Text(title),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1C5039),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

class TrimPage extends StatefulWidget {
  final String videoPath;
  final Duration duration;

  const TrimPage({
    super.key,
    required this.videoPath,
    required this.duration,
  });

  @override
  State<TrimPage> createState() => _TrimPageState();
}

class _TrimPageState extends State<TrimPage> {
  late final VideoTrimmer trimmer;

  late double startMs;
  late double endMs;

  bool busy = false;

  int get totalMs => widget.duration.inMilliseconds;

  @override
  void initState() {
    super.initState();

    trimmer = VideoTrimmer();

    startMs = 0;
    endMs = totalMs.toDouble();
  }

  String formatTime(double milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> trimAndSave() async {
    if (busy) return;

    if (endMs <= startMs ||
        endMs - startMs < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بازه برش باید حداقل یک ثانیه باشد'),
        ),
      );
      return;
    }

    setState(() => busy = true);

    try {
      await trimmer.loadVideo(widget.videoPath);

      final outputPath = await trimmer.trimVideo(
        startTimeMs: startMs.round(),
        endTimeMs: endMs.round(),
        includeAudio: true,
      );

      if (outputPath == null || outputPath.isEmpty) {
        throw Exception('فایل خروجی ساخته نشد');
      }

      final outputFile = File(outputPath);

      if (!await outputFile.exists()) {
        throw Exception('فایل برش‌خورده پیدا نشد');
      }

      final fileName =
          'PersianStudio_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final result = await SaverGallery.saveFile(
        filePath: outputPath,
        fileName: fileName,
        androidRelativePath: 'Movies/PersianStudio',
        skipIfExists: false,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ویدیو با موفقیت برش خورد و در گالری ذخیره شد',
            ),
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.pop(context);
      } else {
        throw Exception(
          result.errorMessage ?? 'ذخیره در گالری ناموفق بود',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF123B2A),
        title: const Text('برش ویدیو'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.content_cut,
            size: 65,
            color: Color(0xFFD4AD53),
          ),
          const SizedBox(height: 15),
          const Text(
            'تنظیم زمان برش',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'با حرکت دو دستگیره، نقطه شروع و پایان ویدیو را انتخاب کن.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('شروع: ${formatTime(startMs)}'),
              Text('پایان: ${formatTime(endMs)}'),
            ],
          ),
          const SizedBox(height: 15),
          RangeSlider(
            min: 0,
            max: totalMs.toDouble(),
            divisions: totalMs > 1000
                ? (totalMs ~/ 1000).clamp(1, 1000)
                : null,
            values: RangeValues(startMs, endMs),
            activeColor: const Color(0xFFD4AD53),
            inactiveColor: Colors.white24,
            onChanged: busy
                ? null
                : (values) {
                    setState(() {
                      startMs = values.start;
                      endMs = values.end;
                    });
                  },
          ),
          const SizedBox(height: 15),
          Card(
            color: const Color(0xFF1A241E),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text('مدت ویدیوی خروجی'),
                  const SizedBox(height: 8),
                  Text(
                    formatTime(endMs - startMs),
                    style: const TextStyle(
                      fontSize: 27,
                      color: Color(0xFFD4AD53),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: busy ? null : trimAndSave,
            icon: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_alt),
            label: Text(
              busy
                  ? 'در حال پردازش و ذخیره...'
                  : 'برش و ذخیره در گالری',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1C5039),
              padding: const EdgeInsets.all(17),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'لطفاً هنگام پردازش برنامه را نبند.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
