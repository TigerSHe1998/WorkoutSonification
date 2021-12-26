enum NotificationType { chestHeight, waistHeight, waistAngle, elbowL, elbowR, kneeL, kneeR }

class Notification {
   
  int timestamp;
  NotificationType type; // the enum above
  float value;
  
  public Notification(JSONObject json) {
    this.timestamp = json.getInt("timestamp");
    //time in milliseconds for playback from sketch start
    
    String typeString = json.getString("type");
    
    try {
      this.type = NotificationType.valueOf(typeString);
    }
    catch (IllegalArgumentException e) {
      throw new RuntimeException(typeString + " is not a valid value for enum NotificationType.");
    }
    
    this.value = json.getFloat("value");  
  }
  
  public int getTimestamp() { return timestamp; }
  public NotificationType getType() { return type; }
  public float getValue() { return value; }
  
  public String toString() {
      String output = "(" + getType().toString() + ")" + " sensor at value ";
      output += "(" + getValue() + ")";
      return output;
    }
}
