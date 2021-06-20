#lang pollen

◊section[#:label "lisp1-2-omega/sect:lisp2" #:alt "Lisp-2"]{◊Lisp-2}

◊indexE{Lisp-2@◊Lisp-2}
◊indexR{Лисп!Lisp-2@◊Lisp-2}
В~большинстве программ на Лиспе — включая и~наш интерпретатор из предыдущей главы —
при вызовах функций первым элементом формы является имя глобальной переменной.
Мы могли~бы сделать это ограничение частью синтаксиса.
Это~бы не~сильно изменило внешний вид кода, но облегчило~бы вычисление форм:
для первого элемента уже не~нужна вся мощь ◊ic{evaluate},
достаточно мини-вычислителя, который~бы умел только искать нужную функцию по~имени.
Для реализации этой идеи изменим соответствующую часть ◊ic{evaluate}:

◊code:lisp{
...
(else (invoke (lookup (car e) env)
              (evlis (cdr e) env) )) ...
}

◊indexC{fenv}
◊indexR{окружение!функциональное}
Фактически, теперь у~нас два разных интерпретатора:
для выражений на месте функции и для аргументов функций.
Один и тот~же идентификатор теперь обрабатывается по-разному, в~зависимости от его положения.
Если функции требуют особого подхода, то логичным будет также выделить для них отдельное пространство имён.
Очевидно, что легче искать имена функций в~окружении, где нет имён переменных, которые только мешают.
Интерпретатор легко адаптировать для этого случая.
Нам понадобится окружение для функций ◊ic{fenv} и специализированный вычислитель ◊ic{evaluate-application},
который знает, как обращаться с~элементами данного окружения.
Так как теперь у~нас два окружения и два вычислителя, то мы назовём это ◊|Lisp-2|~◊cite{sg93}.

◊indexC{f.evaluate}
◊code:lisp{
(define (f.evaluate e env fenv)
  (if (atom? e)
      (cond ((symbol? e) (lookup e env))
            ((or (number? e)(string? e)(char? e)
                 (boolean? e)(vector? e) )
             e )
            (else (wrong "Cannot evaluate" e)) )
      (case (car e)
        ((quote)  (cadr e))
        ((if)     (if (f.evaluate (cadr e) env fenv)
                      (f.evaluate (caddr e) env fenv)
                      (f.evaluate (cadddr e) env fenv) ))
        ((begin)  (f.eprogn (cdr e) env fenv))
        ((set!)   (update! (cadr e)
                           env
                           (f.evaluate (caddr e) env fenv) ))
        ((lambda) (f.make-function (cadr e) (cddr e) env fenv))
        (else     (evaluate-application (car e)
                                        (f.evlis (cdr e) env fenv)
                                        env
                                        fenv )) ) ) )
}

За~вычисление форм отвечает ◊ic{evaluate-application},
которая принимает «сырое» имя функции, вычисленные значения аргументов и два текущих окружения.
Как видно из определения ◊ic{lambda}, при создании функции замыкаются оба окружения: ◊ic{env} и~◊ic{fenv}.
В~остальном новая версия отличается только тем, что за~◊ic{env} подобно тени следует~◊ic{fenv}. 
Естественно, также необходимо доработать функции ◊ic{evlis} и ◊ic{eprogn}, чтобы они использовали ◊ic{fenv}:

◊indexC{f.evlis}
◊indexC{f.eprogn}
◊code:lisp{
(define (f.evlis exps env fenv)
  (if (pair? exps)
      (cons (f.evaluate (car exps) env fenv)
            (f.evlis (cdr exps) env fenv) )
      '() ) )

(define (f.eprogn exps env fenv)
  (if (pair? exps)
    (if (pair? (cdr exps))
        (begin (f.evaluate (car exps) env fenv)
               (f.eprogn (cdr exps) env fenv) )
        (f.evaluate (car exps) env fenv) )
    empty-begin ) )
}

При вызове функции её аргументы расширяют окружение переменных,
для этого необходимо доработать только способ создания функции;
механизм вызова (◊ic{invoke}) особых изменений не~требует.

◊indexC{f.make-function}
◊code:lisp{
(define (f.make-function variables body env fenv)
  (lambda (values)
    (f.eprogn body (extend env variables values) fenv) ) )
}

Задача ◊ic{evaluate-application} в~том, чтобы проанализировать функциональный элемент формы и обеспечить правильный вызов.
Если мы последуем путём ◊CommonLisp, то на месте функционального элемента может стоять или символ, или ◊ic{lambda}-форма.

◊indexC{evaluate-application}
◊code:lisp[#:label "lisp1-2-omega/lisp2/src:erroneous-eval-application"]{
(define (evaluate-application fn args env fenv)
  (cond ((symbol? fn)
         (invoke (lookup fn fenv) args) )
        ((and (pair? fn) (eq? (car fn) 'lambda))
         (f.eprogn (cddr fn)
                   (extend env (cadr fn) args)
                   fenv ) )
        (else (wrong "Incorrect functional term" fn)) ) )
}

Итак, что~же мы в~итоге получили, а~что потеряли?
Первое очевидное преимущество состоит в~том,
что для поиска функции по имени необходим только простой вызов ◊ic{lookup},
а~не~◊ic{f.evaluate} с~последующим синтаксическим разбором.
Далее, так как мы избавились ото~всех ссылок на переменные в~◊ic{fenv},
это окружение стало компактнее, а~значит и поиск в~нём ускорился.
Второе преимущество состоит в~ускорении вычисления форм, где на месте функции находится ◊ic{lambda}-форма.
Например:

◊code:lisp{
(let ((state-tax 1.186))
  ((lambda (x) (* state-tax x)) (read)) )
}

В~этом случае для ◊ic{(lambda (x) (*~state-tax~x))} не~будет создаваться замыкание,
её тело будет вычислено сразу в~правильном окружении.

Однако, если задуматься, то эти два преимущества по~сути ничего не~дают,
так как тех~же результатов можно добиться и в~◊Lisp-1 с~помощью небольшого предварительного анализа программ.
Есть только один действительно приятный момент:
◊Lisp-2 чуть-чуть быстрее, так как мы можем быть уверены в~том, что любое имя из~◊ic{fenv} связано с~функцией и ни~с~чем иным,
а~значит, проверку на то, что это действительно функция, надо выполнять лишь один раз: при помещении функции в~окружение.
Так как каждое имя должно быть связано с~функцией, то все неиспользуемые имена можно просто связать с~◊ic{wrong}.

Ввиду того, что каждое имя из~◊ic{fenv} связано с~функцией,
мы можем вообще избавиться от вызова ◊ic{invoke}, а~заодно и от вызова ◊ic{procedure?}~внутри.
Правда, это работает только потому что мы реализуем интерпретатор на~Scheme
(в~◊CommonLisp формы вроде ◊ic{((lookup fn fenv) args)} запрещены).
Немного изменим начало ◊ic{evaluate-application}:

◊code:lisp{
(define (evaluate-application fn args env fenv)
  (cond ((symbol? fn) ((lookup fn fenv) args))
        ... ) )
}

В~Лиспе функции вызываются так часто, что любой выигрыш времени при вызовах —
это уже хорошо и может сильно повлиять на производительность.
Но этот конкретный выигрыш не~так уж и велик:
он появляется только для динамически определяемых функций,
тогда как в~большинстве случаев вызываемая функция известна статически.

Теперь поговорим о~том, что~же мы потеряли.
А~потеряли мы возможность ◊emph{вычислить} вызываемую функцию.
Рассмотрим выражение ◊ic{(if~◊ii{условие} (+~3~4) (*~3~4))}.
В~Scheme можно легко вынести аргументы ◊ic{3} и~◊ic{4} за скобки:
◊ic{((if~◊ii{условие} +~*) 3~4)}.
Просто, понятно, логично — считай, алгебраическое тождество.
Но~в~◊Lisp-2 такая программа некорректна,
ведь ◊ic{if}-форма, стоящая на месте функции, — это не~символ и~не~◊ic{lambda}-форма.
