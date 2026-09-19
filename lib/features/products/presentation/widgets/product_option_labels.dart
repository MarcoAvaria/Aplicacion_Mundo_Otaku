/// Etiquetas corregidas para opciones cuyo valor ya está guardado en la base.
///
/// El valor almacenado no cambia: los productos existentes conservan su texto
/// original y el `DropdownButton` los sigue encontrando entre sus opciones.
/// Cambiar los valores exigiría una migración de datos aparte.
const productOptionLabels = <String, String>{
  'Accion peleas': 'Acción / peleas',
  'Gore Terror': 'Gore / terror',
  'Magical Girls Maho Shojo': 'Magical girls (mahō shōjo)',
  'Komodo': 'Kodomo',
};

String productOptionLabel(String value) => productOptionLabels[value] ?? value;
