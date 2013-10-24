public class Instance {
  int m;
  public Instance(int x) {
    m = x;
  }
  public int f(int i) {
    return i*m;
  }
  public static void main(String args[]) {
    new Instance(4).f(3);
  }
}
