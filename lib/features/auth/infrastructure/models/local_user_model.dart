 class UserModel{
  //variables que se usaran para recibir o enviar valores
  final String username;
  late String lastName;
  late String email;
  late int age;
  final String profileImage;

  //constructor de la clase
  UserModel({
    required this.username,
    required this.profileImage,
  });


  //con este metodo podras enviar datos de ser necesario.
  Map<String, dynamic> toJson(){
    return {
      "name": username,
      "profileImage": profileImage,
    };
  }

  //con este metodo los valores que recibes los convieres en un objeto de tipo ProductModel.
  //es necesario que las claves tengan el mismo nombre que el json que recibes.
  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      username: json['name'],
      profileImage: json['profileImage'], 
    );
  }
}