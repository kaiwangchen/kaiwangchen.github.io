public class Sync {
  public synchronized void f1() {
  }

  public void f2(Object o) {
    synchronized (o) {
      
    }
  }
}
