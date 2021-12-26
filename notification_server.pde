import java.util.Calendar;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

class NotificationServer {
  
  Boolean debugMode = false; //set this to false to turn off the println statements on each Notification below
  
  Timer timer;
  Calendar calendar;
  private ArrayList<NotificationListener> listeners;
  private ArrayList<Notification> currentNotifications;
  long startTime;
  long pauseTime;

  public NotificationServer() {
    timer = new Timer();
    listeners = new ArrayList<NotificationListener>();
    calendar = Calendar.getInstance();
  }
  
  //loads and schedules all tasks
  //you should register all listeners before calling this method
  public void loadEventStream(String eventDataJSON) {
    currentNotifications = this.getNotificationDataFromJSON(loadJSONArray(eventDataJSON));
    
    //Getting the current date
    Date date = new Date();
    //This method returns the time in millis
    startTime = date.getTime();
    println("<NotificationServer> started at time =", startTime);

    //Starting the NotificationServer (scheduling tasks) 
    for (int i = 0; i < currentNotifications.size(); i++) { //<>//
      this.scheduleTask(currentNotifications.get(i));
    } 
  }
  
  public void stopEventStream() {
    pauseTime = 0;
    this.stopTimer();
  }
  
  public void pauseEventStream() {
    Date date = new Date();
    pauseTime = date.getTime() - startTime;
    this.stopTimer();
  }
  
  private void stopTimer() {
    if (timer != null)
      timer.cancel(); //stop all currently scheduled tasks
    timer = new Timer();  //create a new Timer for future scheduling
  }
  
  public ArrayList<Notification> getCurrentNotifications() {
    return currentNotifications;
  }
  
  public ArrayList<Notification> getNotificationDataFromJSON(JSONArray values) {
    ArrayList<Notification> notifications = new ArrayList<Notification>();
    for (int i = 0; i < values.size(); i++) {
      //println(values.getJSONObject(i));
      notifications.add(new Notification(values.getJSONObject(i)));
    }
    return notifications;
  }

  public void scheduleTask(Notification notification) {
    if (notification.getTimestamp() >= pauseTime) {
      timer.schedule(new NotificationTask(this, notification), notification.getTimestamp() - pauseTime);
    }
  }
  
  public void addListener(NotificationListener listenerToAdd) {
    listeners.add(listenerToAdd);
  }
  
  public void notifyListeners(Notification notification) {
    if (debugMode)
      println("<NotificationServer> " + notification.toString());
    for (int i=0; i < listeners.size(); i++) {
      listeners.get(i).notificationReceived(notification);
    }
  }
  

  class NotificationTask extends TimerTask {
    
    NotificationServer server;
    Notification notification;
    
    public NotificationTask(NotificationServer server, Notification notification) {
      super();
      this.server = server;
      this.notification = notification;
    }
    
    public void run() {
      server.notifyListeners(notification);
    }
    
  }
}
