class Message{

  String message;
  String sentByMe;
  String sendBy;

  Message({required this.message, required this.sentByMe, required this.sendBy});
  
  factory Message.fromJson(Map<String,dynamic> json){
    return Message(
      message: json["message"] as String, 
      sentByMe: json["fullName"] as String,
      sendBy: json["productId"] as String,
    );
  }
}