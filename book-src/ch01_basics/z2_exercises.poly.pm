#lang pollen

◊section*[#:label "basics/sect:exercises"]{Упражнения}


◊exercise{basics/ex:tracer}

◊indexR{трассировка}
Превратите функцию ◊ic{evaluate} в~трассировщик вычислений.
Все вызовы функций должны выводить на экран фактические аргументы и возвращаемый результат.
Легко представить себе дальнейшее развитие этого инструмента в~пошаговый отладчик,
позволяющий вдобавок изменять ход исполнения отлаживаемой программы.


◊exercise{basics/ex:excess-recursion}

Если функции~◊ic{evlis} передать список из одного выражения, она делает лишний рекурсивный вызов.
Придумайте способ избавиться от~него.


◊exercise{basics/ex:new-extend}

Предположим, новая функция~◊ic{extend} определена~так:

◊indexC{extend}
◊code:lisp{
(define (extend env names values)
  (cons (cons names values) env) )
}

Определите соответствующие функции ◊ic{lookup} и~◊ic{update!}.
Сравните их с~рассмотренными ранее вариантами.


◊exercise{basics/ex:racks}

◊indexR{ближнее связывание}
◊indexR{связывание!ближнее}
◊indexE{rack}
В~работе~◊cite{ss80} рассматривается механизм ближнего связывания, названный~◊english{◊term{rack}}.
Символ связывается со~стеком значений, а~не~единственным значением.
В~каждый момент времени значением переменной является находящаяся на вершине стека величина.
Перепишите функции ◊ic{s.make-function}, ◊ic{s.lookup}, ◊ic{s.update!} для реализации этой~идеи.


◊exercise{basics/ex:liar-liar!}

◊indexR{представление!логических значений}
Если вы ещё не~заметили, то в~определение примитивной функции ◊ic{<} вкралась ошибка!
Ведь эта функция должна возвращать логические значения определяемого языка,
а~не~языка реализации.
Исправьте это досадное недоразумение.


◊exercise{basics/ex:def-list}

Определите функцию~◊ic{list}.


◊exercise{basics/ex:def-call/cc}

Для обожающих продолжения: определите~◊ic{call/cc}.


◊exercise{basics/ex:def-apply}

Определите функцию~◊ic{apply}.


◊exercise{basics/ex:def-end}

Определите функцию~◊ic{end}, позволяющую выйти из интерпретатора, разработанного в~этой главе.


◊exercise{basics/ex:slowpoke}

◊indexR{уровни интерпретации}
◊indexR{интерпретация!уровневая}
Сравните скорость Scheme и~◊ic{evaluate}.
Затем сравните скорость ◊ic{evaluate} и~◊ic{evaluate}, интерпретируемой с~помощью ◊ic{evaluate}.


◊exercise{basics/ex:no-gensym}

Ранее мы определили ◊ic{begin} через~◊ic{lambda},
◊seePage{basics/forms/sequence/par:gensym-puzzle}
но для этого нам потребовалось использовать функцию ◊ic{gensym},
чтобы избежать коллизий имён переменных.
Переопределите ◊ic{begin} в~таком~же духе, но без использования ◊ic{gensym}.
