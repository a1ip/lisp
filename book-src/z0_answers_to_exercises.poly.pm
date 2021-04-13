% -- Глава 2 ------------------------

◊exanswer{lisp1-2-omega/ex:funcall}

На Scheme оно переводится непосредственно как ◊ic{(cons~1~2)}. Если быть
дотошным, то можно сделать так:

◊begin{code:lisp}
(define (funcall f . args) (apply f args))
(define (function f) f)
◊end{code:lisp}

◊noindent
Или то~же самое с~помощью макросов:

◊begin{code:lisp}
(define-syntax funcall
  (syntax-rules ()
    ((funcall f arg ...) (f arg ...)) ) )

(define-syntax function
  (syntax-rules ()
    ((function f) f) ) )
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:lexical}

Перед ответом на этот вопрос сначала попробуйте ответить на два других:

◊begin{enumerate}
  ◊item Можно~ли ссылаться на функцию ◊ic{bar} до того, как она была
        определена?

  ◊item Если ◊ic{bar} всё~же была определена ранее, то как поведёт себя
        ◊ic{defun}: выдаст ошибку или переопределит функцию?
◊end{enumerate}

А~собственно результат исполнения программы зависит от того, что возвращает
специальная форма ◊ic{function}: ◊emph{саму} функцию ◊ic{bar} или некоторое
значение, связанное с~именем ◊ic{bar} в~пространстве функций.


◊exanswer{lisp1-2-omega/ex:innovations}

За вызовы функций отвечает ◊ic{invoke}, так что достаточно просто научить её
не~пугаться при виде чисел и списков. Вот~так:

◊indexC{invoke}
◊begin{code:lisp}
(define (invoke fn args)
  (cond ((procedure? fn) (fn args))
        ((number? fn)
         (if (= (length args) 1)
             (if (>= fn 0)
                 (list-ref (car args) fn)
                 (list-tail (car args) (- fn)) )
             (wrong "Incorrect arity" fn) ) )
        ((pair? fn)
         (map (lambda (f) (invoke f args)) fn) )
        (else (wrong "Cannot apply" fn)) ) )
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:assoc-with-comparator}

Сложность здесь в~том, что компаратор берётся из определяемого Лиспа и
возвращает логические значения оттуда~же.

