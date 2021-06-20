#lang pollen

◊subsection[#:label "lisp1-2-omega/namespaces/ssect:conclusions"]{В~заключение о~пространствах~имён}

После отступления к~динамическим переменным, вернёмся к~идее пространств имён в~общем:
специализированные окружения для специализированных объектов.
Мы уже видели ◊Lisp-3 в~деле,
а~также разобрали механизм динамических переменных в~◊|CommonLisp|.

◊indexE{Lisp-n@◊Lisp{◊${n}}}
◊indexR{Лисп!Lisp-n@◊Lisp{◊${n}}}
Тем не~менее, наша последняя реализация — с~двумя функциями вместо трёх специальных форм — поднимает каверзный вопрос.
Если это ◊Lisp{◊${n}}, то чему равно~◊${n}?
Интерпретатор очень похож на Scheme, но явно имеет два окружения: ◊ic{env} и~◊ic{denv}.
В~то~же время, все значения вычисляются одинаковым образом, что является отличительной чертой Scheme и класса~◊|Lisp-1|.
С~другой стороны, нам пришлось довольно сильно модифицировать интерпретатор (просто сравните ◊ic{evaluate} и ◊ic{dd.evaluate}),
чтобы реализовать функции ◊ic{bind/de} и~◊ic{assoc/de}.
Наконец, мы столкнулись с~примитивными функциями,
которые не~могут быть реализованы пользователями языка самостоятельно.
Более того, само существование этих функций глубоко влияет на семантику языка и его реализацию.
В~следующей главе мы рассмотрим функцию~◊ic{call/cc}, которая приводит к~аналогичной ситуации.

◊indexR{списки свойств}
◊indexR{символы!списки свойств}
Короче говоря, похоже, что у~нас получился ◊Lisp-1, если смотреть на количество вычислителей,
и~◊Lisp-2 — если смотреть на пространства имён.
Некоторые исследователи придерживаются более общего мнения,
что наличие списка свойств у~символов является характерной чертой ◊Lisp{◊${n}}, где~◊${n} — произвольное число.
◊seeEx{lisp1-2-omega/ex:write-put/get-prop}
Так как наши пространства имён объективно существуют,
а~значения соответствующих переменных вычисляются особым образом
(пусть и с~помощью примитивных функций, а~не~специальных форм),
то~будем считать нашу реализацию представителем класса~◊|Lisp-2|.

◊(bigskip)

◊indexC{csetq}
◊indexR{константы}
Остаётся ещё один урок, который можно извлечь из рассмотрения лексических и динамических переменных.
◊CommonLisp старается унифицировать доступ к~переменным из различных пространств имён,
не~делая между ними синтаксических различий.
Однако семантика переменных, очевидно, различная, поэтому необходимо знать правила языка,
по~которым определяется, из~какого пространства имён взять переменную.
К~сожалению, они не~всегда однозначны;
например, ◊CommonLisp не~различает глобальное динамическое и глобальное лексическое окружения.
Далее, в~◊LISP-1.5 существовала концепция констант,
определяемых специальной формой~◊ic{csetq} (◊english{constant}~◊ic{setq}).

◊envtable{
  ◊tr{◊td{Ссылка}      ◊td{◊ii{x}}                        }
  ◊tr{◊td{Значение}    ◊td{◊ii{x}}                        }
  ◊tr{◊td{Изменение}   ◊td{◊ic{(csetq ◊ii{x} ◊ii{форма})}}}
  ◊tr{◊td{Расширение}  ◊td{запрещено}                     }
  ◊tr{◊td{Определение} ◊td{◊ic{(csetq ◊ii{x} ◊ii{форма})}}}
}

Константы тоже делают синтаксис неоднозначным.
Когда мы пишем ◊ic{foo} — это может означать как константу, так и переменную.
Правило разрешения неоднозначностей в~◊LISP-1.5 таково:
если существует константа с~именем ◊ic{foo}, то~вернуть её значение;
иначе искать одноимённую переменную в~лексическом пространстве имён.
Но:~«константы» можно изменять (представьте себе!) с~помощью той~же формы ◊ic{csetq},
что используется для их создания.
Таким образом, константы ◊LISP-1.5 соответствуют глобальным переменным Scheme,
только с~обратным приоритетом:
в~Scheme локальные лексические переменные скрывают одноимённые глобальные.

Эта проблема имеет довольно общий характер.
Если для доступа к~нескольким пространствам имён используется одинаковый синтаксис,
то необходимо чётко определить правила разрешения неоднозначностей.
