import 'package:tfg_clima_malaga/models/spot.dart';

/// ===============================================================
///  SELECCIÓN AUTOMÁTICA DE FUENTES METEOROLÓGICAS
/// ===============================================================
///
///  Este archivo decide qué fuente usar según:
///   - Ubicación del spot (detectado por coordenadas)
///   - Variable meteorológica
///
///  Fuentes:
///   - AEMET (España)
///   - Puertos del Estado (olas)
///   - Open-Meteo (fallback o fuera de España)
///   - Open-Meteo Marine (olas fallback)
///
/// ===============================================================

class MapaFuentes {
  /// Determina si un spot está en España usando coordenadas
  static bool esEspana(Spot spot) {
    final lat = spot.lat;
    final lng = spot.lng;

    // España peninsular + Baleares
    final espanaPeninsula =
        lat >= 36.0 && lat <= 44.5 && lng >= -9.5 && lng <= 4.5;

    // Canarias
    final canarias = lat >= 27.0 && lat <= 30.0 && lng >= -18.0 && lng <= -13.0;

    return espanaPeninsula || canarias;
  }

  /// Devuelve la fuente adecuada según variable y ubicación
  static String fuentePara(Spot spot, String variable) {
    final enEspana = esEspana(spot);

    switch (variable) {
      case "viento":
      case "racha":
      case "direccion_viento":
      case "temperatura":
      case "lluvia":
      case "humedad":
        return enEspana ? "AEMET" : "OPEN_METEO";

      case "olas":
      case "periodo":
      case "direccion_ola":
      case "swell":
        return enEspana ? "PUERTOS" : "OPEN_METEO_MARINE";

      default:
        return enEspana ? "AEMET" : "OPEN_METEO";
    }
  }

  /// Devuelve la URL de tiles según la fuente
  static String urlTiles(String fuente, String variable) {
    switch (fuente) {
      case "AEMET":
        return "https://tu-backend.com/tiles/aemet/$variable/{z}/{x}/{y}.png";

      case "PUERTOS":
        return "https://tu-backend.com/tiles/puertos/$variable/{z}/{x}/{y}.png";

      case "OPEN_METEO":
        return "https://tu-backend.com/tiles/openmeteo/$variable/{z}/{x}/{y}.png";

      case "OPEN_METEO_MARINE":
        return "https://tu-backend.com/tiles/openmeteo_marine/$variable/{z}/{x}/{y}.png";

      default:
        return "";
    }
  }
}
