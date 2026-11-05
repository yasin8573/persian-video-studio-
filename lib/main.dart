
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

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

  int subtitleStyle = 0;
  int subtitlePosition = 2;

  double startSeconds = 0;
  double endSeconds = 10;

  bool exporting = false;

  final List<Color> colors = [
    Colors.white,
    const Color(0xFFFFD54F),
    const Color(0xFF80DEEA),
    const Color(0xFFFF8A80),
    const Color(0xFFB9F6CA),
    const Color(0xFFE1BEE7),
  ];

  double get durationSeconds {
    if (video == null || !video!.value.isInitialized) return 1;
    return video!.value.duration.inMilliseconds / 1000;
  }

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
        startSeconds = 0;
        endSeconds = next.value.duration.inMilliseconds / 1000;
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
        title: const Text('ویرایش زیرنویس'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'متن زیرنویس را بنویسید',
            border: OutlineInputBorder(),
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

    controller.dispose();
  }

  Future<Uint8List> createSubtitleImage({
    required int width,
    required int height,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    final scaledFontSize = subtitleSize * (width / 360.0);

    final bool modern = subtitleStyle == 1;
    final bool minimal = subtitleStyle == 2;
    final bool karaoke = subtitleStyle == 3;

    final textStyle = TextStyle(
      fontSize: scaledFontSize,
      fontWeight: FontWeight.bold,
      color: karaoke
          ? const Color(0xFFFFD54F)
          : subtitleColor,
      height: 1.35,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: textStyle,
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: 4,
      ellipsis: '...',
    );

    painter.layout(maxWidth: width * 0.88);

    final horizontal = (width - painter.width) / 2;

    double top;

    if (subtitlePosition == 0) {
      top = height * 0.08;
    } else if (subtitlePosition == 1) {
      top = (height - painter.height) / 2;
    } else {
      top = height - painter.height - height * 0.09;
    }

    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        horizontal - scaledFontSize * 0.55,
        top - scaledFontSize * 0.35,
        painter.width + scaledFontSize * 1.1,
        painter.height + scaledFontSize * 0.7,
      ),
      Radius.circular(scaledFontSize * 0.3),
    );

    if (modern) {
      canvas.drawRRect(
        backgroundRect,
        Paint()..color = const Color(0xC9000000),
      );
    }

    if (!minimal) {
      final strokePainter = TextPainter(
        text: TextSpan(
          text: subtitle,
          style: TextStyle(
            fontSize: scaledFontSize,
            fontWeight: FontWeight.bold,
            height: 1.35,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = karaoke
                  ? scaledFontSize * 0.12
                  : scaledFontSize * 0.16
              ..color = Colors.black,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 4,
        ellipsis: '...',
      );

      strokePainter.layout(maxWidth: width * 0.88);
      strokePainter.paint(canvas, Offset(horizontal, top));
    }

    painter.paint(canvas, Offset(horizontal, top));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    picture.dispose();

    if (data == null) {
      throw Exception('ساخت تصویر زیرنویس ناموفق بود');
    }

    return data.buffer.asUint8List();
  }

  Future<void> exportSubtitleVideo() async {
    if (exporting) return;

    if (videoPath == null || video == null ||
        !video!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا یک ویدیو انتخاب کن')),
      );
      return;
    }

    if (subtitle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متن زیرنویس خالی است')),
      );
      return;
    }

    if (startSeconds >= endSeconds ||
        endSeconds > durationSeconds + 0.1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('زمان شروع و پایان را بررسی کن')),
      );
      return;
    }

    setState(() => exporting = true);

    try {
      await video!.pause();

      final sourceSize = video!.value.size;
      final width = sourceSize.width.round();
      final height = sourceSize.height.round();

      if (width <= 0 || height <= 0) {
        throw Exception('ابعاد ویدیو قابل تشخیص نیست');
      }

      final subtitleBytes = await createSubtitleImage(
        width: width,
        height: height,
      );

      final layer = ImageLayer(
        image: EditorLayerImage.memory(subtitleBytes),
        offset: Offset.zero,
        size: Size(width.toDouble(), height.toDouble()),
        startTime: Duration(
          milliseconds: (startSeconds * 1000).round(),
        ),
        endTime: Duration(
          milliseconds: (endSeconds * 1000).round(),
        ),
      );

      final renderData = VideoRenderData(
        videoSegments: [
          VideoSegment(
            video: EditorVideo.file(File(videoPath!)),
          ),
        ],
        imageLayers: [layer],
        outputFormat: VideoOutputFormat.mp4,
        enableAudio: true,
      );

      final outputPath =
          '${Directory.systemTemp.path}/PersianStudio_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await ProVideoEditor.instance.renderVideoToFile(
        outputPath,
        renderData,
      );

      final outputFile = File(outputPath);

      if (!await outputFile.exists()) {
        throw Exception('فایل خروجی ساخته نشد');
      }

      final fileName =
          'PersianStudio_Subtitle_${DateTime.now().millisecondsSinceEpoch}.mp4';

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
              'ویدیو با زیرنویس حک‌شده ذخیره شد',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        throw Exception(
          result.errorMessage ?? 'ذخیره در گالری ناموفق بود',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ساخت ویدیو: $e'),
          duration: const Duration(seconds: 7),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => exporting = false);
      }
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
                          bottom: subtitlePosition == 2 ? 15 : null,
                          top: subtitlePosition == 0
                              ? 15
                              : subtitlePosition == 1
                                  ? 0
                                  : null,
                          left: 8,
                          right: 8,
                          child: subtitlePosition == 1
                              ? Center(
                                  child: _previewSubtitle(),
                                )
                              : _previewSubtitle(),
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

          const Divider(height: 30),

          const Text(
            'طراحی و استایل زیرنویس',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _button(
            'ویرایش متن زیرنویس',
            Icons.subtitles,
            editSubtitle,
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            value: subtitleStyle,
            decoration: const InputDecoration(
              labelText: 'قالب زیرنویس',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 0,
                child: Text('سینمایی - سفید با دورخط مشکی'),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text('مدرن - پس‌زمینه نیمه‌شفاف'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text('مینیمال - ساده و ظریف'),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text('کارائوکه - طلایی با دورخط'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => subtitleStyle = value);
              }
            },
          ),

          const SizedBox(height: 18),

          const Text('رنگ زیرنویس'),

          const SizedBox(height: 8),

          Wrap(
            spacing: 12,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() => subtitleColor = color);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: subtitleColor == color
                          ? const Color(0xFFD4AD53)
                          : Colors.white54,
                      width: subtitleColor == color ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          Text(
            'اندازه زیرنویس: ${subtitleSize.round()}',
          ),

          Slider(
            value: subtitleSize,
            min: 14,
            max: 42,
            activeColor: const Color(0xFFD4AD53),
            onChanged: (value) {
              setState(() => subtitleSize = value);
            },
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<int>(
            value: subtitlePosition,
            decoration: const InputDecoration(
              labelText: 'موقعیت زیرنویس',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 0,
                child: Text('بالای تصویر'),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text('وسط تصویر'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text('پایین تصویر'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => subtitlePosition = value);
              }
            },
          ),

          const Divider(height: 35),

          const Text(
            'زمان نمایش زیرنویس',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (player?.value.isInitialized == true) ...[
            Text(
              'شروع: ${startSeconds.toStringAsFixed(1)} ثانیه',
            ),
            Slider(
              value: startSeconds.clamp(
                0,
                (durationSeconds - 0.1).clamp(0, durationSeconds),
              ),
              min: 0,
              max: durationSeconds > 0.1
                  ? durationSeconds - 0.1
                  : 0.1,
              activeColor: const Color(0xFFD4AD53),
              onChanged: (value) {
                setState(() {
                  startSeconds = value;
                  if (endSeconds <= startSeconds) {
                    endSeconds = startSeconds + 0.1;
                  }
                });
              },
            ),

            Text(
              'پایان: ${endSeconds.toStringAsFixed(1)} ثانیه',
            ),
            Slider(
              value: endSeconds.clamp(
                0.1,
                durationSeconds,
              ),
              min: 0.1,
              max: durationSeconds > 0.1
                  ? durationSeconds
                  : 0.2,
              activeColor: const Color(0xFFD4AD53),
              onChanged: (value) {
                setState(() {
                  endSeconds = value;
                  if (startSeconds >= endSeconds) {
                    startSeconds = endSeconds - 0.1;
                    if (startSeconds < 0) startSeconds = 0;
                  }
                });
              },
            ),
          ] else
            const Text(
              'برای تنظیم زمان، ابتدا ویدیو انتخاب کن.',
              style: TextStyle(color: Colors.white54),
            ),

          const SizedBox(height: 12),

          _button(
            exporting
                ? 'در حال ساخت ویدیو...'
                : 'حک زیرنویس و ذخیره MP4',
            Icons.movie_filter,
            exportSubtitleVideo,
          ),

          if (exporting)
            const Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFD4AD53),
                  ),
                  SizedBox(height: 12),
                  Text('در حال پردازش ویدیو؛ لطفاً برنامه را نبند.'),
                ],
              ),
            ),

          const Divider(height: 35),

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

  Widget _previewSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: subtitleStyle == 1
            ? Colors.black54
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        subtitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: subtitleSize,
          color: subtitleStyle == 3
              ? const Color(0xFFFFD54F)
              : subtitleColor,
          fontWeight: FontWeight.bold,
          shadows: subtitleStyle == 2
              ? null
              : const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 8,
                    offset: Offset(1, 2),
                  ),
                ],
        ),
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
        onPressed: exporting ? null : action,
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

    if (endMs <= startMs || endMs - startMs < 1000) {
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
