#lang pollen

◊subsection[#:label "assignment/side-effects/ssect:equality-func"]{Равенство функций}

◊indexR{сравнение!функций}
◊indexR{функции!сравнение}
◊indexR{функции!тождественность}
Сравнение функций кажется безнадёжным занятием.
Легко догадаться, что функции эквивалентны, если они дают равные результаты для равных аргументов —
очевидно, подобные функции взаимозаменимы.
Более~формально тождественность функций записывается следующим~образом:

◊; TODO: формула должна быть красивой
◊$${f = g \iff \forall x \colon f(x) = g(x)}

◊; TODO: автозамена ... на красивое многоточие ◊(dots), да?
К~сожалению, сравнение функций — в общем случае алгоритмически неразрешимая задача.
Таким образом, мы вынуждены либо отказаться от идеи сравения функций в~принципе,
либо~же принять менее строгое определение эквивалентности,
чтобы ограничиться исключительно разрешимыми случаями.
Сложно сказать, эквивалентны~ли произвольные функции,
однако порой бывает очень легко понять, когда они не~эквивалентны
(например, если функции принимают разное число аргументов).

Имея в~виду вышесказанное, мы~можем определить нестрогий предикат равенства между функциями,
понимая, что порой он даёт неточные, а~то~и~вовсе ошибочные результаты.
Естественно, подобный инструмент будет полезен лишь в~том случае,
когда мы знаем, где именно и какие ошибки он~может допускать.

◊indexC{eqv?!для функций} ◊; TODO: вот это должно правильным образом индексироваться, ты помнишь?
Например, Scheme определяет ◊ic{eqv?} для функций следующим образом:
если для функций ◊ic{f} и~◊ic{g} существуют эквивалентные (в~смысле~◊ic{eqv?}) аргументы,
которые приводят к~различным (в~смысле~◊ic{eqv?}) результатам,
то~данные функции не~эквивалентны.
И~снова вместо равенства определяются различия.

Давайте рассмотрим несколько примеров.
Выражение ◊nobr{◊ic{(eqv? car cdr)}} очевидно возвращет~◊ic{#f},
ведь~поведение этих функций значительно отличается,
особенно для аргументов вроде~◊nobr{◊ic{(a . b)}}.

◊indexR{тождественность!функций}
Также очевидно, что ◊nobr{◊ic{◊ic{(eqv? car car)}}} следует возвращать~◊ic{#t},
ведь отношение эквивалентности обязано быть рефлексивным.
Однако в~некоторых реализациях ◊ic{eqv?} возвращает~◊ic{#f},
потому что там ◊ic{car} является инлайн-функцией и такая форма фактически читается
как~◊ic{(eqv? (lambda~(x)~(car~x)) (lambda~(x)~(car~x)))}.
В~таком случае ◊|R5RS|~оставляет результат ◊ic{eqv?} на~усмотрение реализации.

Но~как~же тогда сравнивать ◊ic{cons} и ◊ic{cons}, не~прибегая к~спасительной рефлексивности?
Функция~◊ic{cons} обязана каждый раз возвращать новую изменяемую точечную пару,
так~что даже если её аргументы эквивалентны, то~в~результате получаются очевидно разные объекты —
ведь~они размещаются в~разных участках памяти.
Получается, ◊ic{cons} не~тождественна ◊ic{cons}, а~◊nobr{◊ic{(eqv? cons cons)}} должна вернуть~◊ic{#f},
потому~что ◊nobr{◊ic{(eqv? (cons 1 2) (cons 1 2))}} возвращает~◊ic{#f}?

◊; TODO: формулы должны быть красивыми (а формулы в сносках должны иметь соответствующий кегль)
◊indexR{частичные функции}
◊indexR{функции!частичные}
Вы~всё ещё уверены, что ◊ic{car} должна быть равна~◊ic{car}?
Например, в~динамически типизированных языках выражение ◊ic{(car~'foo)} вызовет ошибку и выброс исключения,
поэтому фактический результат вызова функции зависит не~только от~аргументов,
но~и от~активных в~данный момент обработчиков исключений.
Далеко не~всегда результаты вычисления функций можно сравнить.
Аналогичные затруднения возникают с~частичными
◊trnote{
  Функция~◊${f \colon X \to Y} называется частичной,
  если она определена лишь на~подмножестве множества~◊${X}.
  Например, операция вычитания для натуральных чисел имеет тип ◊${\mathbb{N} \times \mathbb{N} \to \mathbb{N}},
  однако~она определена не~для всех пар натуральных чисел ◊${(a, b) \in \mathbb{N} \times \mathbb{N}},
  а~лишь для тех, где~◊${a \geq b}.
}
функциями, которые используются вне своей области определения.

◊indexR{замыкания (closures)!сравнение}
Так~что~же делать?
Сколько~языков — столько~и~мнений.
Языки со~статической типизацией позволяют точно определить, когда аргументы сравнения оказываются функциями.
Таким образом, например, некоторые диалекты~ML запрещают сравнивать функции в~принципе —
это~семантически и~синтаксически некорректно.
В~Scheme форма~◊ic{lambda} создаёт замыкания.
Каждый вызов ◊ic{lambda} возвращает замыкание, которое имеет определённый адрес в~памяти,
поэтому функции можно сравнивать хотя~бы по~этому адресу.
Именно так и поступает ◊ic{eqv?}, считая функции с~одинаковым адресом эквивалентными.

Такое определение, однако, мешает некоторым оптимизациям, доступным в~◊${\lambda}-исчислении.
Рассмотрим функцию с~говорящим именем ◊ic{make-named-box},
которая возвращает замыкания, реагирующие на~определённые сообщения.
Фактически, это один из способов реализации объектов —
именно такой подход мы будем использовать для написания интерпретатора в~этой~главе.

◊indexC{make-named-box}
◊code:lisp{
(define (make-named-box name value)
  (lambda (msg)
    (case msg
      ((type) (lambda () 'named-box))
      ((name) (lambda () name))
      ((ref)  (lambda () value))
      ((set!) (lambda (new-value) (set! value new-value))) ) ) )
}

Замечательно, мы~научились привязывать к~коробкам бирку с~именем.
Теперь рассмотрим функцию внимательнее:
все~возвращаемые замыкания замыкают одни~и~те~же привязки,
а~сообщение~◊ic{type} вообще не~зависит от локальных переменных.
Достаточно умная реализация вынесет всё это за~скобки:

◊code:lisp{
(define other-make-named-box
  (let ((type-closure (lambda () 'named-box)))
    (lambda (name value)
      (let ((name-closure  (lambda () name))
            (value-closure (lambda () value))
            (set!-closure  (lambda (new-value)
                             (set! value new-value) )) )
        (lambda (msg)
          (case msg
            ((type) type-closure)
            ((name) name-closure)
            ((ref)  value-closure)
            ((set!) set!-closure) ) ) ) ) ) )
}

◊noindent
Отлично, ◊ic{type-closure} теперь создаётся всего один раз для всех коробок,
а~не~при каждом обращении к~объекту.

Однако что мы получим в~результате следующего сравнения?

◊code:lisp{
(let ((box (make-named-box 'foo 33)))
  (◊ii{равны}? (box 'type) (box 'type)) )
}

Это не~совсем корректный вопрос, ведь здесь не~указан предикат сравнения.
Если это~◊ic{eq?}, то~ответ зависит от количества созданных копий ◊nobr{◊ic{(lambda () 'named-box)}},
если~же используется ◊ic{egal}, то~расположение замыканий не~играет роли и ответом будет~◊ic{#t}.
Таким образом, семантика языка неявно зависит от предоставляемых им предикатов сравнения.

Если ◊ic{lambda} создаёт замыкания в~памяти, то~у~них всегда есть какой-то адрес.
Два~замыкания с~одинаковым адресом, очевидно, являются одним и тем~же замыканием, а~потому эквивалентны.
Соответственно, в~Scheme следующая программа ведёт~себя~верно:

◊; TODO: стрелочки
◊code:lisp{
(let ((f (lambda (x y) (cons x y))))
  (eqv? f f) ) ◊(is) #t
}

◊noindent
Так~как ◊ic{eqv?} передан один и тот~же объект, она вправе вернуть~◊ic{#t} —
несмотря на~то, что ◊ic{(eqv? (f~1~2) (f~1~2))} возвращает~◊ic{#f}.

◊(bigskip)

Как~видим, сравнение функций вызывает множество вопросов, на которые нельзя дать однозначный ответ.
Предпочтения зависят от свойств эквивалентности, которые желательно сохранить в~языке,
так~как проверка математической тождественности функций не~представляется возможной.
Реализации могут предоставлять множество вариантов сравнения с~различными свойствами.
Хотя в~этой книге сравнение функций всё~же используется для методов ◊|Meroonet|◊seePage{objects/method/par:func-eq},
мы~настоятельно рекомендуем по~возможности избегать сравнения функций в~принципе.
