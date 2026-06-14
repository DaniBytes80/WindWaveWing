import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:video_player/video_player.dart';

class WebcamViewer extends StatefulWidget {
  final String url;
  const WebcamViewer({super.key, required this.url});

  @override
  State<WebcamViewer> createState() => _WebcamViewerState();
}

class _WebcamViewerState extends State<WebcamViewer> {
  VideoPlayerController? _videoCtrl;
  _TipoCam _tipo = _TipoCam.cargando;

  @override
  void initState() {
    super.initState();
    _detectarTipo();
  }

  Future<void> _detectarTipo() async {
    final url = widget.url.trim().toLowerCase();

    if (url.contains('.m3u8')) {
      try {
        _videoCtrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.url.trim()),
        );
        await _videoCtrl!.initialize();
        _videoCtrl!.play();
        _videoCtrl!.setLooping(true);
        if (mounted) setState(() => _tipo = _TipoCam.hls);
      } catch (_) {
        if (mounted) setState(() => _tipo = _TipoCam.web);
      }
    } else if (url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('mjpeg') ||
        url.contains('mjpg')) {
      if (mounted) setState(() => _tipo = _TipoCam.imagen);
    } else {
      if (mounted) setState(() => _tipo = _TipoCam.web);
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero, // ✅ sin margen exterior
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ), // ✅ sin bordes redondeados
      child: Stack(
        children: [
          // ✅ Contenido a pantalla completa sin padding
          _contenido(),

          // X minimalista
          Positioned(
            right: 6,
            top: 6,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white70, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    switch (_tipo) {
      case _TipoCam.cargando:
        return const SizedBox(
          width: 200,
          height: 150,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 8),
                Text(
                  "Conectando...",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        );

      case _TipoCam.hls:
        if (_videoCtrl == null || !_videoCtrl!.value.isInitialized) {
          return const SizedBox(
            width: 200,
            height: 150,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return AspectRatio(
          aspectRatio: _videoCtrl!.value.aspectRatio,
          child: VideoPlayer(_videoCtrl!),
        );

      case _TipoCam.imagen:
        return _ImagenCamara(url: widget.url);

      case _TipoCam.web:
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.4,
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url.trim())),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              transparentBackground: false,
            ),
          ),
        );
    }
  }
}

class _ImagenCamara extends StatefulWidget {
  final String url;
  const _ImagenCamara({required this.url});

  @override
  State<_ImagenCamara> createState() => _ImagenCamaraState();
}

class _ImagenCamaraState extends State<_ImagenCamara> {
  int _cacheKey = 0;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      setState(() => _cacheKey++);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      '${widget.url}?t=$_cacheKey',
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const SizedBox(
              width: 200,
              height: 150,
              child: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
      errorBuilder: (_, e, s) => const SizedBox(
        width: 200,
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white30, size: 36),
              SizedBox(height: 6),
              Text(
                "No se pudo cargar",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TipoCam { cargando, hls, imagen, web }
