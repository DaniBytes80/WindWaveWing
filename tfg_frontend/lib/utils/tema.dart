import 'package:flutter/material.dart';

class EstilosWWW {
  // Colores base
  static const Color colorFondoPantalla = Color(0xFF000723);
  static const Color colorAzulMedio = Color(0xFF0D1B4B);
  static const Color colorAzulBorde = Color(0xFF1A2F6B);
  static const Color colorLetra = Colors.white;
  static const Color colorLetraSecundaria = Colors.white70;
  static const Color colorLetraMenuMapa = Color(0xFF000723);
  static const Color colorEnlace = Colors.white70;
  static const Color colorBordeTabla = Color(0xFF000723);
  static const Color colorError = Colors.redAccent;
  static const Color colorCampana = Color.fromARGB(201, 206, 185, 1);
  static const Color colorAccent = Color(0xFF1565C0); // azul acción

  // Fondos con transparencia
  static Color get fondoTransparente =>
      colorFondoPantalla.withValues(alpha: 0.75);
  static Color get fondoDialog => colorFondoPantalla.withValues(alpha: 0.97);
  static Color get fondoCard => colorAzulMedio.withValues(alpha: 0.85);
  static Color get fondoSeccion => colorAzulBorde.withValues(alpha: 0.50);

  // Decoración de dialog/panel
  static BoxDecoration get decoracionDialog => BoxDecoration(
    color: fondoDialog,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: colorAzulBorde.withValues(alpha: 0.6)),
  );

  static BoxDecoration get decoracionCard => BoxDecoration(
    color: fondoCard,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colorAzulBorde.withValues(alpha: 0.5)),
  );

  static BoxDecoration get decoracionSeccion => BoxDecoration(
    color: fondoSeccion,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: colorAzulBorde.withValues(alpha: 0.4)),
  );

  // Estilos de texto
  static const TextStyle tituloApp = TextStyle(
    color: colorLetra,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle tituloDialog = TextStyle(
    color: colorLetra,
    fontSize: 17,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle tituloSeccion = TextStyle(
    color: colorLetra,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const TextStyle textoTabla = TextStyle(
    color: colorLetra,
    fontSize: 14,
  );

  static const TextStyle textoSecundario = TextStyle(
    color: colorLetraSecundaria,
    fontSize: 13,
  );

  static const TextStyle textoNegritaTabla = TextStyle(
    color: colorLetra,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle linkRegistro = TextStyle(
    color: colorLetra,
    fontSize: 13,
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.underline,
  );

  static const TextStyle bordeTabla = TextStyle(
    color: colorBordeTabla,
    fontWeight: FontWeight.bold,
  );

  /// Botón principal de acción (fondo azul oscuro de la app)
  static final ButtonStyle botonOscuro = ElevatedButton.styleFrom(
    backgroundColor: colorBordeTabla,
    foregroundColor: colorLetra,
    minimumSize: const Size(double.infinity, 46),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Colors.white38, width: 1),
    ),
  );

  /// Botón de acción secundaria (azul medio)
  static final ButtonStyle botonAccent = ElevatedButton.styleFrom(
    backgroundColor: colorAccent,
    foregroundColor: colorLetra,
    minimumSize: const Size(double.infinity, 46),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  // FAB (botón flotante +)
  static const Color colorFAB = colorBordeTabla;

  // AppBar
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: colorFondoPantalla,
    foregroundColor: colorLetra,
    elevation: 0,
    iconTheme: IconThemeData(color: colorLetra),
    titleTextStyle: tituloApp,
  );

  // ThemeData completo
  static ThemeData get tema => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: colorFondoPantalla,
    appBarTheme: appBarTheme,
    cardColor: fondoCard,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorBordeTabla,
      foregroundColor: colorLetra,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: botonOscuro),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: colorLetra.withValues(alpha: 0.7)),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: colorLetra),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorAccent, width: 2),
      ),
      errorStyle: TextStyle(
        color: colorLetra, // tu color de letra del tema
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorAzulMedio,
      textStyle: const TextStyle(color: colorLetra),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? colorAccent : Colors.white54,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? colorAccent.withValues(alpha: 0.5)
            : colorLetra,
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: fondoDialog),
  );

  // Widget X para cerrar
  static Widget botonCerrar(BuildContext context, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.close, color: Colors.white54, size: 20),
      ),
    );
  }

  // Cabecera de dialog
  static Widget cabeceraDialog(
    BuildContext context,
    String titulo, {
    IconData? icono,
    VoidCallback? onCerrar,
  }) {
    return Row(
      children: [
        if (icono != null) ...[
          Icon(icono, color: colorCampana, size: 20),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(titulo, style: tituloDialog)),
        botonCerrar(context, onTap: onCerrar),
      ],
    );
  }
}
