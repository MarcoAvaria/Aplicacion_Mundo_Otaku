import 'package:flutter/material.dart';

/// Pregunta antes de una acción que no se puede deshacer.
///
/// Devuelve `true` solo si la persona confirmó. Si cierra el diálogo tocando
/// fuera o con el botón atrás, devuelve `false`, nunca `null`, para que quien
/// llama no tenga que distinguir esos casos.
///
/// Existe para que todas las confirmaciones de la aplicación digan lo mismo de
/// la misma forma. Antes cada pantalla armaba su propio `AlertDialog`, y el
/// resultado fue desparejo: eliminar un producto preguntaba, pero rechazar una
/// solicitud, cancelar una propuesta y cerrar la sesión no lo hacían, aunque
/// las tres son igual de difíciles de deshacer.
///
/// El criterio: **se pregunta cuando deshacer la acción no consiste en
/// retroceder, sino en provocar otro cambio que alguien más va a ver; o cuando
/// la acción interrumpe lo que estabas haciendo.**
///
/// Las tres acciones sobre un intercambio —aceptar, rechazar y cancelar— caen
/// en el primer caso: mueven el `status` de la entidad y ese movimiento le
/// llega a la otra persona. Aceptar estuvo un rato sin preguntar por creerse
/// "reversible desde el chat"; lo es, pero deshacerlo cuesta otra transición
/// que la otra persona también ve, y los botones quedan lo bastante juntos como
/// para rozar el que no era.
Future<bool> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  /// Texto del botón que confirma. Conviene que **no repita** el nombre del
  /// botón que abrió el diálogo: mientras el diálogo está abierto los dos
  /// conviven, y un "Rechazar" sobre otro "Rechazar" es ambiguo tanto para un
  /// lector de pantalla como para una prueba que localice por nombre.
  required String etiquetaConfirmar,

  /// Texto del botón que se va sin hacer nada. Conviene que nombre la salida
  /// ("Seguir aquí") en vez de un "Cancelar" genérico, que se confunde con la
  /// acción cuando esta también se llama cancelar.
  String etiquetaVolver = 'Volver',
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(etiquetaVolver),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(etiquetaConfirmar),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
