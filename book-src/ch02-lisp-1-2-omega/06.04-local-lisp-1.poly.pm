#lang pollen

◊subsection[#:label "lisp1-2-omega/recusion/ssect:local-lisp1"]{Локальная~рекурсия в~◊Lisp-1}

◊indexR{рекурсия!локальная}
Проблема определения локальных рекурсивных функций существует и в~◊|Lisp-1|;
решается она похожим способом.
Форма~◊ic{letrec} (рекурсивная~◊ic{let}) очень похожа по~смыслу на~◊ic{labels}.

◊indexC{let}
В~Scheme форма ◊ic{let} имеет следующий синтаксис:

◊; TODO: унифицировать написание многоточий в списках (многоточие сразу под скобкой или с отступом в 1 пробел)
◊code:lisp{
(let ((◊ii{переменная◊sub{1}} ◊ii{выражение◊sub{1}})
      (◊ii{переменная◊sub{2}} ◊ii{выражение◊sub{2}})
       ...
      (◊ii{переменная◊sub{n}} ◊ii{выражение◊sub{n}}) )
  ◊ii{выражения}... )
}

◊noindent
И~она эквивалентна следующему выражению:

◊code:lisp{
((lambda (◊ii{переменная◊sub{1}} ◊ii{переменная◊sub{2}} ... ◊ii{переменная◊sub{n}}) ◊ii{выражения}...)
 ◊ii{выражение◊sub{1}} ◊ii{выражение◊sub{2}} ... ◊ii{выражение◊sub{n}} )
}

Поясним, что здесь происходит.
Сперва вычисляются все аргументы аппликации: ◊ii{выражение◊sub{1}}~◊(dots) ◊ii{выражение◊sub{n}};
затем переменные ◊ii{переменная◊sub{1}}~◊(dots) ◊ii{переменная◊sub{n}} связываются с~только что полученными значениями;
наконец, ◊ii{выражения}, составляющие тело~◊ic{let}, вычисляются в~расширенном окружении внутри неявной формы~◊ic{begin},
а~последнее вычисленное значение становится значением всей формы~◊ic{let}.

Как видим, в~принципе нет необходимости делать ◊ic{let} специальной формой,
так как её полностью заменяет ◊ic{lambda};
следовательно, ◊ic{let} может быть всего лишь макросом.
(Собственно, в~Scheme так и есть: ◊ic{let} — это примитивный макрос.)
Тем~не~менее, форма ◊ic{let} полезна с~точки зрения стиля кодирования,
потому как позволяет писать переменные и значения рядом, подобно блокам в~Алголе.
Теперь самое время заметить, что начальные значения локальных переменных формы ◊ic{let} вычисляются в~текущем окружении;
в~расширенном окружении вычисляется только её~тело.

◊indexC{letrec}
По тем~же причинам, с~которыми мы столкнулись в~◊Lisp-2,
это значительно усложняет написание взаимно рекурсивных функций.
На~помощь приходит форма ◊ic{letrec}, аналог~◊ic{labels}.

Синтаксис~◊ic{letrec} аналогичен~◊ic{let}:

◊code:lisp{
(letrec ((even? (lambda (n) (if (= n 0) #t (odd? (- n 1)))))
         (odd? (lambda (n) (if (= n 0) #f (even? (- n 1))))) )
  (even? 4) )
}

◊indexC{letrec!как макрос}
Отличается ◊ic{letrec} от ◊ic{let} тем, что
выражения-инициализаторы вычисляются в~том~же окружении, что и тело~◊ic{letrec}.
Форма~◊ic{letrec} выполняет те~же действия, что и ◊ic{let}, но в~несколько ином порядке.
Сначала локальное окружение ◊ic{letrec} расширяется переменными.
Затем в~этом расширенном окружении вычисляются начальные значения переменных.
Наконец, в~том~же расширенном окружении вычисляется тело~◊ic{letrec}.
По~этому описанию довольно легко понять, как реализовать такое поведение.
Действительно, достаточно написать следующее:

◊indexC{even?}
◊indexC{odd?}
◊indexC{void@'void}
◊code:lisp{
(let ((even? 'void) (odd? 'void))
  (set! even? (lambda (n) (if (= n 0) #t (odd? (- n 1)))))
  (set! odd? (lambda (n) (if (= n 0) #f (even? (- n 1)))))
  (even? 4) )
}

Сперва создаются привязки для ◊ic{even?} и~◊ic{odd?}.
(Их начальные значения не~важны, просто ◊ic{let} и ◊ic{lambda} требуют указать какое-то значение.)
Затем эти переменные инициализируются значениями, вычисленными в~окружении, где известны переменные ◊ic{even?} и~◊ic{odd?}.
Мы говорим «известны» потому, что хотя для этих переменных и созданы привязки,
их значения не~имеют смысла, так как они ещё не~были корректно инициализированы.
Про ◊ic{even?} и ◊ic{odd?} известно достаточно, чтобы ссылаться на них,
но~пока ещё не~достаточно, чтобы они участвовали в~вычислениях.

◊indexR{порядок вычислений!неопределённый}
Однако, такое преобразование не~вполне корректно из-за порядка вычислений:
действительно, ◊ic{let} раскрывается в~применение функции;
следовательно, ◊ic{letrec}, по~идее, должна вести себя так~же;
а~это значит, что начальные значения переменных должны вычисляться как аргументы функции —
то~есть в~неопределённом порядке.
К~сожалению, текущая реализация всегда вычисляет их слева направо.
◊seeEx{lisp1-2-omega/ex:orderless-letrec}
