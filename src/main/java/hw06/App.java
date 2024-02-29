package hw06;

/**
 * Our app.
 *
 * @author Prof
 * @author Student
 */
public class App {
    public static void main(String[] args) {
        var text = "(2 + (1 * 32))";
        var expr = new Expr(text);
        System.out.println(expr.eval());
    }
}


