public class Try {
  public void f1() throws Exception {
  }
  public int f2() {
    int i;
    try {
      i=0;
    }
    catch (Exception e) {
      i=1;
    }
    finally {
      i=2;
    }
    return i;
  }
}
