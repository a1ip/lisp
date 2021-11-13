#lang pollen

◊; TODO: что я говорил о написании "λ-исчисления"?
◊section[#:label "denotational/sect:lambda" #:alt "Семантика λ-исчисления"]{Семантика ◊${\lambda}-исчисления}

Как~видим, Scheme по~сути можно определить с~помощью всего лишь нескольких формул,
что является одной из притягательных черт этого языка программирования.
Именно по этой причине функциональные языки часто становятся лингвистическими лабораториями,
где испытываются новые языковые конструкции и изучаются их фундаментальные, обобщённые свойства.
В~зависимости от предмета исследования, порой можно обойтись более простым и~ограниченным лингвистическим базисом,
вроде ◊${\lambda}-исчисления самого по~себе.
Здесь нет никакой тавтологии или шутки,
ведь ◊${\lambda}-исчисление — это тоже язык, а~значит, у~него должна быть некоторая семантика.
Будет полезным рассмотреть денотационную семантику языка, который отличается от~Scheme, но~всё~же является родственным.

Начнём с~синтаксиса.
Для наших целей он не~особо важен, так что ради читабельности будем использовать Scheme-подобный синтаксис:

◊; TODO: \quad? \qquad? x2? последовательно используй
◊$${
  x
  \qquad\qquad
  ◊text{◊ic{(lambda (◊${x}) ◊${M})}}
  \qquad\qquad
  ◊text{◊ic{(◊${M} ◊${N})}}
}

Далее определим домены.
В~◊${\lambda}-исчислении нет присваиваний и продолжений, что серьёзно облегчает задачу.
Более~того, мы ограничимся чистым ◊${\lambda}-исчислением —
то~есть никаких чисел и других типов данных помимо абстракций.
Итак,~домены:

◊; TODO: красота, особенно вокруг знака равенства
◊$${
\begin{array}{rll}
  ◊p & ◊Vset{Программы}  &                                          \\
  ◊n & ◊Vset{Переменные} &                                          \\
  ◊r & ◊Vset{Окружения}  & = ◊Vset{Переменная} \to ◊Vset{Значение}  \\
  ◊e & ◊Venv{Значения}   & = ◊Vset{Функции}                         \\
  ◊f & ◊Venv{Функции}    & = ◊Vset{Значение} \to ◊Vset{Значение}    \\
\end{array}
}

◊indexR{интерпретатор!L@◊${◊Lain}}
◊indexE{L@◊${◊Lain}, интерпретатор}
Функцию-интерпретатор мы назовём~◊${◊Lain}.
Она~сопоставляет каждому ◊${\lambda}-терму его денотацию — другой~◊${\lambda}-терм.
Таким образом, интерпретатор имеет~тип

◊$${
◊Lain \colon \quad ◊Vset{Программа} \to (◊Vset{Окружение} \to ◊Vset{Значение})
}

◊indexR{лямбда-исчисление@◊${\lambda}-исчисление!семантика}
Осталось лишь тщательно определить денотации всех синтаксических форм языка,
поразительное разнообразие которых собрано в~таблице~◊ref{denotational/lambda/fig:self}.

◊; TODO: особый конвертер
◊table:semantic-denotation[#:label "denotational/lambda/fig:self"]{
◊code:denotation{
(define ((L-meaning-reference n) r)
  (r n) )

(define ((L-meaning-abstraction n e) r)
  (lambda (v)
    ((L-meaning e) (extend r n v)) ) )

(define ((L-meaning-combination e1 e2) r)
  (((L-meaning e1) r) ((L-meaning e2) r)) )
}
◊caption{Семантика ◊${\lambda}-исчисления}
}

Приведённая семантика очень точна, вплоть до неопределённости порядка вычислений при аппликации (комбинации) абстракций.
Комбинация переводится в~комбинацию, без указания какого-либо предпочтительного порядка.

Интерпретатор~◊${◊Lain} определяется рекурсивно.
Эта~рекурсия хорошо обоснована благодаря композициональности:
рекурсивные вычисления выполняются для сокращающихся подпрограмм,
которые в~итоге сводятся к~ссылкам на~переменные.

◊; TODO: когда будешь реализовывать ◊seeCite, проследи за тем, как он играет с пунктуацией и пробелами до/после
◊${\lambda}-исчисление представляет особенный случай,
так~как мы и безо~всяких денотаций имеем довольно чёткое представление о~его семантике.
Возможно строго доказать ◊seeCite{sto77},
что~подобное самоопределение сохраняет все необходимые свойства ◊${\lambda}-исчисления вроде~◊${\beta}-редукции.

Денотирование ◊${\lambda}-исчислением хорошо работает для языков без побочных эффектов и продолжений.
Однако если подобные явления в~языке всё~же присутствуют,
то~в~общем случае оказывается необходим определённый порядок вычислений, чтобы корректно описать семантику языка.
Присваивание добавляет сложностей,
вынуждая разделять окружение и память с~помощью механизма
вроде коробок из предыдущей~главы
◊seePage{assignment/assignment/ssect:boxes}
или~же изменяемых~ссылок, как~в~ML.