◊indexC{assoc/de}
◊begin{code:lisp}
(definitial new-assoc/de
  (lambda (values current.denv)
    (if (= 3 (length values))
        (let ((tag        (car values))
              (default    (cadr values))
              (comparator (caddr values)) )
          (let look ((denv current.denv))
            (if (pair? denv)
                (if (eq? the-false-value
                         (invoke comparator (list tag (caar denv))
                                            current.denv ) )
                    (look (cdr denv))
                    (cdar denv) )
                (invoke default (list tag) current.denv) ) ) )
        (wrong "Incorrect arity" 'assoc/de) ) ) )
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:dynamic}

Функция-обработчик ◊ic{specific-error} должна будет вывести соответствующее
сообщение о~неизвестной динамической переменной.

◊indexC{dynamic-let}
◊indexC{dynamic}
◊indexC{dynamic-set"!}
◊begin{code:lisp}
(define-syntax dynamic-let
  (syntax-rules ()
    ((dynamic-let () . body)
     (begin . body) )
    ((dynamic-let ((variable value) others ...) . body)
     (bind/de 'variable (list value)
              (lambda () (dynamic-let (others ...) . body)) ) ) ) )

(define-syntax dynamic
  (syntax-rules ()
    ((dynamic variable)
     (car (assoc/de 'variable specific-error)) ) ) )

(define-syntax dynamic-set!
  (syntax-rules ()
    ((dynamic-set! variable value)
     (set-car! (assoc/de 'variable specific-error) value) ) ) )
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:write-put/get-prop}

Переменная ◊ic{properties}, замыкаемая обеими функциями, содержит список свойств
всех символов.

◊begin{code:lisp}
(let ((properties '()))
  (set! putprop
        (lambda (symbol key value)
          (let ((plist (assq symbol properties)))
            (if (pair? plist)
                (let ((couple (assq key (cdr plist))))
                  (if (pair? couple)
                      (set-cdr! couple value)
                      (set-cdr! plist (cons (cons key value)
                                            (cdr plist) )) ) )
                (let ((plist (list symbol (cons key value))))
                  (set! properties (cons plist properties)) ) ) )
          value ) )
  (set! getprop
        (lambda (symbol key)
          (let ((plist (assq symbol properties)))
            (if (pair? plist)
                (let ((couple (assq key (cdr plist))))
                  (if (pair? couple)
                      (cdr couple)
                      #f ) )
                #f ) ) ) ) )
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:label}

Просто добавьте следующие строки в~◊ic{evaluate}:

◊begin{code:lisp}
...
((label)  ; Синтаксис: ◊ic{(label ◊ii{имя} (lambda (◊ii{аргументы}) ◊ii{тело}))}
 (let* ((name    (cadr e))
        (new-env (extend env (list name) (list 'void)))
        (def     (caddr e))
        (fun     (make-function (cadr def) (cddr def) new-env)) )
   (update! name new-env fun)
   fun ) )
...
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:labels}

Достаточно добавить следующий фрагмент в~◊ic{f.evaluate}. Обратите внимание на
его схожесть с~определением ◊ic{flet}; разница только в~окружении, где создаются
локальные функции.

◊begin{code:lisp}
...
((labels)
 (let ((new-fenv (extend fenv
                         (map car (cadr e))
                         (map (lambda (def) 'void) (cadr e)) )))
   (for-each (lambda (def)
               (update! (car def)
                        new-fenv
                        (f.make-function (cadr def) (cddr def)
                                         env new-fenv ) ) )
             (cadr e) )
   (f.eprogn (cddr e) env new-fenv) ) )
...
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:orderless-letrec}

Так как форма ◊ic{let} сохраняет неопределённый порядок вычислений, то её
следует использовать для вычисления значений переменных формы ◊ic{letrec}.
Связывание~же этих переменных с~полученными значениями необходимо выполнять
отдельно. Имена для всех этих ◊ii{temp}◊sub{◊ii{i}} можно получить или с~помощью
механизма макрогигены, или просто кучей вызовов ◊ic{gensym}.

◊begin{code:lisp}
(let ((|◊ii{переменная}◊sub{1}| 'void)
      ...
      (|◊ii{переменная}◊sub{◊ii{n}}| 'void) )
  (let ((|◊ii{temp}◊sub{1}| |◊ii{выражение}◊sub{1}|)
        ...
        (|◊ii{temp}◊sub{◊ii{n}}| |◊ii{выражение}◊sub{◊ii{n}}|) )
    (set! |◊ii{переменная}◊sub{1}| |◊ii{temp}◊sub{1}|)
    ...
    (set! |◊ii{переменная}◊sub{◊ii{n}}| |◊ii{temp}◊sub{◊ii{n}}|)
    |◊ii{тело}| ) )
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:fixn}

Вот вам вариант для бинарных функций. $◊eta$"=конверсия была модифицирована
соответствующим образом.

◊begin{code:lisp}
(define fix2
  (let ((d (lambda (w)
             (lambda (f)
               (f (lambda (x y) (((w w) f) x y))) ) )))
    (d d) ) )
◊end{code:lisp}

◊noindent
После этого довольно легко догадаться, как сделать $n$-арную версию:

◊begin{code:lisp}
(define fixN
  (let ((d (lambda (w)
             (lambda (f)
               (f (lambda args (apply ((w w) f) args))) ) )))
    (d d) ) )
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:nfixn}

Ещё одно умственное усилие — и вы увидите, что предыдущее определение
◊ic{fixN} легко расширяется:

◊begin{code:lisp}
(define 2fixN
  (let ((d (lambda (w)
             (lambda (f*)
               (list ((car f*)
                      (lambda a (apply (car ((w w) f*)) a))
                      (lambda a (apply (cadr ((w w) f*)) a)) )
                     ((cadr f*)
                      (lambda a (apply (car ((w w) f*)) a))
                      (lambda a (apply (cadr ((w w) f*)) a)) ) ) ) )))
    (d d) ) )
◊end{code:lisp}

После этого остаётся понять, когда именно должен быть вычислен терм
◊ic{((w~w)~f)}, и~можно будет написать правильную универсальную версию:

◊begin{code:lisp}
(define NfixN
  (let ((d (lambda (w)
             (lambda (f*)
               (map (lambda (f)
                      (apply f (map (lambda (i)
                                      (lambda a
                                        (apply (list-ref ((w w) f*) i)
                                               a ) ) )
                                    (iota 0 (length f*)) )) )
                    f* ) ) )))
    (d d) ) )
◊end{code:lisp}

Внимание: порядок функций важен. Если определение ◊ic{odd?} идёт первым в~списке
функционалов, то именно эта функция будет связана с~их первыми аргументами.

◊indexC{iota}
Функция ◊ic{iota} аналогична одноимённому примитиву~$◊iota$ языка~APL:

◊begin{code:lisp}
(define (iota start end)
  (if (< start end)
      (cons start (iota (+ 1 start) end))
      '() ) )
◊end{code:lisp}


◊exanswer{lisp1-2-omega/ex:klop}

◊cite{bar84} приписывает эту функцию Яну~Виллему~Клопу. Можете проверить, что
◊ic{((klop meta-fact) 5)} действительно возвращает~◊ic{120}.

Так как все внутренние переменные ◊ic{s}, ◊ic{c}, ◊ic{h}, ◊ic{e},~◊ic{m}
связываются с~одной~◊ic{r}, то их порядок в~аппликации ◊ic{(m~e~c~h~e~s)}
не~имеет значения. Важно только их количество. Вернее, согласованная арность:
можно оставить одну переменную~◊ic{w}, а можно использовать хоть весь алфавит
— в~любом случае получится~◊comb{Y}◊!.


◊exanswer{lisp1-2-omega/ex:hyper-fact}

Абсолютно неожиданный ответ: 120. Вам ведь понравилось выражать рекурсию
с~помощью самоприменения, правда? Данное определение можно записать немного
по-другому, используя вложенные ◊ic{define}:

◊begin{code:lisp}
(define (factfact n)
  (define (internal-fact f n)
    (if (= n 0) 1
        (* n (f f (- n 1))) ) )
  (internal-fact internal-fact n) )
◊end{code:lisp}


% -- Глава 3 ------------------------

◊begingroup
◊def◊cc#1{◊ensuremath{◊text{◊ic{cc}}_{#1}}}
◊def◊tc#1{◊text{◊ic{#1}}}

◊exanswer{escape/ex:cc-cc}

◊indexC{the-current-continuation}
Эту форму можно было назвать ◊ic{(the-current-continuation)}, так как она
возвращает собственное продолжение. Давайте разберёмся, как у~неё это
получается. Для понятности будем нумеровать используемые продолжения и функции,
а ◊ic{call/cc} сократим до просто~◊ic{cc}. Итак, вычисляемое выражение:
◊ic{◊cont{k_0}(◊cc1~◊cc2)}. $k_0$ — это продолжение данных вычислений.
Определение ◊ic{call/cc}:

◊begin{code:lisp}
|◊cont*{k}|(call/cc |$◊phi$|)  |◊is|  |◊cont*{k}|(|$◊phi$| |$k$|)
◊end{code:lisp}

◊noindent
Следовательно, ◊ic{◊cont{k_0}(◊cc1~◊cc2)} становится
◊ic{◊cont{k_0}(◊cc2~$k_0$)}, которое в~свою очередь переходит
в~◊ic{◊cont{k_0}($k_0$~$k_0$)}, которое, очевидно, возвращает~$k_0$.


◊exanswer{escape/ex:cc-cc-cc-cc}

Используя нотацию предыдущего упражнения, запишем: ◊ic{◊cont{k_0}(({◊cc1}
{◊cc2})◊:({◊cc3} {◊cc4}))}. Для простоты будем считать, что термы аппликаций
вычисляются слева направо. Тогда исходное выражение эквивалентно
◊ic{◊cont{k_0}(◊cont{k_1}({◊cc1} {◊cc2})◊:({◊cc3} {◊cc4}))}, где $k_1$ равно
$◊lambda◊phi . ◊tc{◊cont{k_0}($◊phi$ ◊cont{k_2}({◊cc3} {◊cc4}))}$, а $k_2$ это
$◊lambda◊epsilon . ◊tc{◊cont{k_0}($k_1$~$◊epsilon$)}$. Вычисление первого терма
приводит к~◊ic{◊cont{k_0}($k_1$ $k_2$)}, а вычисление этого —
к~◊ic{◊cont{k_0}($k_2$ ◊cont{k'_2}({◊cc3} {◊cc4}))}, где {$k'_2$} равно
$◊lambda◊epsilon . ◊tc{◊cont{k_0}($k_2$~$◊epsilon$)}$. Эта форма вычисляется
в~◊ic{◊cont{k_0}($k_1$ $k'_2$)}, что впоследствии приводит
к~◊ic{◊cont{k_0}($k_1$ $k''_2$)}, и~так далее. Как видите, вычисления
зацикливаются. Можно доказать, что результат не~зависит от порядка вычисления
термов аппликаций. Вполне вероятно, что это самая короткая программа на Лиспе,
выражающая бесконечный цикл.

◊endgroup % ◊def cc, tc


◊exanswer{escape/ex:tagbody}

Метки разделяют тело ◊ic{tagbody} на отдельные последовательности выражений. Эти
последовательности оборачиваются в~функции и помещаются в~гигантскую форму
◊ic{labels}. Формы ◊ic{go} преобразуются в~вызовы соответствующих функций, но
данные вызовы выполняются специальным образом, чтобы ◊ic{go} получила правильное
продолжение. В~итоге ◊ic{tagbody} становится этим:

◊begingroup
◊def◊L#1{◊ii{метка}◊sub{#1}}
◊def◊E#1{◊ii{выражения}◊sub{#1}}
◊begin{code:lisp}
(block EXIT
  (let (LABEL (TAG (list 'tagbody)))
    (labels ((INIT  () |◊E0|... (|◊L1|))
             (|◊L1| () |◊E1|... (|◊L2|))
             ...
             (|◊L{◊ii{n}}| () |◊E{◊ii{n}}|... (return-from EXIT nil)) )
      (setq LABEL (function INIT))
      (while #t
        (setq LABEL (catch TAG (funcall LABEL))) ) ) ) )
◊end{code:lisp}
◊endgroup

Формы ◊ic{(go ◊ii{метка})} становятся~◊ic{(throw TAG ◊ii{метка})}, а
◊ic{(return ◊ii{значение})} превращается в~◊ic{(return-from EXIT
◊ii{значение})}. Имена переменных, записанные ◊ic{ПРОПИСНЫМИ} буквами,
не~должны конфликтовать с~переменными, используемыми в~теле ◊ic{tagbody}.

Такое сложное представление ◊ic{go} необходимо для того, чтобы обеспечить
переходам правильное продолжение: в~форме ◊ic{(bar (go~L))} не~надо вызывать
функцию ◊ic{bar} после того, как ◊ic{(go~L)} вернёт значение. Если этого
не~сделать, то вот такая программа будет вести себя неправильно:

◊begin{code:lisp}
(tagbody  A (return (+ 1 (catch 'foo (go B))))
          B (* 2 (throw 'foo 5)) )
◊end{code:lisp}

◊noindent
См.~также~◊cite{bak92c}.


◊exanswer{escape/ex:arity-optimize}

Введите новый класс функций:

◊begin{code:lisp}
(define-class function-with-arity function (arity))
◊end{code:lisp}

◊noindent
Затем измените обработку ◊ic{lambda}-форм, чтобы они возвращали именно такие
объекты:

◊begin{code:lisp}
(define (evaluate-lambda n* e* r k)
  (resume k (make-function-with-arity n* e* r (length n*))) )
◊end{code:lisp}

◊noindent
И,~наконец, реализуйте оптимизированный протокол вызова данных функций:

◊begin{code:lisp}
(define-method (invoke (f function-with-arity) v* r k)
  (if (= (function-with-arity-arity f) (length v*))
      (let ((env (extend-env (function-env f)
                             (function-variables f) v* )))
        (evaluate-begin (function-body f) env k) )
      (wrong "Incorrect arity" (function-variables f) v*) ) )
◊end{code:lisp}


◊exanswer{escape/ex:apply}

◊indexC{apply}
◊begin{code:lisp}
(definitial apply
  (make-primitive 'apply
   (lambda (v* r k)
     (if (>= (length v*) 2)
         (let ((f (car v*))
               (args (let flat ((args (cdr v*)))
                       (if (null? (cdr args))
                           (car args)
                           (cons (car args) (flat (cdr args))) ) )) )
           (invoke f args r k) )
         (wrong "Incorrect arity" 'apply) ) ) ) )
◊end{code:lisp}


◊exanswer{escape/ex:dotted}

Определите новый класс функций по аналогии
с~упражнением~◊ref{escape/ex:arity-optimize}.

◊begin{code:lisp}
(define-class function-nary function (arity))

(define (evaluate-lambda n* e* r k)
  (resume k (make-function-nary n* e* (length n*))) )

(define-method (invoke (f function-nary) v* r k)
  (define (extend-env env names values)
    (if (pair? names)
        (make-variable-env
         (extend-env env (cdr names) (cdr values))
         (car names)
         (car values) )
        (make-variable-env env names values) ) )
  (if (>= (length v*) (function-nary-arity f))
      (let ((env (extend-env (function-env f)
                             (function-variables f)
                             v* )))
        (evaluate-begin (function-body f) env k) )
      (wrong "Incorrect arity" (function-variables f) v*) ) )
◊end{code:lisp}


◊exanswer{escape/ex:evaluate}

Реализуйте циклическое выполнение ◊ic{evaluate} с~помощью начального
продолжения:

◊begin{code:lisp}
(define (chapter3-interpreter-2)
  (letrec ((k.init (make-bottom-cont
                    'void (lambda (v) (display v)
                                      (toplevel) ) ))
           (toplevel (lambda () (evaluate (read r.init k.init)))) )
    (toplevel) ) )
◊end{code:lisp}


◊exanswer{escape/ex:cc-value}

Определите соответствующий класс значений-продолжений. Он должен инкапсулировать
продолжения языка реализации и предоставлять метод для их активации.
◊ic{call/cc} теперь будет возвращать именно такие объекты.

◊indexC{call/cc}
◊begin{code:lisp}
(define-class reified-continuation value (k))

(definitial call/cc
  (make-primitive 'call/cc
   (lambda (v* r k)
     (if (= 1 (length v*))
         (invoke (car v*) (list (make-reified-continuation k)) r k)
         (wrong "Incorrect arity" 'call/cc v*) ) ) ) )

(define-method (invoke (f reified-continuation) v* r k)
  (if (= 1 (length v*))
      (resume (reified-continuation-k f) (car v*))
      (wrong "Continuations expect one argument" v* r k) ) )
◊end{code:lisp}


◊exanswer{escape/ex:eternal}

Вычисление функции заканчивается возвратом значения. Перехватывайте все попытки
вернуть его.

◊begin{code:lisp}
(defun eternal-return (thunk)     |◊dialect{◊CommonLisp}|
  (labels ((loop ()
             (unwind-protect (thunk)
               (loop) ) ))
    (loop) ) )
◊end{code:lisp}


◊exanswer{escape/ex:crazy-cc}

Значения этих выражений: 33 и~44 соответственно. Функция ◊ic{make-box} создаёт
◊term{коробку}, которая может хранить в~себе одно значение. Причём это значение
можно изменять без видимых побочных эффектов. Достигается такое поведение
с~помощью ◊ic{call/cc} и ◊ic{letrec}. Если вспомнить, что ◊ic{letrec}
эквивалентна комбинации ◊ic{let} и ◊ic{set!}, то станет понятнее, каким образом
нам удаётся получить такой эффект. Полноценные продолжения Scheme, способные
сколько угодно раз возвращаться к~прерванным вычислениям, позволяют отделить
неявную ◊ic{set!}-часть формы ◊ic{letrec} от её ◊ic{let}-части.


◊exanswer{escape/ex:generic-evaluate}

Сначала сделайте ◊ic{evaluate} обобщённой:

◊begin{code:lisp}
(define-generic (evaluate (e) r k)
  (wrong "Not a program" e) )
◊end{code:lisp}

◊noindent
Затем напишите для неё методы, вызывающие соответствующие функции:

◊begin{code:lisp}
(define-method (evaluate (e quotation) r k)
  (evaluate-quote (quotation-value e) r k) )

(define-method (evaluate (e assignment) r k)
  (evaluate-set! (assignment-name e)
                 (assignment-form e)
                 r k ) )
...
◊end{code:lisp}
◊noindent
Также вам понадобятся новые классы объектов для представления различных частей
программ:

◊begin{code:lisp}
(define-class program    Object  ())
(define-class quotation  program (value))
(define-class assignment program (name form))
...
◊end{code:lisp}

Всё, теперь остаётся только определить функцию, преобразующую текст программ
в~объекты класса ◊ic{program}. Эта функция, называемая ◊ic{objectify},
рассматривается в~разделе~◊ref{macros/macrosystem/ssect:object}.


◊exanswer{escape/ex:throw}

Функция ◊ic{throw} определяется вот~так:

◊begin{code:lisp}
(definitial throw
  (make-primitive 'throw
   (lambda (v* r k)
     (if (= 2 (length v*))
         (catch-lookup k (car v*)
                       (make-throw-cont k
                        `(quote ,(cadr v*)) r ) )
         (wrong "Incorrect arity" 'throw v*) ) ) ) )
◊end{code:lisp}

Вместо того, чтобы определять новый метод для ◊ic{catch-lookup}, мы просто
подсунули ей фальшивое продолжение, чтобы заставить интерпретатор вести себя
ожидаемым образом: вычислить и вернуть второй аргумент ◊ic{throw}, когда
найдётся соответствующая форма ◊ic{catch}.


◊exanswer{escape/ex:cps-speed}

◊indexE{CPS}
◊indexR{стиль передачи продолжений (CPS)}
CPS-код медленнее обычного, так как он вынужден постоянно создавать замыкания
для явного представления продолжений.

Между прочим, CPS-преобразование не~идемпотентно; то есть, применив его
к~программе, уже переписанной в~стиле передачи продолжений, мы получим ещё одну,
третью версию той~же программы. Рассмотрим, например, определение факториала:

◊indexC{fact}
◊begin{code:lisp}
(define (cps-fact n k)
  (if (= n 0) (k 1)
      (cps-fact (- n 1) (lambda (v) (k (* n v)))) ) )
◊end{code:lisp}

Очевидно, что ◊ic{k} — это просто аргумент функции ◊ic{cps-fact}. Он может
быть вообще чем угодно. В~том числе и таким продолжением:

◊begin{code:lisp}
(call/cc (lambda (k) (* 2 (cps-fact 4 k)))) |◊is| 24
◊end{code:lisp}


◊exanswer{escape/ex:the-current-cc}

Функцию ◊ic{the-current-continuation} также можно определить подобно
упражнению~◊ref{escape/ex:cc-cc}.

◊indexC{call/cc}
◊begin{code:lisp}
(define (cc f)
  (let ((reified? #f))
    (let ((k (the-current-continuation)))
      (if reified? k
          (begin (set! reified? #t)
                 (f k) ) ) ) ) )
◊end{code:lisp}

Большое спасибо Люку~Моро за эту пару упражнений ◊cite{mor94}.


% -- Глава 4 ------------------------

◊exanswer{assignment/ex:pure-min-max}

Количество способов написания этой функции огромно. Например, можно возвращать
промежуточные результаты или использовать продолжения:

◊indexC{min-max}
◊begin{code:lisp}
(define (min-max1 tree)
  (define (mm tree)
    (if (pair? tree)
        (let ((a (mm (car tree)))
              (b (mm (cdr tree))) )
          (list (min (car a) (car d))
                (max (cadr a) (cadr d)) ) )
        (list tree tree) ) )
  (mm tree) )

(define (min-max2 tree)
  (define (mm tree k)
    (if (pair? tree)
        (mm (car tree)
            (lambda (mina maxa)
              (mm (cdr tree)
                  (lambda (mind maxd)
                    (k (min mina mind)
                       (max maxa maxd) ) ) ) ) )
        (k tree tree) ) )
  (mm tree list) )
◊end{code:lisp}

◊indexE{deforestation}
Первый вариант в~процессе работы постоянно создаёт и тут~же уничтожает кучу
списков. Ситуацию можно поправить с~помощью известной оптимизации, называемой
◊term{deforestation} ◊cite{wad88}. Она позволяет избавиться от лишних
промежуточных структур данных. Второй вариант в~этом плане ничем не~лучше:
просто вместо списков здесь замыкания. Исходная версия гораздо быстрее любого из
них (но она использует <<невыносимо отвратительные>> побочные эффекты).


◊exanswer{assignment/ex:lambda-cons}

Функции начинаются на~◊ic{q}, чтобы избежать путаницы.

◊indexC{cons}◊indexC{car}◊indexC{cdr}
◊begin{code:lisp}
(define (qons a d) (lambda (msg) (msg a d)))
(define (qar pair) (pair (lambda (a d) a)))
(define (qdr pair) (pair (lambda (a d) d)))
◊end{code:lisp}


◊exanswer{assignment/ex:destructive-eq}

Идея в~том, что две точечные пары идентичны, если модификация одной из них
приводит к~изменениям в~другой.

◊begin{code:lisp}
(define (pair-eq? a b)
  (let ((tag (list 'tag))
        (old-car (car a)) )
    (set-car! a tag)
    (let ((result (eq? (car b) tag)))
      (set-car! a old-car)
      result ) ) )
◊end{code:lisp}


◊exanswer{assignment/ex:form-or}

Добавляете анализ новой специальной формы в~◊ic{evaluate}:

◊begin{code:lisp}
...
((or) (evaluate-or (cadr e) (caddr e) r s k))
...
◊end{code:lisp}

◊noindent
После этого определяете её как-то~так:

◊begin{code:lisp}
(define (evaluate-or e1 e2 r s k)
  (evaluate e1 r s (lambda (v ss)
                     (((v 'boolify)
                       (lambda () (k v ss))
                       (lambda () (evaluate e2 [r k s])) )) )) )
◊end{code:lisp}

Суть в~том, что вычисление альтернативной ветки~$◊beta$ производится в~старой
памяти~◊ic{s}, а~не~в~новой~◊ic{ss}.


◊exanswer{assignment/ex:previous-value}

◊indexR{возвращаемые значения!присваивания}
◊indexCS{set"!}{возвращаемое значение}
◊indexR{присваивание!возвращаемое значение}
Вообще-то такая формулировка задания допускает разночтения: можно ведь
возвращать то значение переменной, которое она имела до вычисления её нового
значения, а можно вернуть и~то, каким оно стало после.

◊begin{code:lisp}
(define (pre-evaluate-set! n e r s k)
  (evaluate e r s
    (lambda (v ss)
      (k ([ss] (r n)) (update ss (r n) v)) ) ) )

(define (post-evaluate-set! n e r s k)
  (evaluate e r s
    (lambda (v ss)
      (k ([s] (r n)) (update ss (r n) v)) ) ) )
◊end{code:lisp}

◊noindent
Это важно. Например, значение данного выражения зависит от реализации:

◊begin{code:lisp}
(let ((x 1))
  (set! x (set! x 2)) )
◊end{code:lisp}


◊exanswer{assignment/ex:apply/cc}

Основная сложность в~◊ic{apply} — это правильно обработать список её
аргументов, созданный интерпретатором определяемого языка.

◊indexC{apply}
◊begin{code:lisp}
(definitial apply
  (create-function
   -11 (lambda (v* s k)
         (define (first-pairs v*)
           ;; ◊ic{(assume (pair? v*))}
           (if (pair? (cdr v*))
               (cons (car v*) (first-pairs (cdr v*)))
               '() ) )
         (define (terms-of v s)
           (if (eq? (v 'type) 'pair)
               (cons (s (v 'car)) (terms-of (s (v 'cdr)) s))
               '() ) )
         (if (>= (length v*) 2)
             (if (eq? ((car v*) 'type) 'function)
                 (((car v*) 'behavior)
                  (append (first-pairs (cdr v*))
                          (terms-of (car (last-pair (cdr v*))) s) )
                  s k )
                 (wrong "First argument not a function") )
             (wrong "Incorrect arity") ) ) ) )
◊end{code:lisp}

Функция ◊ic{call/cc} сохраняет каждое продолжение в~собственной ячейке памяти,
чтобы сделать их уникальными.

◊indexC{call/cc}
◊begin{code:lisp}
(definitial call/cc
  (create-function
   -13 (lambda (v* s k)
         (if (= 1 (length v*))
             (if (eq? ((car v*) 'type) 'function)
                 (allocate 1 s
                  (lambda (a* ss)
                    (((car v*) 'behavior)
                     (list (create-function
                            (car a*)
                            (lambda (vv* sss kk)
                              (if (= 1 (length vv*))
                                  (k (car vv*) sss)
                                  (wrong "Incorrect arity") ) ) ))
                     ss k ) ) )
                 (wrong "Argument not a function") )
             (wrong "Incorrect arity") ) ) ) )
◊end{code:lisp}


◊exanswer{assignment/ex:dotted}

Сложность здесь состоит в~проверке совместимости количества фактически
полученных аргументов с~арностью вызываемой функции, а также в~преобразовании
списков и значений при передаче их между языками.

◊begin{code:lisp}
(define (evaluate-nlambda n* e* r s k)
  (define (arity n*)
    (cond ((pair? n*) (+ 1 (arity (cdr n*))))
          ((null? n*) 0)
          (else       1) ) )

  (define (update-environment r n* a*)
    (cond ((pair? n*) (update-environment
                       (update r (car n*) (car a*))
                       (cdr n*) (cdr* a) ))
          ((null? n*) r)
          (else (update r n* (car a*))) ) )

  (define (update-store s a* v* n*)
    (cond ((pair? n*) (update-store (update s (car a*) (car v*))
                                    (cdr a*) (cdr v*) (cdr n*) ))
          ((null? n*) s)
          (else (allocate-list v* s (lambda (v ss)
                                      (update ss (car a*) v) ))) ) )
  (allocate 1 s
    (lambda (a* ss)
      (k (create-function
          (car a*)
          (lambda (v* s k)
            (if (compatible-arity? n* v*)
                (allocate (arity n*) s
                 (lambda (a* ss)
                   (evaluate-begin e*
                                   (update-environment r n* a*)
                                   (update-store ss a* v n*)
                                   k ) ) )
                (wrong "Incorrect arity") ) ) )
         ss ) ) ) )

(define (compatible-arity? n* v*)
  (cond ((pair? n*) (and (pair? v*)
                         (compatible-arity? (cdr n*) (cdr v*)) ))
        ((null? n*) (null? v*))
        ((symbol? n*) #t) ) )
◊end{code:lisp}


% -- Глава 5 ------------------------

◊begingroup◊ChapterFiveSpecials

◊exanswer{denotational/ex:truly-random}

Доказывается индукцией по количеству термов аппликации.


◊exanswer{denotational/ex:label}

◊begin{denotation}
$◊Lain◊sem*{(label $◊n$ $◊p$)}◊r =
    (◊comb{Y}◊ ◊lambda ◊e.(◊Lain◊sem{◊p}◊ ◊r[◊n ◊to ◊e]))$
◊end{denotation}


◊exanswer{denotational/ex:dynamic-fallback}

◊begin{denotation}
$◊Eval◊sem*{(dynamic $◊n$)}◊r◊d◊k◊s = {}$                                     ◊◊
  $◊LET ◊e = (◊d◊ ◊n)$                                                        ◊◊
  $◊IN {}$◊.$◊IF   ◊e = ◊ii{no-dynamic-binding}$                              ◊◊
            $◊THEN {}$◊.$◊LET ◊a = (◊g◊ ◊n)$                                  ◊◊
                        $◊IN {}$◊.$◊IF   ◊a = ◊ii{no-global-binding}$         ◊◊
                                  $◊THEN ◊ii{wrong}◊ ◊ic{"No such variable"}$ ◊◊
                                  $◊ELSE (◊k◊ (◊s◊ ◊a)◊ ◊s)$                  ◊◊
                                  $◊ENDIF$                                ◊-◊-◊◊
            $◊ELSE (◊k◊ ◊e◊ ◊s)$                                              ◊◊
            $◊ENDIF$
◊end{denotation}


◊exanswer{denotational/ex:quantum}

Этот макрос помещает вычисление каждого терма в~собственное замыкание, после
чего выполняет все эти вычисления в~произвольном порядке, определяемом функцией
◊ic{determine!}.

◊begin{code:lisp}
(define-syntax unordered
  (syntax-rules ()
    ((unordered f) (f))
    ((unordered f arg ...)
     (determine! (lambda () f) (lambda () arg) ...) ) ) )

(define (determine! . thunks)
  (let ((results (iota 0 (length thunks))))
    (let loop ((permut (random-permutation (length thunks))))
      (if (pair? permut)
          (begin (set-car! (list-tail results (car permut))
                           (force (list-ref thunks (car permut))) )
                 (loop (cdr permut)) )
          (apply (car results) (cdr results)) ) ) ) )
◊end{code:lisp}

Заметьте, что порядок выбирается перед началом вычислений, так что такое
определение не~совсем идентично денотации, приведённой в~этой главе. Если
функция ◊ic{random-permutation} определена вот~так:

◊begin{code:lisp}
(define (random-permutation n)
  (shuffle (iota 0 n)) )
◊end{code:lisp}

◊noindent
то последовательность вычислений выбирается действительно динамически:

◊begin{code:lisp}
(define (d.determine! . thunks)
  (let ((results (iota 0 (length thunks))))
    (let loop ((permut (random-permutation (length thunks))))
      (if (pair? permut)
          (begin (set-car! (list-tail results (car permut))
                           (force (list-ref thunks (car permut))) )
                 (loop [(shuffle (cdr permut))]) )
          (apply (car results) (cdr results)) ) ) ) )
◊end{code:lisp}

◊endgroup %◊ChapterFiveSpecials


% -- Глава 6 ------------------------

◊exanswer{fast/ex:symbol-table}

Самый простой способ — это добавить ◊ic{CHECKED-GLOBAL-REF} ещё один аргумент
с~именем соответствующей переменной:

◊begin{code:lisp}
(define (CHECKED-GLOBAL-REF- i n)
  (lambda ()
    (let ((v (global-fetch i)))
      (if (eq? v undefined-value)
          (wrong "Uninitialized variable" n)
          v ) ) ) )
◊end{code:lisp}

Однако такой подход нерационально расходует память и дублирует информацию. Более
правильным решением будет создать специальную таблицу символов для хранения
соответствий между адресами переменных и их именами.

◊begin{code:lisp}
(define sg.current.names (list 'foo))
(define (standalone-producer e)
  (set! g.current (original.g.current))
  (let* ((m (meaning e r.init #t))
         (size (length g.current))
         (global-names (map car (reverse g.current))) )
    (lambda ()
      (set! sg.current (make-vector size undefined-value))
      (set! sg.current.names global-names)
      (set! *env* sr.init)
      (m) ) ) )

(define (CHECKED-GLOBAL-REF+ i)
  (lambda ()
    (let ((v (global-fetch i)))
      (if (eq? v undefined-value)
          (wrong "Uninitialized variable"
                 (list-ref sg.current.names i) )
          v ) ) ) )
◊end{code:lisp}


◊exanswer{fast/ex:list}

Функция ◊ic{list} — это, конечно~же, просто ◊ic{(lambda l~l)}. Вам надо
только выразить это определение с~помощью комбинаторов:

◊begin{code:lisp}
(definitial list ((NARY-CLOSURE (SHALLOW-ARGUMENT-REF 0) 0)))
◊end{code:lisp}


◊exanswer{fast/ex:disassemble}

Всё просто: достаточно переопределить каждый комбинатор~◊ii{k} как ◊ic{(lambda
args `(◊ii{k}~. ,args))} и распечатать результат предобработки.


◊exanswer{fast/ex:act-rec-before}

Решение в~лоб: вычислять термы аппликации справа налево:

◊begin{code:lisp}
(define (FROM-RIGHT-STORE-ARGUMENT m m* index)
  (lambda ()
    (let* ([(v* (m*))]
           [(v  (m))] )
      (set-activation-frame-argument! v* index v)
      v* ) ) )

(define (FROM-RIGHT-CONS-ARGUMENT m m* arity)
  (lambda ()
    (let* ([(v* (m*))]
           [(v  (m))] )
      (set-activation-frame-argument!
       v* arity (cons v (activation-frame-argument v* arity)) )
      v* ) ) )
◊end{code:lisp}

Также можно изменить не~порядок вычисления аргументов, а определение
◊ic{meaning*}, чтобы она создавала запись активации первой. В~любом случае
эффективнее будет сначала вычислить функциональный терм (порядок вычисления
остальных аргументов здесь не~важен), так как это позволяет узнать истинную
арность вызываемого замыкания и сразу создавать запись активации правильного
размера.


◊exanswer{fast/ex:redefine}

Определите синтаксис новой специальной формы в~◊ic{meaning}:

◊begin{code:lisp}
... ((redefine) (meaning-redefine (cadr e))) ...
◊end{code:lisp}

◊noindent
Затем реализуйте её предобработку:

◊begin{code:lisp}
(define (meaning-redefine n)
  (let ((kind1 (global-variable? g.init n)))
    (if kind1
        (let ((value (vector-ref sg.init (cdr kind)))
              (kind2 (global-variable? g.current n)) )
          (if kind2
              (static-wrong "Already redefined variable" n)
              (let ((index (g.current-extend! n)))
                (vector-set! sg.current index value) ) ) )
        (static-wrong "Can't redefine variable" n) )
    (lambda () 2001) ) )
◊end{code:lisp}

Подобные переопределения производятся во~время предобработки, ещё до исполнения
программы. Возвращаемое значение формы ◊ic{redefine} не~важно.


◊exanswer{fast/ex:boost-thunks}

Вызов функции без аргументов не~требует выделения памяти под переменные, то есть
расширения текущего окружения. Каждый дополнительный уровень окружения
увеличивает стоимость обращений к~свободным переменным замыканий, что
сказывается на быстродействии. Реализуйте новый комбинатор и добавьте
в~определение ◊ic{meaning-fix-abstraction} обработку соответствующего
специального случая.

◊begin{code:lisp}
(define (THUNK-CLOSURE m+)
  (let ((arity+1 (+ 0 1)))
    (lambda ()
      (define (the-function v* sr)
        (if (= (activation-frame-argument-length v*) arity+1)
            (begin (set! *env* sr)
                   (m+) )
            (wrong "Incorrect arity") ) )
      (make-closure the-function *env*) ) ) )

(define (meaning-fix-abstraction n* e+ r tail?)
  (let ((arity (length n*)))
    (if (= arity 0)
        (let ((m+ (meaning-sequence e+ r #t)))
          (THUNK-CLOSURE m+) )
        (let* ((r2 (r-extend* r n*))
               (m+ (meaning-sequence e+ r2 #t)) )
          (FIX-CLOSURE m+ arity) ) ) ) )
◊end{code:lisp}


% -- Глава 7 ------------------------

◊exanswer{compilation/ex:dynamic}

Сначала создайте новый регистр:

◊begin{code:lisp}
(define *dynenv* -1)
◊end{code:lisp}

◊noindent
Затем сохраняйте его вместе с~остальным окружением:

◊begin{code:lisp}
(define (preserve-environment)
  (stack-push *dynenv*)
  (stack-push *env*) )

(define (restore-environment)
  (set! *env* (stack-pop))
  (set! *dynenv* (stack-pop)) )
◊end{code:lisp}

◊noindent
Теперь динамическое окружение извлекается элементарно; лишь несколько изменилась работа со~стеком:

◊begin{code:lisp}
(define (search-dynenv-index)
  *dynenv* )

(define (pop-dynamic-binding)
  (stack-pop)
  (stack-pop)
  (set! *dynenv* (stack-pop)) )

(define (push-dynamic-binding index value)
  (stack-push *dynenv*)
  (stack-push value)
  (stack-push index)
  (set! *dynenv* (- *stack-index* 1)) )
◊end{code:lisp}


◊exanswer{compilation/ex:load}

Сама функция-то простая:

◊begin{code:lisp}
(definitial load
  (let* ((arity 1)
         (arity+1 (+ 1 arity)) )
    (make-primitive
     (lambda ()
       (if (= arity+1 (activation-frame-argument-length *val*))
           (let ((filename (activation-frame-argument *val* 0)))
             (set! *pc* (install-object-file! filename)) )
           (signal-exception
            #t (list "Incorrect arity" 'load) ) ) ) ) ) )
◊end{code:lisp}

◊noindent
Но вот при её использовании возникают определённые сложности. Всё дело
в~продолжениях. Допустим, с~помощью ◊ic{load} загружается следующий файл:

◊begin{code:lisp}
(display 'attention)
(call/cc (lambda (k) (set! *k* k)))
(display 'caution)
◊end{code:lisp}

◊noindent
Что случится, если после этого активировать продолжение ◊ic{*k*}? Правильно,
выведется символ ◊ic{caution}! А~потом?

Кроме того, определения глобальных переменных из загружаемого файла не~переходят
в~текущий (что, согласитесь, будет сюрпризом для функций, которые от них
зависят).


◊exanswer{compilation/ex:global-value}

Всё просто:

◊begin{code:lisp}
(definitial global-value
  (let* ((arity 1)
         (arity+1 (+ 1 arity)) )
    (define (get-index name)
      (let ((where (memq name sg.current.names)))
        (if where
            (- (length where) 1)
            (signal-exception
             #f (list "Undefined global variable" name) ) ) ) )
    (make-primitive
     (lambda ()
       (if (= arity+1 (activation-frame-argument-length *val*))
           (let* ((name (activation-frame-argument *val* 0))
                  (i (get-index name)) )
             (set! *val* (global-fetch i))
             (when (eq? *val* undefined-value)
               (signal-exception #f (list "Uninitialized variable" i)) )
             (set! *pc* (stack-pop)) )
           (signal-exception
            #t (list "Incorrect arity" 'global-value) ) ) ) ) ) )
◊end{code:lisp}

Во~время вызова этой функции переменная может как просто не~существовать, так и
ещё не~иметь значения. Оба этих случая необходимо проверять.


◊exanswer{compilation/ex:shallow-dynamic}

Для начала добавьте в~◊ic{run-machine} инициализацию вектора текущего состояния
динамического окружения:

◊begin{code:lisp}
... (set! *dynamics* (make-vector (+ 1 (length dynamics))
                                  undefined-value )) ...
◊end{code:lisp}

◊noindent
После чего переопределите функции-аксессоры на новый лад:

◊begin{code:lisp}
(define (find-dynamic-value index)
  (let ((v (vector-ref *dynamics* index)))
    (if (eq? v undefined-value)
        (signal-exception #f (list "No such dynamic binding" index))
        v ) ) )

(define (push-dynamic-binding index value)
  (stack-push (vector-ref *dynamics* index))
  (stack-push index)
  (vector-set! *dynamics* index value) )

(define (pop-dynamic-binding)
  (let* ((index (stack-pop))
         (old-value (stack-pop)) )
    (vector-set! *dynamics* index old-value) ) )
◊end{code:lisp}

Увы, но такое решение в~общем случае неверно. В~стеке сейчас сохраняются только
предыдущие значения динамических переменных, но не~текущие. Следовательно, любой
переход или активация продолжения приведут к~неправильному состоянию
динамического окружения, так как мы не~сможем восстановить значение
◊ic{*dynamics*} на момент входа в~форму ◊ic{bind-exit} или ◊ic{call/cc}. Чтобы
реализовать данное поведение, необходима форма ◊ic{unwind-protect}; ну, или
можно отказаться от такого подхода в~пользу дальнего связывания, где подобные
проблемы не~возникают в~принципе.


◊exanswer{compilation/ex:export-rename}

С~помощью следующей функции можно выразить даже взаимные переименования вида
◊ic{((fact fib) (fib fact))}. Но не~стоит этим злоупотреблять.

◊begin{code:lisp}
(define (build-application-with-renaming-variables
         new-application-name application-name substitutions )
  (if (probe-file application-name)
      (call-with-input-file application-name
        (lambda (in)
          (let* ((dynamics     (read in))
                 (global-names (read in))
                 (constants    (read in))
                 (code         (read in))
                 (entries      (read in)) )
            (close-input-port in)
            (write-result-file
             new-application-name
             (list ";;; Renamed variables from " application-name)
             dynamics
             (let sublis ((global-names global-names))
               (if (pair? global-names)
                   (cons (let ((s (assq (car global-names)
                                        substitutions )))
                           (if (pair? s)
                               (cadr s)
                               (car global-names) ) )
                         (sublis (cdr global-names)) )
                   global-names ) )
             constants
             code
             entries ) ) ) )
      (signal-exception #f (list "No such file" application-name)) ) )
◊end{code:lisp}


◊exanswer{compilation/ex:unchecked-ref}

Сделать это просто, только не~перепутайте коды инструкций и смещения!

◊begin{code:lisp}
(define-instruction (CHECKED-GLOBAL-REF i) 8
  (set! *val* (global-fetch i))
  (if (eq? val undefined-value)
      (signal-exception #t (list "Uninitialized variable" i))
      (vector-set! *code* (- *pc* 2) 7) ) )
◊end{code:lisp}


% -- Глава 8 ------------------------

◊exanswer{reflection/ex:no-cycles}

Она может не~волноваться об~этом, потому как сравнивает переменные не~по именам.
Такой подход правильно работает даже для списков с~циклами.


◊exanswer{reflection/ex:optimize-ce}

Вот вам подсказка:

◊begin{code:lisp}
(define (prepare e)
  (eval/ce `(lambda () ,e)) )
◊end{code:lisp}


◊exanswer{reflection/ex:no-capture}

◊begin{code:lisp}
(define (eval/at e)
  (let ((g (gensym)))
    (eval/ce `(lambda (,g) (eval/ce ,g))) ) )
◊end{code:lisp}


◊exanswer{reflection/ex:defined}

Да, определив специальный обработчик исключений:

◊begin{code:lisp}
(set! variable-defined?
      (lambda (env name)
        (bind-exit (return)
          (monitor (lambda (c ex) (return #f))
            (eval/b name env)
            #t ) ) ) )
◊end{code:lisp}


◊exanswer{reflection/ex:rnrs}

Реализацию специальной формы ◊ic{monitor}, которая используется в~рефлексивном
интерпретаторе, мы молча пропустим, так как она принципиально непереносима.
В~конце концов, если не~делать ошибок, то ◊ic{monitor} эквивалентна ◊ic{begin}.
Строго говоря, остальной код, что следует далее, тоже не~совсем легален, так
как использует переменные с~именами специальных форм. Однако, большинство
реализаций Scheme допускают такие вольности.

Форма ◊ic{the-environment}, захватывающая привязки:

◊begin{code:lisp}
(define-syntax the-environment
  (syntax-rules ()
    ((the-environment)
     (capture-the-environment make-toplevel make-flambda flambda?
      flambda-behavior prompt-in prompt-out exit it extend error
      global-env toplevel eval evlis eprogn reference quote if set!
      lambda flambda monitor ) ) ) )

(define-syntax capture-the-environment
  (syntax-rules ()
    ((capture-the-environment word ...)
     (lambda (name . value)
       (case name
         ((word) ((handle-location word) value)) ...
         ((display) (if (pair? value)
                        (wrong "Immutable" 'display)
                        show ))
         (else (if (pair? value)
                   (set-top-level-value! name (car value))
                   (top-level-value name) )) ) ) ) ) )

(define-syntax handle-location
  (syntax-rules ()
    ((handle-location name)
     (lambda (value)
       (if (pair? value) (set! name (car value))
           name ) ) ) ) )
◊end{code:lisp}

Функции ◊ic{variable-defined?}, ◊ic{variable-value} и ◊ic{set-variable-value!},
манипулирующие захваченными полноценными окружениями:

◊begin{code:lisp}
(define undefined (cons 'un 'defined))

(define-class Envir Object
  ( name value next ) )

(define (enrich env . names)
  (let enrich ((env env) (names names))
    (if (pair? names)
        (enrich (make-Envir (car names) undefined env)
                (cdr names) )
        env ) ) )

(define (variable-defined? name env)
  (if (Envir? env)
      (or (eq? name (Envir-name env))
          (variable-defined? name (Envir-next env)) )
      #f ) )

(define (variable-value name env)
  (if (Envir? env)
      (if (eq? name (Envir-name env))
          (let ((value (Envir-value env)))
            (if (eq? value undefined)
                (error "Uninitialized variable" name)
                value ) )
          (variable-value name (Envir-next env)) )
      (env name) ) )
◊end{code:lisp}

Как видите, окружения — это связные списки, заканчивающиеся замыканием.
Теперь рефлексивный интерпретатор может быть запущен!


% -- Глава 9 ------------------------

◊exanswer{macros/ex:repeat}

Используйте гигиеничные макросы Scheme:

◊begin{code:lisp}
(define-syntax repeat1
  (syntax-rules (:while :unless :do)
    ((_ :while p :unless q :do body ...)
     (let loop ()
       (if p (begin (if (not q) (begin body ...))
                    (loop) )) ) ) ) )
◊end{code:lisp}

◊noindent
Как вариант, можно всё сделать вручную с~помощью ◊ic{define-abbreviation}:

◊begin{code:lisp}
(with-aliases ((+let let) (+begin begin) (+when when) (+not not))
  (define-abbreviation (repeat2 . params)
    (let ((p    (list-ref  params 1))
          (q    (list-ref  params 3))
          (body (list-tail params 5))
          (loop (gensym)) )
      `(,+let ,loop ()
          (,+when ,p (,+begin (,+when (,+not ,q) . ,body)
                              (,loop) )) ) ) ) )
◊end{code:lisp}


◊exanswer{macros/ex:arg-sequence}

Вся хитрость в~том, как представить числа с~помощью одних только
макроопределений. Один из вариантов — это использовать списки такой~же длины,
что и представляемое ими число. Тогда во~время исполнения программы можно будет
получить нормальные числа с~помощью функции ◊ic{length}.

◊begin{code:lisp}
(define-syntax enumerate
  (syntax-rules ()
    ((enumerate) (display 0))
    ((enumerate e1 e2 ...)
     (begin (display 0)
            (enumerate-aux e1 (e1) e2 ...) ) ) ) )

(define-syntax enumerate-aux
  (syntax-rules ()
    ((enumerate-aux e1 len) (begin (display e1)
                                   (display (length 'len)) ))
    ((enumerate-aux e1 len e2 e3 ...)
     (begin (display e1)
            (display (length 'len))
            (enumerate-aux e2 (e2 . len) e3 ...) ) ) ) )
◊end{code:lisp}


◊exanswer{macros/ex:unique}

Достаточно переопределить функцию ◊ic{make-macro-environment} так, чтобы она
использовала текущий уровень, а не~создавала следующий:

◊begin{code:lisp}
(define (make-macro-environment current-level)
  (let ((metalevel [(delay current-level)]))
    (list (make-Magic-Keyword 'eval-in-abbreviation-world
           (special-eval-in-abbreviation-world metalevel) )
          (make-Magic-Keyword 'define-abbreviation
           (special-define-abbreviation metalevel) )
          (make-Magic-Keyword 'let-abbreviation
           (special-let-abbreviation metalevel) )
          (make-Magic-Keyword 'with-aliases
           (special-with-aliases metalevel) ) ) ) )
◊end{code:lisp}


◊exanswer{macros/ex:decompile}

Написать такой конвертер проще пареной репы. Единственный интересный момент —
это сборка списка аргументов функции. Здесь используется А-список для хранения
соответствий между аргументами и их именами.

◊begin{code:lisp}
(define-generic (->Scheme (e) r))

(define-method (->Scheme (e Alternative) r)
  `(if ,(->Scheme (Alternative-condition e) r)
       ,(->Scheme (Alternative-consequent e) r)
       ,(->Scheme (Alternative-alternant e) r) ) )

(define-method (->Scheme (e Local-Assignment) r)
  `(set! ,(->Scheme (Local-Assignment-reference e) r)
         ,(->Scheme (Local-Assignment-form e) r) ) )

(define-method (->Scheme (e Reference) r)
  (variable->Scheme (Reference-variable e) r) )

(define-method (->Scheme (e Function) r)
  (define (renamings-extend r variables names)
    (if (pair? names)
        (renamings-extend (cons (cons (car variables) (car names)) r)
                          (cdr variables) (cdr names) )
        r ) )
  (define (pack variables names)
    (if (pair? variables)
        (if (Local-Variable-dotted? (car variables))
            (car names)
            (cons (car names) (pack (cdr variables) (cdr names))) )
        '() ) )
  (let* ((variables (Function-variables e))
         (new-names (map (lambda (v) (gensym))
                         variables ))
         (newr (renamings-extend r variables new-names)) )
    `(lambda ,(pack variables new-names)
       ,(->Scheme (Function-body e) newr) ) ) )

(define-generic (variable->Scheme (e) r))
◊end{code:lisp}


◊exanswer{macros/ex:study}

В~текущем состоянии {◊Meroonet} действительно существует в~двух мирах
одновременно. Например, функция ◊ic{register-class} вызывается как во~время
раскрытия макросов, так и в~процессе динамической загрузки файлов.


% -- Глава 10 -----------------------

◊exanswer{cc/ex:boost-calls}

Во-первых, доработайте функцию ◊ic{SCM◊_invoke}: возьмите за основу протокол
вызова примитивов и сделайте подобную специализацию для замыканий. Во-вторых,
не~забудьте передать замыкание самому себе в~качестве первого аргумента.
В-третьих, специализируйте также кодогенераторы для замыканий, чтобы сигнатуры
соответствующих функций совпадали с~тем, чего ожидает ◊ic{SCM◊_invoke}.


◊exanswer{cc/ex:global-check}

Добавьте глобальным переменным флажок, показывающий их инициализированность.
Его начальное значение устанавливается в~функции
◊ic{objectify-free-global-reference}.

◊begin{code:lisp}
(define-class Global-Variable Variable (initialized?))
|◊ForLayout{display}{◊vskip-0.333◊baselineskip}|
(define (objectify-free-global-reference name r)
  (let ((v (make-Global-Variable name #f)))
    (insert-global! v r)
    (make-Global-Reference v) ) )
◊end{code:lisp}

Затем встройте анализ глобальных переменных в~компилятор. Он будет выполняться
обходчиком кода с~помощью обобщённой функции ◊ic{inian!}.

◊indexC{inian"!}
◊begin{code:lisp}
(define (compile->C e out)
  (set! g.current '())
  (let ((prg (extract-things!
              (lift! (initialization-analyze! (Sexp->object e))) )))
    (gather-temporaries! (closurize-main! prg))
    (generate-C-program out e prg) ) )
|◊ForLayout{display}{◊vskip-0.333◊baselineskip}|
(define (initialization-analyze! e)
  (call/cc (lambda (exit)
             (inian! e (lambda () (exit 'finished))) )) )
|◊ForLayout{display}{◊vskip-0.333◊baselineskip}|
(define-generic (inian! (e) exit)
  (update-walk! inian! e exit) )
◊end{code:lisp}

Задачей этой функции будет выявить все глобальные переменные, которые
гарантированно получили значение до того, как это значение кому-то
потребовалось. Сложность выполнения данного анализа зависит от желаемого уровня
общности. Мы выберем простой путь и определим все глобальные переменные, которые
всегда инициализируются.

◊begin{code:lisp}
(define-method (inian! (e Global-Assignment) exit)
  (call-next-method)
  (let ((gv (Global-Assignment-variable e)))
    (set-Global-Variable-initialized! gv #t)
    (inian-warning "Surely initialized variable" gv)
    e ) )
|◊ForLayout{display}{◊vskip-◊baselineskip}|
(define-method (inian! (e Global-Reference) exit)
  (let ((gv (Global-Reference-variable e)))
    (cond ((Predefined-Variable? gv) e)
          ((Global-Variable-initialized? gv) e)
          (else (inian-error "Surely uninitialized variable" gv)
                (exit) ) ) ) )
|◊ForLayout{display}{◊vskip-0.333◊baselineskip}|
(define-method (inian! (e Alternative) exit)
  (inian! (Alternative-condition e) exit)
  (exit) )
|◊ForLayout{display}{◊vskip-0.333◊baselineskip}|
(define-method (inian! (e Application) exit)
  (call-next-method)
  (exit) )
|◊ForLayout{display}{◊vskip-0.333◊baselineskip}|
(define-method (inian! (e Function) exit) e)
◊end{code:lisp}

Анализатор проходит по коду, находит все присваивания глобальным переменным и
останавливается, когда программа становится слишком сложной; то~есть когда он
встречает ветвление или вызов функции. Кстати, ◊ic{lambda}-формы не~являются
«слишком сложным кодом», так как они всегда безошибочно вычисляются за
конечное время и не~трогают глобальные переменные.


% -- Глава 11 -----------------------

◊exanswer{objects/ex:precise-predicate}

◊indexC{Object"?}
Предикат ◊ic{Object?} можно улучшить, добавив в~векторы, которыми представляются
объекты, ещё одно поле, хранящее уникальную метку. Соответственно, также
потребуется изменить аллокаторы, чтобы они заполняли это поле во~всех
создаваемых объектах. (И~не~забыть добавить его в~примитивные классы, которые
определяются вручную.)

◊begin{code:lisp}
(define *starting-offset* 2)
(define meroonet-tag (cons 'meroonet 'tag))
|◊ForLayout{display}{◊vskip-0.333◊baselineskip}|
(define (Object? o)
  (and (vector? o)
       (>= (vector-length o) *starting-offset*)
       (eq? (vector-ref o 1) meroonet-tag) ) )
◊end{code:lisp}

При таком подходе предикат ◊ic{Object?} будет реже ошибаться, но ценой этого
является некоторая потеря быстродействия. Однако, его всё равно можно обмануть,
ведь не~мешает пользователю извлечь метку из любого объекта с~помощью
◊ic{vector-ref} и вставить её в~какой-нибудь другой вектор.


◊exanswer{objects/ex:clone}

◊indexC{clone}
Так как это обобщённая функция, то её можно специализировать для конкретных
классов. Универсальная реализация слишком уж неэффективно расходует память:

◊begin{code:lisp}
(define-generic (clone (o))
  (list->vector (vector->list o)) )
◊end{code:lisp}


◊exanswer{objects/ex:metaclass}

Определите новый класс классов: метакласс ◊ic{CountingClass}, у~которого есть
поле для подсчёта создаваемых объектов.

◊begin{code:lisp}
(define-class CountingClass Class (counter))
◊end{code:lisp}

К~счастью, {◊Meroonet} написана так, что для её расширения не~требуется изменять
половину существующих определений. Новый метакласс можно определить как-то так:

◊begin{code:lisp}
(define-meroonet-macro (define-CountingClass name super-name
                                             own-fields )
  (let ((class (register-CountingClass name super-name own-fields)))
    (generate-related-names class) ) )

(define (register-CountingClass name super-name own-fields)
  (CountingClass-initialize! (allocate-CountingClass)
                             name
                             (->Class super-name)
                             own-fields ) )
◊end{code:lisp}

Однако более правильным решением будет расширить синтаксис формы
◊ic{define-class} так, чтобы она принимала тип создаваемого класса (по~умолчанию
◊ic{Class}). При этом потребуется сделать некоторые функции обобщёнными:

◊begin{code:lisp}
(define-generic (generate-related-names (class)))

(define-method (generate-related-names (class Class))
  (Class-generate-related-names class) )

(define-generic (initialize! (o) . args))

(define-method (initialize! (o Class) . args)
  (apply Class-initialize o args) )

(define-method (initialize! (o CountingClass) . args)
  (set-CountingClass-counter! class 0)
  (call-next-method) )
◊end{code:lisp}

Обновлять значение поля ◊ic{counter} будут, конечно~же, аллокаторы нового
метакласса:

◊begin{code:lisp}
(define-method (generate-related-names (class CountingClass))
  (let* ((cname      (symbol-concatenate (Class-name class) '-class))
         (alloc-name (symbol-concatenate 'allocate- (Class-name class)))
         (make-name  (symbol-concatenate 'make- (Class-name class))) )
    `(begin ,(call-next-method)
            (set! ,alloc-name                 ; аллокатор
                  (let ((old ,alloc-name))
                    (lambda sizes
                      (set-CountingClass-counter! ,cname
                       (+ 1 (CountingClass-counter ,cname)) )
                      (apply old sizes) ) ) )
            (set! ,make-name                  ; конструктор
                  (let ((old ,make-name))
                    (lambda args
                      (set-CountingClass-counter! ,cname
                       (+ 1 (CountingClass-counter ,cname)) )
                      (apply old args) ) ) ) ) ) )
◊end{code:lisp}

В~качестве заключения рассмотрим пример использования данного метакласса:

◊begin{code:lisp}
(define-CountingClass CountedPoint Object (x y))

(unless (and (= 0 (CountingClass-counter CountedPoint-class))
             (allocate-CountedPoint)
             (= 1 (CountingClass-counter CountedPoint-class))
             (make-CountedPoint 11 22)
             (= 2 (CountingClass-counter CountedPoint-class)) )
  ;; не~выполнится, если всё в~порядке
  (meroonet-error "Failed test on CountedPoint") )
◊end{code:lisp}


◊exanswer{objects/ex:field-reflection}

Определите метакласс ◊ic{ReflectiveClass}, обладающий дополнительными полями:
◊ic{predicate}, ◊ic{allocator} и~◊ic{maker}. Затем измените определение
генератора сопутствующих функций, чтобы он заполнял эти поля при создании
экземпляра класса. Аналогичные действия необходимо выполнить для классов полей
(наследников ◊ic{Field}).

◊begin{code:lisp}
(define-class ReflectiveClass Class (predicate allocator maker))

(define-method (generate-related-names (class ReflectiveClass))
  (let ((cname      (symbol-concatenate (Class-name class) '-class))
        (pred-name  (symbol-concatenate (Class-name) '?))
        (alloc-name (symbol-concatenate 'allocate- (Class-name class)))
        (make-name  (symbol-concatenate 'make- (Class-name class))) )
    `(begin ,(call-next-method)
            (set-ReflectiveClass-predicate! ,cname ,pred-name)
            (set-ReflectiveClass-allocator! ,cname ,alloc-name)
            (set-ReflectiveClass-maker!     ,cname ,make-name) ) ) )
◊end{code:lisp}


◊exanswer{objects/ex:auto-generic}

Главная сложность здесь в~том, как узнать, существует~ли уже обобщённая
функция или нет. В~Scheme нельзя определить, существует или нет глобальная
переменная, поэтому придётся искать имя функции в~списке ◊ic{*generics*}.

◊begin{code:lisp}
(define-meroonet-macro (define-method call . body)
  (parse-variable-specifications
   (cdr call)
   (lambda (discriminant variables)
     (let ((g (gensym)) (c (gensym)))
       `(begin
          [(unless (->Generic ',(car call))]
            [(define-generic ,call) )]
          (register-method
           ',(car call)
           (lambda (,g ,c)
             (lambda ,(flat-variables variables)
               (define (call-next-method)
                 ((if (Class-superclass ,c)
                      (vector-ref (Generic-dispatch-table ,g)
                                  (Class-number (Class-superclass ,c)) )
                      (Generic-default ,g) )
                  . ,(flat-variables variables) ) )
               . ,body ) )
           ',(cadr discriminant)
           ',(cdr call) ) ) ) ) ) )
◊end{code:lisp}


◊exanswer{objects/ex:next-method}

Просто добавьте в~определение каждого метода пару локальных функций
◊ic{call-next-method} и ◊ic{next-method?}. Несомненно, было~бы лучше сделать
так, чтобы эти функции создавались только тогда, когда они действительно
используются, но это реализовать сложнее.

◊begin{code:lisp}
(define-meroonet-macro (define-method call . body)
  (parse-variable-specifications
   (cdr call)
   (lambda (discriminant variables)
     (let ((g (gensym)) (c (gensym)))
       `(register-method
         ',(car call)
         (lambda (,g ,c)
           (lambda ,(flat-variables variables)
             [,@(generate-next-method-functions g c variables)]
             . ,body ) )
         ',(cadr discriminant)
         ',(cdr call) ) ) ) ) )
◊end{code:lisp}

Функция ◊ic{next-method?} похожа на ◊ic{call-next-method}, но она только ищет
суперметод, не~вызывая его.

◊begin{code:lisp}
(define (generate-next-method-functions g c variables)
  (let ((get-next-method (gensym)))
    `((define (,get-next-method)
        (if (Class-superclass ,c)
            (vector-ref (Generic-dispatch-table ,g)
                        (Class-number (Class-superclass ,c)) )
            (Generic-default ,g) ) )
      (define (call-next-method)
        ((,get-next-method) . ,(flat-variables variables)) )
      (define (next-method?)
        (not (eq? (,get-next-method) (Generic-default ,g))) ) ) ) )
◊end{code:lisp}
