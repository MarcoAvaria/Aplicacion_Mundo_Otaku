class Message{

  String message;
  String sentByMe;

  Message({required this.message, required this.sentByMe});
  
  factory Message.fromJson(Map<String,dynamic> json){
    return Message(
      message: json["message"] as String, 
      sentByMe: json["fullName"] as String,
    );
  }
}