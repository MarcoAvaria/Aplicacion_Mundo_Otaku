class Product {
  int? id;
  String? tipo;
  String? franquicia;
  int? tomo;
  String? descripcion;
  int? precio;
  String? path;

  Product({
    this.id,
    this.tipo,
    this.franquicia,
    this.tomo,
    this.descripcion,
    this.precio,
    this.path,
  });
}

List<Product> products = [
  Product(
    id: 1,
    tipo: "Manga",
    franquicia: "Bleach",
    descripcion: "Primer volumen de Bleach, el inicio de una mítica serie shonen",
    tomo: 1,
    precio: 6500,
    path: "assets/Bleach_Vol_01.png",
  ),
  Product(
    id: 2,
    tipo: "Manga",
    franquicia: "Blue Lock",
    descripcion: "Comienzo de la serie de futbol más popular de la nueva camada",
    tomo: 1,
    precio: 7400,
    path: "assets/Blue_Lock_Vol_01.png",
  ),
  Product(
    id: 3,
    tipo: "Manga",
    franquicia: "Boku no Hero",
    descripcion: "Uno de los mejores volumenes de esta serie",
    tomo: 29,
    precio: 9800,
    path: "assets/Boku_no_Hero_Vol_29.png",
  ),
  Product(
    id: 4,
    tipo: "Manga",
    franquicia: "Claymore",
    descripcion: "Una serie infravalorada, en excelente estado",
    tomo: 09,
    precio: 8800,
    path: "assets/Claymore_Vol_09.png",
  ),
  Product(
    id: 5,
    tipo: "Manga",
    franquicia: "Dr.Stone",
    descripcion: "Décimo volumen, en buen estado",
    tomo: 10,
    precio: 7700,
    path: "assets/Dr_Stone_Vol_10.png",
  ),
  Product(
    id: 6,
    tipo: "Manga",
    franquicia: "Hajime no Ippo",
    descripcion: "Primer volumen de Ippo, sigue en su bolsa sin abrir",
    tomo: 01,
    precio: 16500,
    path: "assets/Hajime_no_Ippo_Vol_01.png",
  ),
  Product(
    id: 7,
    tipo: "Manga",
    franquicia: "Jujutsu Kaisen",
    descripcion: "Cuarto volumen de esta excelente saga que sigue en emisión",
    tomo: 04,
    precio: 9800,
    path: "assets/Jujutsu_Kaisen_Vol_04.png",
  ),
  Product(
    id: 8,
    tipo: "Manga",
    franquicia: "Kimetsu no Yaiba",
    descripcion: "La serie récord en ventas en japón, el inicio de la historia",
    tomo: 01,
    precio: 9400,
    path: "assets/Kimetsu_no_Yaiba_Vol_01.png",
  ),
  Product(
    id: 9,
    tipo: "Manga",
    franquicia: "Komi-san wa Komyoshou Desu",
    descripcion: "La portada más linda de la saga, el arco más importante hasta la fecha",
    tomo: 23,
    precio: 11800,
    path: "assets/Komi_san_wa_Komyoshou_Desu_Vol_23.png",
  ),
  Product(
    id: 10,
    tipo: "Manga",
    franquicia: "Ao no Hako",
    descripcion: "El spokon más tierno del último tiempo",
    tomo: 01,
    precio: 8100,
    path: "assets/Ao_no_Hako_Vol_01.png",
  ),
];