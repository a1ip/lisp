#lang pollen

◊subsection[#:label "lisp1-2-omega/recusion/ssect:mutual"]{Взаимная рекурсия}

◊indexR{рекурсия!взаимная}
Теперь предположим, что мы хотим определить взаимно рекурсивные функции.
Возьмём для примера ◊ic{odd?} и ◊ic{even?}, реализующие (весьма неэффективную) проверку натуральных чисел на чётность.
Они определяются следующим образом:

◊indexC{even?}
◊indexC{odd?}
◊; TODO: как лучше это разрулить?
◊; ◊indexE{even?@◊protect◊ic{even?}|seealso{◊protect◊ic{odd?}}}
◊; ◊indexE{odd?@◊protect◊ic{odd?}|seealso{◊protect◊ic{even?}}}
◊code:lisp{
(define (even? n) (if (= n 0) #t (odd?  (- n 1))))
(define (odd? n)  (if (= n 0) #f (even? (- n 1))))
}

Можете переставлять местами эти определения сколько вам угодно,
но в~любом случае первое определение не~будет знать о~втором;
сейчас ◊ic{even?} не~знает на~момент определения про ◊ic{odd?}.

И~опять, кажется, решением будет глобальное окружение, где все переменные существуют заранее.
Оба замыкания захватывают глобальное окружение, в~котором есть все возможные переменные,
среди них, в~частности, и необходимые ◊ic{odd?} и~◊ic{even?}.
Реализация замыканий для неограниченного числа свободных переменных оставляется читателю в~качестве упражнения.

Довольно непросто перенести это поведение в~мир с~гиперстатическим глобальным окружением,
так как здесь уж точно первое определение никогда не~сможет узнать о~втором.
Одно из решений состоит в~том, чтобы определять взаимно рекурсивные функции одновременно,
тогда не~будет никаких первых и вторых, и~обе функции смогут ссылаться друг на друга без проблем.
(Мы вернёмся к~этому вопросу чуть позже, после изучения локальной рекурсии.)
Например, когда-то в~◊LISP-1.5 форма ◊ic{define} умела вот~так:

◊indexC{define!параллельные объявления}
◊code:lisp{
(define ((even? (lambda (n) (if (= n 0) #t (odd? (- n 1)))))
         (odd? (lambda (n) (if (= n 0) #f (even? (- n 1))))) ))
}

Таким образом, с~помощью глобального окружения и некоторых ухищрений можно выразить и взаимную рекурсию.

Но что делать, если нам понадобится определить рекурсивные функции локально?
