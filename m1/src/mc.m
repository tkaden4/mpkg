(def true)
(def false)

(def nil)
(def cons)
(def car)
(def cdr)

(def add-int)
(def keyword->int)

(def eq-char)
(def int->char)

(def eq-keyword)

(def type-name)

(def new-data)
(def field)

(def then-run)
(def run-with)
(def then-run-with)
(def run-unsafe)

(def file)

(def args)

(def generate)

(def pair
  (new-data (keyword pair)
    (cons (keyword first)
    (cons (keyword second)
      nil))))

(def new-pair
  (lambda first second
    (pair (cons first (cons second nil)))))

(def first (field (keyword first)))
(def second (field (keyword second)))

(def and
  (lambda x y
    (if x (y nil) false)))

(def or
  (lambda x y
    (if x true (y nil))))

(def not
  (lambda x
    (if x false true)))

(def compose
  (lambda f g
    (lambda x
      (f (g x)))))

(def is-nil
  (lambda x
    (eq-keyword (type-name x) (keyword nil))))

(def cadr (compose car cdr))

(def parse-failure
  (new-data (keyword parse-failure)
    (cons (keyword state)
      nil)))

(def new-parse-failure
  (lambda state
    (parse-failure (cons state nil))))

(def parse-failure.state (field (keyword state)))

(def parse-success
  (new-data (keyword parse-success)
    (cons (keyword value)
    (cons (keyword state)
    (cons (keyword rest)
      nil)))))

(def new-parse-success
  (lambda value state rest
    (parse-success (cons value (cons state (cons rest nil))))))

(def parse-success.value (field (keyword value)))
(def parse-success.state (field (keyword state)))
(def parse-success.rest (field (keyword rest)))

(def is-parse-success
  (lambda x
    (eq-keyword (type-name x) (keyword parse-success))))

(def predicate-parser
  (lambda f
    (lambda input state
      (if (and (not (is-nil input))
               (lambda (f (car input))))
        (new-parse-success (car input) state (cdr input))
        (new-parse-failure state)))))

(def map-parser
  (lambda parser f
    (lambda input state
      (f (parser input state)))))

(def map-parser-success
  (lambda parser f
    (map-parser parser
      (lambda result
        (if (is-parse-success result)
          (f result)
          result)))))

(def map-parser-value
  (lambda parser f
    (map-parser-success parser
      (lambda success
        (new-parse-success
          (f (parse-success.value success))
          (parse-success.state success)
          (parse-success.rest success))))))

(def map-parser-state
  (lambda parser f
    (map-parser-success parser
      (lambda success
        (new-parse-success
          (parse-success.value success)
          (f (parse-success.state success))
          (parse-success.rest success))))))

(def provide-past-state
  (lambda parser
    (lambda input state
      ((map-parser-value parser
        (lambda value
          (new-pair value state)))
      input state))))

(def combine-parser
  (lambda parser1 parser2
    (lambda input state
      ((lambda parser1-result
        (if (is-parse-success parser1-result)
          ((lambda parser2-result
            (if (is-parse-success parser2-result)
              (new-parse-success
                (new-pair
                  (parse-success.value parser1-result)
                  (parse-success.value parser2-result))
                (parse-success.state parser2-result)
                (parse-success.rest parser2-result))
              parser2-result))
          (parser2
            (parse-success.rest parser1-result)
            (parse-success.state parser1-result)))
          parser1-result))
      (parser1 input state)))))

(def combine-parser-left
  (lambda parser1 parser2
    (map-parser-value (combine-parser parser1 parser2) first)))

(def combine-parser-right
  (lambda parser1 parser2
    (map-parser-value (combine-parser parser1 parser2) second)))

(def repeat-parser
  (lambda parser
    (lambda input state
      ((lambda result
        (if (is-parse-success result)
          ((lambda rest-result
            (new-parse-success
              (cons
                (parse-success.value result)
                (parse-success.value rest-result))
              (parse-success.state rest-result)
              (parse-success.rest rest-result)))
          (repeat-parser parser
            (parse-success.rest result)
            (parse-success.state result)))
          (new-parse-success nil state input)))
      (parser input state)))))

