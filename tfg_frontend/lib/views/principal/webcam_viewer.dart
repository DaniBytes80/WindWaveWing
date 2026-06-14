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
      // HLS streaming
      try {
        _videoCtrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.url.trim()),
        );
        await _videoCtrl!.initialize();
        _videoCtrl!.play();
        _videoCtrl!.setLooping(true);
        if (mounted) setState(() => _tipo = _TipoCam.hls);
      } catch (_) {
        if (mounted) {
          setState(() {
            _tipo = _TipoCam.web;
          });
        }
      }
    } else if (url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('mjpeg') ||
        url.contains('mjpg')) {
      // Imagen estática o MJPEG
      if (mounted) setState(() => _tipo = _TipoCam.imagen);
    } else {
      // URL web → InAppWebView
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
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.55,
          child: Stack(
            children: [
              _contenido(),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido() { 
    switch (_tipo) {
      case _TipoCam.cargando:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 12),
              Text(
                "Conectando con la cámara...",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );

      // HLS video
      case _TipoCam.hls:
        if (_videoCtrl == null || !_videoCtrl!.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return Center(
          child: AspectRatio(
            aspectRatio: _videoCtrl!.value.aspectRatio,
            child: VideoPlayer(_videoCtrl!),
          ),
        );

      // Imagen / MJPEG
      case _TipoCam.imagen:
        return _ImagenCamara(url: widget.url);

      // Web (InAppWebView dentro de la app)
      case _TipoCam.web:
        return InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url.trim())),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            transparentBackground: false,
          ),
          onReceivedError: (ctrl, req, err) {
            // Si falla el WebView → mostrar botón navegador externo
            if (mounted) {}
          },
        );
    }
  }
}

//  _ImagenCamara — refresca la imagen cada 5 segundos
//    para cámaras que sirven JPG estático actualizado
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
    // Refresca cada 5s
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
          : const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
      errorBuilder: (_, e, s) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.white30, size: 48),
            SizedBox(height: 8),
            Text(
              "No se pudo cargar la imagen",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TipoCam { cargando, hls, imagen, web }
