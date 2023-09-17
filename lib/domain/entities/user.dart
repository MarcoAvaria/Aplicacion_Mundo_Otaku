class User {
  final String username;
  final String profileImage;
  final String lastName;
  final String email;
  final int age;
  final List<String> productosPropios;
  final List<User> contactosUser;

  User({
    required this.username,
    required this.profileImage,
    required this.lastName,
    required this.email,
    required this.age,
    required this.productosPropios,
    required this.contactosUser,
  });
}