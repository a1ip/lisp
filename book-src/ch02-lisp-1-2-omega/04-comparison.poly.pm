#lang pollen

◊section[#:label "lisp1-2-omega/sect:comparison" #:alt "Сравнение Lisp-1 и Lisp-2"]{Сравнение ◊|Lisp-1|~и~◊|Lisp-2|}

Завершая наше небольшое исследование ◊Lisp-1 и~◊Lisp-2,
что~же мы выяснили в~итоге об~этих двух подходах?

◊indexR{пространства имён}
◊indexE{Lisp-n@◊Lisp{◊ii{n}}}
◊indexR{Лисп!Lisp-n@◊Lisp{◊ii{n}}}
Scheme — это типичный ◊|Lisp-1|, на нём приятно программировать и ему легко обучать, так как процесс вычислений прост и последователен.
По~сравнению со~Scheme, ◊|Lisp-2| более сложен: существование двух миров требует использования особых форм для перехода между ними.
◊CommonLisp — это даже не~◊Lisp-2, так как в~языке есть множество других пространств имён:
для меток лексических переходов, для меток форм ◊ic{tagbody}, и~т.~д.
Порой ◊CommonLisp называют~◊Lisp{◊${n}},
где одно и то~же имя может вести себя различным образом в~зависимости от синтаксической роли.
Языки со~строгим синтаксисом (или, как говорят, с~деспотичным синтаксисом)
часто имеют множество пространств имён или множество окружений: для переменных, для функций, для типов, и~т.~д.
Каждое из этих окружений имеет свои особенности.
Например, локальное функциональное окружение часто неизменяемо — то~есть функциям нельзя присваивать новые значения, —
что облегчает оптимизацию вызовов локальных функций.

В~программах на~◊Lisp-2 функции чётко отделены от остальных вычислений.
Это очень выгодное разграничение и по~мнению ◊cite{sen89}, все хорошие компиляторы им пользуются,
используя ◊Lisp-2 в~качестве внутреннего представления программ.
Компилятор чётко определяет каждое место, куда необходимо вставить ◊ic{funcall} — те места, где функции вычисляются динамически.
Пользователи ◊Lisp-2 вынуждены делать часть работы компилятора вручную,
поэтому в~итоге они лучше понимают истинную стоимость подобной выразительности.

◊indexE{Lisp-2@◊Lisp-2}
◊indexR{Лисп!Lisp-2@◊Lisp-2}
Мы разобрали довольно много вариаций языков,
так что сейчас будет полезным собрать всё воедино и дать определение — простейшее из возможных —
ещё одного ◊|Lisp-2|-языка, похожего на ◊|CommonLisp|.
В~этот раз мы ограничимся только введением функции ◊ic{f.lookup},
которая ищет функцию по имени в~функциональном окружении, а~если не~находит, то возвращает ◊ic{wrong}.
Такой подход гарантирует, что вызов ◊ic{f.lookup} всегда завершается за конечное время.
Конечно, иным следствием такого похода будет появление своеобразных ошибок замедленного действия,
так как обращение к~неопределённой функции обрабатывается не~при интерпретации программы,
а~при попытке вызова функции, что может произойти гораздо позже, а~то и~вовсе никогда.

◊indexC{f.evaluate}
◊indexC{f.evaluate-application}
◊indexC{f.lookup}
◊code:lisp{
(define (f.evaluate e env fenv)
  (if (atom? e)
      (cond ((symbol? e) (lookup e env))
            ((or (number? e) (string? e) (char? e)
                 (boolean? e) (vector? e) )
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
        ((function)
         (cond ((symbol? (cadr e))
                (f.lookup (cadr e) fenv) )
               ((and (pair? (cadr e)) (eq? (car (cadr e)) 'lambda))
                (f.make-function
                 (cadr (cadr e)) (cddr (cadr e)) env fenv ) )
               (else (wrong "Incorrect function" (cadr e))) ) )
        ((flet)
         (f.progn (cddr e)
                  env
                  (extend fenv (map car (cadr e))
                          (map (lambda (def)
                                 (f.make-function (cadr def)
                                                  (cddr def)
                                                  env fenv ) )
                               (cadr e) ) ) ) )
        ((labels)
         (let ((new-fenv (extend fenv
                                 (map car (cadr e))
                                 (map (lambda (def) 'void)
                                      (cadr e) ) )))
           (for-each (lambda (def)
                       (update! (car def)
                                new-fenv
                                (f.make-function (cadr def) (cddr def)
                                                 env new-fenv ) ) )
                     (cadr e) )
           (f.eprogn (cddr e) env new-fenv) ) )
        (else (f.evaluate-application (car e)
                                      (f.evlis (cdr e) env fenv)
                                      env
                                      fenv )) ) ) )

(define (f.evaluate-application fn args env fenv)
  (cond ((symbol? fn)
         ((f.lookup fn fenv) args) )
        ((and (pair? fn) (eq? (car fn) 'lambda))
         (f.eprogn (cddr fn)
                   (extend env (cadr fn) args)
                   fenv ) )
        (else (wrong "Incorrect functional term" fn)) ) )

(define (f.lookup id fenv)
  (if (pair? fenv)
      (if (eq? (caar fenv) id)
          (cdar fenv)
          (f.lookup id (cdr fenv)) )
      (lambda (values)
        (wrong "No such functional binding" id) ) ) )
}

Другое важное, по мнению ◊cite{gp88}, практическое различие между ◊Lisp-1 и ◊Lisp-2 состоит в~читабельности.
Хотя, конечно~же, опытные программисты вряд~ли будут писать что-то вроде:

◊code:lisp{
(defun foo (list)
  (list list) )
}

◊indexR{самоприменение!в Lisp-1 и Lisp-2@в~◊Lisp-1 и~◊Lisp-2}
С~точки зрения ◊Lisp-1, ◊ic{(list~list)} — это вполне~допустимое самоприменение,
◊footnote{
  Существуют и другие самоприменения, которые имеют смысл, хотя их и не~особо много.
  Например, ◊ic{(number?~number?)}.
}
но в~◊Lisp-2 это выражение имеет совершенно иной смысл.
В~◊CommonLisp два имени ◊ic{list} принадлежат различным окружениям и не~конфликтуют.
Тем не~менее, лучше избегать подобного стиля и не~называть локальные переменные именами часто используемых глобальных функций;
это поможет избежать проблем с~макросами и сделает программы менее зависимыми от используемого диалекта.

◊indexR{макросы!в Lisp-1 и Lisp-2@в~◊Lisp-1 и~◊Lisp-2}
Следующее различие между ◊Lisp-1 и ◊Lisp-2 заключается в~собственно макросах.
В~◊CommonLisp довольно непросто написать макрос, раскрывающийся в~◊ic{lambda}-форму,
что было~бы полезно, например, при реализации объектной системы.
Дело в~том, что ◊CommonLisp ограничивает места, где может использоваться ◊ic{lambda}.
Эта форма может находиться только на месте функции,
так что конструкция ◊ic{(...~(lambda~...)~...)} считается ошибкой в~◊|CommonLisp|.
Единственное исключение — ◊ic{lambda} может быть первым аргументом ◊ic{function}.
Но~сама ◊ic{function} может быть только параметром функции, так что ◊ic{((function (lambda~...))~...)} — это снова ошибка.
Если макрос не~знает, где именно он раскрывается — как аргумент или как функция, —
то~его нельзя использовать без некоторого усложнения программ.
Для той~же системы объектов, например, придётся раскрывать макрос в~◊ic{(function (lambda~...))},
а~потом добавлять~◊ic{funcall} везде, где этот макрос вызывается как функция.

◊indexR{конфликт имён}
◊indexR{область видимости!конфликт имён}
Наконец, стоит упомянуть ещё одно радикальное решение, используемое многими языками:
запретить использование одного и того~же имени даже в~различных окружениях.
Предыдущий пример с~переменной~◊ic{list} тогда вызвал~бы ошибку,
так как имя~◊ic{list} уже используется в~функциональном окружении.
Например, практически все реализации Лиспа и Scheme запрещают функциям и макросам иметь совпадающие имена.
Такое правило порой действительно облегчает жизнь.
