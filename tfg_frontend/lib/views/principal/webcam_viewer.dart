import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WebcamViewer extends StatefulWidget {
  final String url;

  const WebcamViewer({super.key, required this.url});

  @override
  State<WebcamViewer> createState() => _WebcamViewerState();
}

class _WebcamViewerState extends State<WebcamViewer> {
  VideoPlayerController? _videoPlayerController;

  bool _isHlsStream = false;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeViewer();
  }

  Future<void> _initializeViewer() async {
    final urlLimpia = widget.url.trim().toLowerCase();

    if (urlLimpia.contains('.m3u8')) {
      setState(() => _isHlsStream = true);

      try {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.url.trim()),
        );
        await _videoPlayerController!.initialize();

        setState(() => _isLoading = false);
      } catch (e) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isHlsStream = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirEnNavegador() async {}

  @override
  void dispose() {
    _videoPlayerController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        height: 260,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Center(child: _buildContent()),

            // BOTÓN X
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blueAccent),
          SizedBox(height: 20),
          Text(
            "Conectando con el Spot...",
            style: TextStyle(color: Colors.white54),
          ),
        ],
      );
    }

    if (_isHlsStream) {
      if (_hasError) {
        return const Text(
          "Error al decodificar el streaming HLS.\nVerifica tu conexión o permisos.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.redAccent),
        );
      }
    }

    // Fallback para cámaras externas
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.public, color: Colors.white54, size: 60),
        const SizedBox(height: 20),
        const Text(
          "Cámara alojada en servidor externo",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _abrirEnNavegador,
          icon: const Icon(Icons.open_in_browser),
          label: const Text("Abrir cámara en el navegador"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
