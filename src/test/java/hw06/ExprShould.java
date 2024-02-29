package hw06;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class ExprShould {

    @Test
    void eval_expr_1() {
        test_eval(9, "((1 + 2) * 3)");
    }

    @Test
    void eval_expr_2() {
        test_eval(18, "(2 + ((1 + (1 * 32) - 17)))");
    }

    void test_eval(int expect, String expr) {
        assertEquals(expect, new Expr(expr).eval(), expr);
    }
}
