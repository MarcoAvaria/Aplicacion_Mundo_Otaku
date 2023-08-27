class ProductModel {
  int? id;
  String? tipo;
  String? franquicia;
  int? volumen;
  String? descripcion;
  int? precio;
  String? path;

  ProductModel({
    this.id,
    this.tipo,
    this.franquicia,
    this.volumen,
    this.descripcion,
    this.precio,
    this.path,
  });
}

List<ProductModel> products = [
  ProductModel(
    id: 1,
    tipo: "Manga",
    franquicia: "Bleach",
    descripcion: "Primer volumen de Bleach, el inicio de una mítica serie shonen",
    volumen: 1,
    precio: 6500,
    path: "assets/Bleach_Vol_01.png",
  ),
  ProductModel(
    id: 2,
    tipo: "Manga",
    franquicia: "Blue Lock",
    descripcion: "Comienzo de la serie de futbol más popular de la nueva camada",
    volumen: 1,
    precio: 7400,
    path: "assets/Blue_Lock_Vol_01.png",
  ),
  ProductModel(
    id: 3,
    tipo: "Manga",
    franquicia: "Boku no Hero",
    descripcion: "Uno de los mejores volumenes de esta serie",
    volumen: 29,
    precio: 9800,
    path: "assets/Boku_no_Hero_Vol_29.png",
  ),
  ProductModel(
    id: 4,
    tipo: "Manga",
    franquicia: "Claymore",
    descripcion: "Una serie infravalorada, en excelente estado",
    volumen: 09,
    precio: 8800,
    path: "assets/Claymore_Vol_09.png",
  ),
  ProductModel(
    id: 5,
    tipo: "Manga",
    franquicia: "Dr.Stone",
    descripcion: "Décimo volumen, en buen estado",
    volumen: 10,
    precio: 7700,
    path: "assets/Dr_Stone_Vol_10.png",
  ),
  ProductModel(
    id: 6,
    tipo: "Manga",
    franquicia: "Hajime no Ippo",
    descripcion: "Primer volumen de Ippo, sigue en su bolsa sin abrir",
    volumen: 01,
    precio: 16500,
    path: "assets/Hajime_no_Ippo_Vol_01.png",
  ),
  ProductModel(
    id: 7,
    tipo: "Manga",
    franquicia: "Jujutsu Kaisen",
    descripcion: "Cuarto volumen de esta excelente saga que sigue en emisión",
    volumen: 04,
    precio: 9800,
    path: "assets/Jujutsu_Kaisen_Vol_04.png",
  ),
  ProductModel(
    id: 8,
    tipo: "Manga",
    franquicia: "Kimetsu no Yaiba",
    descripcion: "La serie récord en ventas en japón, el inicio de la historia",
    volumen: 01,
    precio: 9400,
    path: "assets/Kimetsu_no_Yaiba_Vol_01.png",
  ),
  ProductModel(
    id: 9,
    tipo: "Manga",
    franquicia: "Komi-san wa Komyoshou Desu",
    descripcion: "La portada más linda de la saga, el arco más importante hasta la fecha",
    volumen: 23,
    precio: 11800,
    path: "assets/Komi_san_wa_Komyoshou_Desu_Vol_23.png",
  ),
  ProductModel(
    id: 10,
    tipo: "Manga",
    franquicia: "Ao no Hako",
    descripcion: "El spokon más tierno del último tiempo",
    volumen: 01,
    precio: 8100,
    path: "assets/Ao_no_Hako_Vol_01.png",
  ),
];