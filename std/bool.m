;;; Bool.m
;;;
;;; An implementation of booleans which are encoded using two argument functions
;;; which ignore one argument.
;;;
;;; All definitions in this file are optimized to use the backend's native
;;; implementation of booleans.

;; The singleton truthy value, a function which ignores its second argument.
(def true (fn x _ x))

;; The singleton falsy value, a function which ignores its first argument.
(def false (fn _ x x))

;; True if both arguments are true.
(def and
  (fn x y
    (if x (force y) false)))

;; True if either argument is true.
(def or
  (fn x y
    (if x true (force y))))

;; True if its argument is false.
(def not
  (fn x
    (if x false true)))

;; Macro for and which delays the second argument.
(macro &
  (fn expr
    (apply-vararg expr.list
      (expr.symbol (symbol and))
      (car expr)
      (expr.list (cons (expr.symbol (symbol delay)) (list (cadr expr)))))))

;; Macro for or which delays the second argument.
(macro |
  (fn expr
    (apply-vararg expr.list
      (expr.symbol (symbol or))
      (car expr)
      (expr.list (cons (expr.symbol (symbol delay)) (list (cadr expr)))))))

;; Macro for control flow.
(macro if
  (fn expr
    (apply-vararg expr.list
      (expr.symbol (symbol force))
      (apply-vararg expr.list
        (car expr)
        (expr.list (cons (expr.symbol (symbol delay)) (list (cadr expr))))
        (expr.list (cons (expr.symbol (symbol delay)) (list (caddr expr))))))))

;; Tests M booleans.
(def bool:test
  (apply-vararg combine-tests
    (assert     true)
    (assert-not false)
    (assert     (not false))
    (assert-not (not true))
    (assert     (& true true))
    (assert-not (& true false))
    (assert-not (& false true))
    (assert-not (& false false))
    (assert     (| true true))
    (assert     (| true false))
    (assert     (| false true))
    (assert-not (| false false))))