(def repeat-parser1
  (lambda parser
    (map-parser-value
      (combine-parser parser (repeat-parser parser))
        (lambda pair
          (cons (first pair) (second pair))))))

(def alternative-parser
  (lambda parser1 parser2
    (lambda input state
      ((lambda parser1-result
        (if (is-parse-success parser1-result)
          parser1-result
          (parser2 input state)))
      (parser1 input state)))))

(def lazy-parser
  (lambda parser input state
    ((parser nil) input state)))

(def identifier-expr
  (new-data (keyword identifier-expr)
    (cons (keyword name)
    (cons (keyword line)
      nil))))

(def new-identifier-expr
  (lambda name line
    (identifier-expr (cons name (cons line nil)))))

(def identifier-expr.name (field (keyword name)))
(def identifier-expr.line (field (keyword line)))

(def list-expr
  (new-data (keyword list-expr)
    (cons (keyword exprs)
    (cons (keyword line)
      nil))))

(def new-list-expr
  (lambda exprs line
    (list-expr (cons exprs (cons line nil)))))

(def list-expr.exprs (field (keyword exprs)))
(def list-expr.line (field (keyword line)))

(def one (keyword->int (keyword 1)))

(def keyword->int->char (compose int->char keyword->int))

(def open-parentheses (keyword->int->char (keyword 40)))
(def close-parentheses (keyword->int->char (keyword 41)))
(def semicolon (keyword->int->char (keyword 59)))
(def space (keyword->int->char (keyword 32)))

(def tab (keyword->int->char (keyword 9)))
(def linefeed (keyword->int->char (keyword 10)))
(def vtab (keyword->int->char (keyword 11)))
(def formfeed (keyword->int->char (keyword 12)))
(def carriage-return (keyword->int->char (keyword 13)))

(def is-newline
  (lambda char
    (or (eq-char char linefeed)
        (lambda
          (or (eq-char char carriage-return)
              (lambda
                (eq-char char formfeed)))))))

(def is-whitespace
  (lambda char
    (or (is-newline char)
        (lambda
          (or (eq-char char space)
              (lambda
                (or (eq-char char tab)
                    (lambda (eq-char char vtab)))))))))

(def is-identifier-character
  (lambda char
    (not
      (or (is-whitespace char)
          (lambda
            (or (eq-char char open-parentheses)
                (lambda
                  (eq-char char close-parentheses))))))))

(def file.read (field (keyword read)))

(def char-parser
  (lambda char
    (predicate-parser (eq-char char))))

(def newline-parser
  (map-parser-state
    (predicate-parser is-newline)
    (add-int one)))

(def whitespace-parser
  (alternative-parser
    newline-parser
    (predicate-parser is-whitespace)))

(def comment-parser
  (combine-parser
    (char-parser semicolon)
    (repeat-parser (predicate-parser (compose not is-newline)))))

(def ignore-unused
  (lambda parser
    (combine-parser-right
      (repeat-parser (alternative-parser whitespace-parser comment-parser))
      parser)))

(def parser)

(def identifier-char-parser
  (predicate-parser is-identifier-character))

(def identifier-expr-parser
  (ignore-unused
    (map-parser-value
      (provide-past-state
        (repeat-parser1 identifier-char-parser))
      (lambda pair
        (new-identifier-expr (first pair) (second pair))))))

(def list-expr-parser
  (ignore-unused
    (map-parser-value
      (provide-past-state
        (combine-parser-right
          (char-parser open-parentheses)
          (combine-parser-left
            (lazy-parser (lambda parser))
            (char-parser close-parentheses))))
      (lambda pair
        (new-list-expr (first pair) (second pair))))))

(def expr-parser
  (alternative-parser
    identifier-expr-parser
    list-expr-parser))

(def parser
  (repeat-parser expr-parser))

(def parse
  (lambda input
    (parse-success.value
      (parser input one))))

(def compile
  (lambda in-file out-file
    (run-with (file.read in-file)
      (lambda char-stream
        (generate in-file out-file
          (parse char-stream))))))

(run-unsafe
  (compile
    (file (car args))
    (file (cadr args))))