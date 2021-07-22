#lang pollen

◊subsection[#:label "escape/handling/ssect:catch-throw"]{Пара ◊ic{catch}/◊ic{throw}}

◊; TODO: перекрёстные ссылки на ◊ic, здесь и ниже
◊indexC{catch}
◊indexC{catch|seealso{◊ic{throw}}}
◊indexR{специальные формы!catch@◊ic{catch}}
◊indexR{переходы!динамические}
Специальная форма ◊ic{catch} имеет следующий синтаксис:

◊code:lisp{
(catch ◊ii{метка} ◊ii{формы}...)
}

◊indexR{динамическое окружение!окружение меток}
◊indexR{окружение меток!динамическое}
◊noindent
Сперва вычисляется ◊ii{метка}, которая связывается с~продолжением формы ◊ic{catch}.
Раз~связывается, то образуется новое пространство имён — ◊term{динамическое окружение меток} — в~котором и будут храниться эти связи.
Это не~совсем пространство ◊emph{имён}, так как метки не~обязательно являются идентификаторами, но вполне похоже по смыслу.
Правда, произвольность значений меток может вызвать проблемы с~определением их эквивалентности,
а~следовательно, с~поиском в~окружении, так как не~все значения можно легко и однозначно сравнивать.
К~этому вопросу мы ещё вернёмся.

Оставшиеся ◊ii{формы} образуют тело ◊ic{catch} и вычисляются последовательно, как в~◊ic{progn} или ◊ic{begin}.
По~умолчанию, значением формы ◊ic{catch} становится значение последней вычисленной формы.
Однако в~процесс вычислений может вмешаться ◊ic{throw}.

◊indexC{throw}
◊indexC{throw|seealso{◊ic{catch}}}
Форма ◊ic{throw} имеет следующий синтаксис:

◊code:lisp{
(throw ◊ii{метка} ◊ii{форма})
}

◊noindent
Первый аргумент при вычислении должен вернуть значение,
которое эквивалентно метке, связанной с~продолжением формы ◊ic{catch}, внутри которой исполняется ◊ic{throw}.
Далее исполнение переходит к~соответствующему продолжению,
а~вместо значения ◊ic{catch} подставляется значение ◊ii{формы} из~◊ic{throw}.

Вернёмся к~примеру с~поиском в~двоичном дереве и перепишем его с~использованием ◊ic{catch} и ◊ic{throw}.
В~этой реализации значение ◊ic{id} просто захватывается вспомогательной функцией, а~не~передаётся как аргумент.

◊indexC{find-symbol!с~переходами}
◊code:lisp{
(define (find-symbol id tree)
  (define (find tree)
    (if (pair? tree)
        (or (find (car tree))
            (find (cdr tree)) )
        (if (eq? tree id)
            (throw 'find #t)
            #f ) ) )
  (catch 'find
    (find tree) ) )
}

Оправдывая своё название, форма ◊ic{catch} ловит значение, которое бросает ей ◊ic{throw}.
Переход в~данном случае идентифицируется значением, связанным с~продолжением формы ◊ic{catch}.
Иными словами, ◊ic{catch} — это связывающая форма, которая ассоциирует метку с~текущим продолжением.
Форма ◊ic{throw} фактически ссылается на это продолжение, используя его для управления потоком вычислений.
Сама по себе она не~возвращает значения — ◊ic{throw} лишь заставляет ◊ic{catch} вернуть указанное значение.
В~приведённом выше примере ◊ic{catch} захватывает продолжение вызова ◊ic{find-symbol},
а~◊ic{throw} выполняет прямой переход к~дальнейшим вычислениям,
которые выполняются после вызова ◊ic{find-symbol}.

◊indexR{динамическое окружение!окружение меток}
Динамическое окружение меток описывается следующей таблицей свойств:

◊envtable{
  ◊tr{◊td{Ссылка}      ◊td{◊ic{(throw ◊ii{метка} ...)}}           }
  ◊tr{◊td{Значение}    ◊td{отсутствует, это объекты второго сорта}}
  ◊tr{◊td{Изменение}   ◊td{запрещено}                             }
  ◊tr{◊td{Расширение}  ◊td{◊ic{(catch ◊ii{метка} ...)}}           }
  ◊tr{◊td{Определение} ◊td{запрещено}                             }
}

Обратите внимание: ◊ic{catch} — это не~функция, а~специальная форма.
◊ic{catch} вычисляет свой первый аргумент (метку),
затем связывает с~ней в~динамическом окружении своё продолжение,
после чего вычисляет оставшиеся формы подобно ◊ic{begin}.
Последовательное вычисление может быть прервано с~помощью ◊ic{throw}.
Когда ◊ic{catch} возвращает значение последней вычисленной формы
или когда мы покидаем ◊ic{catch} через ◊ic{throw},
связь между меткой и продолжением автоматически удаляется.

◊indexC{throw!варианты реализации}
Форму ◊ic{throw} можно реализовать и~как функцию, и~как специальную форму.
Если это специальная форма, как в~◊|CommonLisp|, то она вычисляет метку,
затем ищет соответствующее продолжение ◊ic{catch},
и~если находит, то вычисляет значение для передачи и выполняет переход.
Если~же ◊ic{throw} реализована как функция, то всё происходит немного в~другом порядке:
сначала вычисляются оба аргумента, затем ищется ◊ic{catch}, после чего выполняется переход.

Такие семантические различия хорошо показывают неточность описания управляющих форм естественным языком.
Можно придумать множество вопросов, на которые сложно дать однозначный ответ.
Например, что делать, если соответствующей ◊ic{catch}-формы не~оказалось?
Как именно сравниваются метки?
Что произойдёт, если написать ◊nobr{◊ic{(throw ◊${\alpha} (throw ◊${\beta} ◊${\pi}))}}?
Ответами на подобные вопросы мы займёмся чуть позже.
