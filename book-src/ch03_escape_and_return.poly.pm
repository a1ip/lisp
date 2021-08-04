% -*- coding: utf-8 -*-

◊subsection[#:label "escape/forms/ssect:protection"]{Защитные формы}

◊indexC{unwind-protect}
◊indexC{car}◊indexC{cdr}
Осталось рассмотреть ещё один эффект, относящийся к~продолжениям.
Связан он
со~специальной формой ◊ic{unwind-protect}.
Названием она обязана принципу первой
реализации◊footnote{Тут та~же ситуация, что и с~◊ic{car} и~◊ic{cdr}, которые
являются акронимами от «◊english{contents of the address register}» и
«◊english{contents of the decrement register}»~— с~помощью данных
примитивов обрабатывались точечные пары в~оригинальной реализации Лиспа для
IBM~704.
Это не~имеет ничего общего с~текущими реализациями, но названия
приклеились.} и задуманному функциональному назначению.
Вот синтаксис этой
формы:

◊code:lisp{
(unwind-protect |◊ii{форма}|
  |◊ii{формы-уборщики}|...
)
}

Сначала вычисляется ◊ii{форма}, её значение станет значением всей формы
◊ic{unwind-protect}.
Как только значение ◊ii{формы} получено, вычисляются
◊ii{формы-уборщики}, и только потом ◊ic{unwind-protect} возвращает ранее
вычисленное значение.
Она похожа на ◊ic{prog1} из {◊CommonLisp} или ◊ic{begin0}
из некоторых версий Scheme, которые последовательно вычисляют формы подобно
◊ic{begin}, но возвращают значение первой из них, а не~последней.
Вот только
◊ic{unwind-protect} гарантирует выполнение ◊ii{уборщиков} даже в~случае, если
вычисление ◊ii{формы} было прервано переходом.
Поэтому:

◊code:lisp{
(let ((a 'on))          |◊dialect{◊CommonLisp}|
  (cons (unwind-protect (list a)
          (setq a 'off) )
        a ) ) |◊is| ((on) . off)

(block foo
  (unwind-protect (return-from foo 1)
    (print 2) ) ) |◊is| 1 ; и печатает ◊ic{2}
}

Данная форма полезна, когда состояние системы должно быть восстановлено вне
зависимости от результата производимых действий.
Например, когда мы читаем файл,
то в~конце он должен быть закрыт в~любом случае.
Другим примером является
эмуляция ◊ic{catch} с~помощью ◊ic{block}.
Если данные формы используются
одновременно, то возможна рассинхронизация состояния ◊ic{*active-catchers*}.
Этот недостаток можно исправить с~помощью ◊ic{unwind-protect}, гарантируя
восстановление ◊ic{*active-catchers*}:

◊indexCS{catch}{с~помощью ◊ic{unwind-protect}}
◊code:lisp{
(define-syntax catch
  (syntax-rules ()
    ((catch tag . body)
     (let ((saved-catchers *active-catchers*))
       (unwind-protect
         (block label
           (set! *active-catchers*
                 (cons (cons tag (lambda (x) (return-from label x)))
                       *active-catchers*) )
           . body )
         (set! *active-catchers* saved-catchers) ) ) ) ) )
}

Что~бы ни~случилось, теперь ◊ic{*active-catchers*} будет иметь корректное
состояние при выходе из тела формы.
Форму ◊ic{block} можно использовать внутри
◊ic{catch} не~опасаясь, что ◊ic{catch} не~удалится из ◊ic{*active-catchers*},
так как теперь за этим следит ◊ic{unwind-protect}.
Это гораздо лучше, хотя всё
ещё не~идеально: ◊ic{*active-catchers*} доступна не~только ◊ic{catch} и
◊ic{throw}, так что её состояние всё равно можно исказить (случайно или
намеренно).

Форма ◊ic{unwind-protect} обеспечивает защиту системы от противоречий, выполняя
определённые действия после завершения вычислений.
Следовательно, эта форма
обязана знать, когда именно они завершаются.
Но в~присутствии продолжений
с~неограниченным временем жизни ◊ic{unwind-protect} не~может легко ответить на
этот вопрос.◊footnote*{Правильно работающий аналог ◊ic{unwind-protect} для
Scheme~— ◊ic{dynamic-wind}, — был описан ещё в~◊cite{fwh92};
см.~также~◊cite{que93c}.}

Как мы уже не~раз говорили, семантика управляющих структур далека от точного
определения.
Рассмотрим лишь несколько примеров, где нельзя однозначно сказать,
какой мы получим результат:

◊code:lisp{
(block foo
  (unwind-protect (return-from foo 1)
    (return-from foo 2) ) )                          |◊is| |◊ii{?}|

(catch 'bar
  (block foo
    (unwind-protect (return-from foo (throw 'bar 1))
      (throw 'something (return-from foo 2)) ) ) )   |◊is| |◊ii{?}|
}

◊indexCS{unwind-protect}{проблемы семантики}
Конечно, стремление к~более точным определениям управляющих структур
естественно, однако нельзя игнорировать очевидную неопределённость, привносимую
продолжениями в~понятие «после вычислений».
Не~всё можно выяснить только по
исходному коду.
Продолжения по определению ◊emph{динамичны}, так как являются
воплощением потока исполнения.
Рассмотрим следующий пример:

◊code:lisp{
(block bar
  (unwind-protect (return-from bar 1)
    (block foo |◊${◊pi}|) ) )
}

◊phantomlabel{escape/forms/protection/p:discard}
◊ic{unwind-protect} вклинивается в~поток исполнения и не~даёт завершить переход,
который выполняется в~охраняемой ей форме.
Вместо этого данный переход
становится продолжением формы ◊ic{(block foo~...)}.
Если она просто вернёт
результат, то это продолжение активируется и форма ◊ic{(block bar~...)}
передаст~◊ic{1} своему продолжению.
Если~же внутри ◊${◊pi} будет выполнен переход,
то данное продолжение должно быть отброшено и заменено продолжением перехода.
В~этом случае из-за ◊ic{unwind-protect} «после вычислений ◊ic{(return-from
bar~1)}» не~наступает вообще.
(Мы обсудим этот феномен позже вместе деталями
реализации данной формы.)

◊bigskip

Конечно~же, есть и другие управляющие формы.
Особенно их жалует {◊CommonLisp},
в~котором реализована даже старая ◊ic{prog}, только под названием ◊ic{tagbody}.
Её можно легко проэмулировать с~помощью ◊ic{labels} и ◊ic{block}.
◊seeEx[escape/ex:tagbody] Интересным фактом является то, что если продолжения
имеют исключительно динамическое время жизни, то для реализации любого
управления потоком исполнения достаточно форм ◊ic{block}, ◊ic{return-from} и
◊ic{unwind-protect}.
Аналогично, для продолжений с~неограниченным временем жизни
достаточно одной ◊ic{call/cc}.
Очевидно, что мы не~сможем легко реализовать
◊ic{call/cc}, имея лишь продолжения с~динамическим временем жизни.
Обратное
вполне возможно, хотя это и стрельба из пушки по воробьям.
Способ станет вполне
очевидным после рассмотрения реализации интерпретатора с~явными продолжениями.


◊subsubsection{Защита и динамические~переменные}

◊indexC{fluid-let}
◊indexCS{unwind-protect}{динамические переменные}
◊indexR{динамические переменные!◊protect◊ic{unwind-protect}}
Некоторые реализации Scheme обеспечивают динамическое время жизни переменных
не~так, как мы показывали ранее.
Они делают это с~помощью ◊ic{unwind-protect}
или аналогичного механизма.
Идея состоит в~том, чтобы «одолжить» нужную
лексическую переменную, восстановив впоследствии её значение обратно.
Подобные
динамические переменные реализуются с~помощью формы ◊ic{fluid-let}:

{◊def◊A{◊hbox to 0pt{◊${◊alpha}}}
◊def◊B{◊hbox to 0pt{◊${◊beta}}}
◊def◊E{◊hbox to 0pt{◊kern0.15em◊${◊equiv}}}
◊def◊T{◊hbox to 0pt{◊ii{tmp}}}
◊code:lisp{
(fluid-let ((x |◊${◊alpha}|)) |◊E|   (let ((|◊T|    x))
  |◊B| ...
)                (set! x |◊A| )
                        (unwind-protect
                          (begin |◊B| ...)
                          (set! x |◊T|   ) ) )
}}

В~процессе вычисления ◊${◊beta} будет видна переменная~◊ic{x}
со~значением~◊${◊alpha}; предыдущее значение ◊ic{x} сохраняется на время
вычислений в~локальной переменной ◊ii{tmp} и восстанавливается после их
завершения.
Это подразумевает, что есть такая лексическая переменная~◊ic{x},
которой можно воспользоваться.
Обычно она глобальная, чтобы её было видно
отовсюду.
Если она будет локальной, то её поведение будет (значительно)
отличаться от должного поведения динамической переменной в~{◊CommonLisp}: ведь
тогда она будет правильно работать внутри ◊ic{fluid-let}, но не~в~связывающих
формах, вложенных во~◊ic{fluid-let}.
Далее, очевидно, что такие переменные тоже
не~дружат с~◊ic{call/cc}.
В~итоге получается нечто ещё более хитрое, нежели
обычные динамические переменные {◊CommonLisp}.


◊section[#:label "escape/sect:actors"]{Участники вычислений}

◊indexR{вычисления!контекст}
◊indexR{контекст вычислений}
Сейчас мы считаем, что для проведения вычислений необходимы три вещи: выражение,
окружение и продолжение.
Тактическая цель вычислений: определить значение
выражения в~окружении.
Стратегическая~— передать это значение продолжению.

◊indexR{записи активации}
◊indexR{фреймы стека}
◊indexR{стековые фреймы}
Мы определим новый интерпретатор, чтобы показать, какие продолжения нужны на
каждом этапе вычислений.
Так как обычно продолжения представляются снимками
фреймов стека (или записей активаций), то мы будем использовать объекты для
представления этих сущностей внутри разрабатываемого интерпретатора.


◊subsection[#:label "escape/actors/ssect:review"]{Краткий обзор~объектов}

◊indexR{объекты}
◊indexE{Meroon@◊protect◊MeroonMeroonet!вводное описание}
В~этом разделе мы не~будем детально разбирать устройство объектной системы,
отложив эту задачу до одиннадцатой главы.
Здесь рассматриваются лишь три~макроса
и несколько правил именования.
Такие макросы выражают суть объектов и в~том
или~ином виде присутствуют в~любой объектной системе любого языка.
Объекты~же
используются для того, чтобы подсказать удобный вариант реализации продолжений.
Уж очень хорошо понятие записи активации, инкапсулирующей различные данные,
связанные с~вызовами подпрограмм, укладывается в~концепцию объектов с~полями.
Также у~нас будет в~распоряжении наследование, которое поможет вынести общие
части реализации за скобки, уменьшая таким образом размер интерпретатора.

Я полагаю, что вы знакомы с~философией, терминологией и подходами
объектно-ориентированного программирования, так что будет достаточно показать,
как здесь записываются известные вам идиомы, которые мы будем использовать.

◊indexR{классы}
◊indexR{методы}
◊indexR{обобщённые функции}
◊indexR{функции!обобщённые}
Объекты группируются в~◊term{классы}; объекты одного класса имеют одинаковые
◊term{методы}; сообщения посылаются с~помощью ◊term{обобщённых функций},
популяризованных Common Loops~◊cite{bkk+86}, CLOS~◊cite{bdg+88} и
◊TELOS~◊cite{pnb93}.
Для нас важнейшей возможностью объектно-ориентированного
программирования является отделение обработки различных специальных форм и
примитивных функций от ядра интерпретатора.
Но всё имеет свою цену: в~этом
случае будет сложнее увидеть картину целиком, так как обработка будет размазана
по нескольким местам.


◊subsubsection{Определение классов}

◊indexC{define-class}
Классы определяется с~помощью ◊ic{define-class} следующим образом:

◊code:lisp{
(define-class |◊ii{класс}| |◊ii{суперкласс}|
  (|◊ii{поля}|...) )
}

◊indexR{поля}
◊indexR{аксессоры}
Эта форма определяет класс с~именем ◊ii{класс}, который наследует поля и методы
◊ii{суперкласса}, а также имеет свои собственные ◊ii{поля}.
Вместе с~классом
создаётся набор вспомогательных функций.
Функция ◊ic{make-◊ii{класс}} создаёт
объекты этого класса; количество и порядок её аргументов соответствуют порядку
указания полей при определении класса.
Названия аксессоров чтения состоят из
имени класса и имени поля, разделённых дефисом.
Названия аксессоров записи
аналогичны аксессорам чтения, только с~◊ic{set-} в~начале и восклицательным
знаком в~конце.
Возвращаемое значение аксессоров записи не~определено.
Предикат
◊ic{◊ii{класс}?} проверяет, является~ли объект экземпляром данного класса.

◊indexC{Object}
Корнем иерархии наследования является класс ◊ic{Object}, не~имеющий полей.

Например, определение

◊code:lisp{
(define-class continuation Object (k))
}

◊noindent
создаст следующие функции:

◊code:lisp{
(make-continuation k)         ; конструктор
(continuation-k c)            ; аксессор чтения
(set-continuation-k! c k)     ; аксессор записи
(continuation? k)             ; предикат принадлежности
}


◊subsubsection{Определение обобщённых~функций}

◊indexC{define-generic}
◊indexR{обобщённые функции}
Обобщённые функции определяются следующим образом:

◊code:lisp{
(define-generic (|◊ii{функция}| |◊ii{аргументы}|)
  |◊textrm{◊${[}◊ic{◊ii{трактовка-по-умолчанию}...}◊${]}}|)
}

◊indexR{дискриминант}
◊indexR{обобщённые функции!дискриминант}
Эта форма определяет обобщённую ◊ii{функцию}; формы
◊ii{трак◊-товки-по-умол◊-чанию} станут её телом, если при вызове функции
не~найдётся подходящего специализированного варианта.
Список аргументов
указывается как обычно, за исключением того, что один из них является
◊term{дискриминантом}; дискриминант записывается в~скобках:

◊code:lisp{
(define-generic (invoke (f) v* r k)
  (wrong "Not a function" f r k) )
}

Таким образом определяется обобщённая функция ◊ic{invoke}, для которой можно
в~последующем задать специализированные варианты.
Данная функция имеет четыре
аргумента, первый из них~— ◊ic{f} — это дискриминант.
Если для
класса~◊ic{f} не~найдётся специализированного варианта функции (метода
класса~◊ic{f}), то будет выбран вариант по умолчанию: вызов~◊ic{wrong}.


◊subsubsection{Определение методов}

◊indexC{define-method}
Форма ◊ic{define-method} используется для специализации обобщённых функций
конкретными методами.

◊code:lisp{
(define-method (|◊ii{функция}| |◊ii{аргументы}|)
  |◊ii{тело}|...
)
}

Аргументы указываются аналогично ◊ic{define-generic}.
Класс дискриминанта, для
которого создаётся метод, указывается после него.
Например, мы можем создать
метод ◊ic{invoke} для класса ◊ic{primitive} следующим образом:

◊code:lisp{
(define-method (invoke (f primitive) v* r k)
  ((primitive-address f) v* r k) )
}

На этом мы заканчиваем обзор объектной системы и переходим к~написанию
интерпретатора.
Детали реализации, а также другие возможности объектов будут
рассмотрены в~одиннадцатой главе.
Здесь мы ограничимся наиболее простыми и
известными из них, чтобы облегчить понимание и уменьшить количество возможных
проблем.


◊subsection[#:label "escape/actors/ssect:interpreter"]{Интерпретатор}

◊indexR{соглашения именования}
◊indexE{e @◊protect◊ic{e} (выражения)}
◊indexE{r @◊protect◊ic{r} (лексическое окружение)}
◊indexE{k @◊protect◊ic{k} (продолжения)}
◊indexE{v @◊protect◊ic{v} (значения)}
◊indexE{f @◊protect◊ic{f} (функции)}
◊indexE{n @◊protect◊ic{n} (идентификаторы)}
Функция ◊ic{evaluate} имеет три аргумента: выражение, окружение и продолжение.
Начинает она свою работу с~выяснения смысла выражения, чтобы выбрать правильный
метод его вычисления, который хранится в~специализированной функции.
Перед тем,
как продолжить, давайте договоримся о~правилах именования переменных, которых
теперь будет довольно много.
Первое правило: сущность «список~◊ii{x}» будем
называть ◊ic{◊ii{x}*}.
Второе: сущности интерпретатора будем называть
одной-двумя буквами для краткости:

◊begin{center}◊begin{tabular}{>{◊raggedleft}p{0.3◊textwidth}p{0.6◊textwidth}}
◊ic{e}, ◊ic{et}, ◊ic{ec}, ◊ic{ef} & выражения, формы                          ◊◊
                           ◊ic{r} & окружения                                 ◊◊
                  ◊ic{k}, ◊ic{kk} & продолжения                               ◊◊
                           ◊ic{v} & значения (числа, пары, замыкания {◊itd})◊◊
                           ◊ic{f} & функции                                   ◊◊
                           ◊ic{n} & идентификаторы
◊end{tabular}◊end{center}


Всё, теперь принимаемся за интерпретатор.
Для простоты он считает все атомы,
кроме переменных, автоцитированными значениями.

◊indexC{evaluate}
◊code:lisp{
(define (evaluate e r k)
  (if (atom? e)
      (cond ((symbol? e) (evaluate-variable e r k))
            (else        (evaluate-quote e r k)) )
      (case (car e)
        ((quote)  (evaluate-quote (cadr e) r k))
        ((if)     (evaluate-if (cadr e) (caddr e) (cadddr e) r k))
        ((begin)  (evaluate-begin (cdr e) r k))
        ((set!)   (evaluate-set! (cadr e) (caddr e) r k))
        ((lambda) (evaluate-lambda (cadr e) (cddr e) r k))
        (else     (evaluate-application (car e) (cdr e) r k)) ) ) )
}

Собственно интерпретатор состоит из трёх функций: ◊ic{evaluate}, ◊ic{invoke} и
◊ic{resume}.
Две последние являются обобщёнными и знают, как вызывать вызываемое
и продолжать продолжаемое.
Все вычисления в~конечном счёте сводятся к~обмену
значениями между этими функциями.
Вдобавок мы введём ещё две полезные обобщённые
функции для работы с~переменными: ◊ic{lookup} и~◊ic{update!}.

◊indexC{invoke}
◊indexC{resume}
◊indexC{lookup}
◊indexC{update"!}
◊code:lisp{
(define-generic (invoke (f) v* r k)
  (wrong "Not a function" f r k) )

(define-generic (resume (k continuation) v)
  (wrong "Unknown continuation" k) )

(define-generic (lookup (r environment) n k)
  (wrong "Not an environment" r n k) )

(define-generic (update! (r environment) n k v)
  (wrong "Not an environment" r n k) )
}

Все сущности, которыми мы будем оперировать, наследуются от трёх базовых
классов:

◊indexC{value}
◊indexC{environment}
◊indexC{continuation}
◊code:lisp{
(define-class value        Object ())
(define-class environment  Object ())
(define-class continuation Object (k))
}

Классы значений являются наследниками ◊ic{value}, классы окружений —
наследники ◊ic{environment}, классы продолжений~— ◊ic{continuation}.


◊subsection[#:label "escape/actors/ssect:quoting"]{Цитирование}

Специальная форма цитирования всё так~же является наиболее простой, её задача
сводится к~передаче значения в~неизменной форме текущему продолжению:

◊indexC{evaluate-quotation}
◊code:lisp{
(define (evaluate-quotation v r k)
  (resume k v) )
}


◊subsection[#:label "escape/actors/ssect:alternatives"]{Ветвление}

Условный оператор использует два продолжения: текущее и продолжение вычисления
условия, которое выберет и вычислит необходимую ветку.
Для этого продолжения мы
создадим отдельный класс.
После вычисления условия ещё остаётся вычисление той
или иной ветки, а~значит, в~продолжении необходимо хранить сами ветки и
окружение для их вычисления.
Результат вычисления одной из веток надо будет
передать продолжению условной формы, которое тоже надо где-то хранить.
Таким
образом, мы пишем:

◊indexC{if-cont}
◊indexC{evaluate-if}
◊indexCS{resume}{◊ic{if-cont}}
◊code:lisp{
(define-class if-cont continuation (et ef r))

(define (evaluate-if ec et ef r k)
  (evaluate ec r (make-if-cont k et ef r)) )

(define-method (resume (k if-cont) v)
  (evaluate (if v (if-cont-et k) (if-cont-ef k))
            (if-cont-r k)
            (if-cont-k k) ) )
}

Форма вначале вычисляет условие~◊ic{ec} в~своём окружении~◊ic{r}, но с~новым
продолжением.
Как только мы заканчиваем вычислять условие, результат передаётся
◊ic{resume}, которая вызывает специализацию для нашего класса продолжений.
В~этом продолжении мы выполняем собственно выбор, вычисляем одну их сохранённых
веток в~сохранённом окружении и передаём результат сохранённому продолжению всей
условной формы.◊footnote*{С~точки зрения реализации можно считать, что
◊ic{make-if-cont} кладёт в~стек ◊ic{et} и ◊ic{ef}, а также ◊ic{r}; под ними
в~стеке лежат аналогичные группы выражений и окружений, которые фактически и
есть ничем иным, как продолжением~◊ic{k}.
А~вызовы вроде ◊ic{(if-cont-et k)}
лишь снимают с~верхушки стека нужные данные.}


◊subsection[#:label "escape/actors/ssect:sequence"]{Последовательность}

Здесь нам тоже потребуются два продолжения: текущее и продолжение вычисления
оставшихся форм.

◊indexC{begin-cont}
◊indexC{evaluate-begin}
◊indexCS{resume}{◊ic{begin-cont}}
◊code:lisp{
(define-class begin-cont continuation (e* r))

(define (evaluate-begin e* r k)
  (if (pair? e*)
    (if (pair? (cdr e*))
        (evaluate (car e*) r (make-begin-cont k e* r))
        (evaluate (car e*) r k) )
    (resume k empty-begin-value) ) )

(define-method (resume (k begin-cont) v)
  (evaluate-begin (cdr (begin-cont-e* k))
                  (begin-cont-r k)
                  (begin-cont-k k) ) )
}

Случаи ◊ic{(begin)} и ◊ic{(begin~◊${◊pi})} тривиальны.
Если~же ◊ic{begin}
передано больше выражений, то вычисление первого из них продолжается
◊ic{(make-begin-cont k~e*~r)}.
Это продолжение принимает значение~◊ic{v}
с~помощью ◊ic{resume}, игнорирует его и продолжает оставшиеся вычисления
в~том~же окружении и с~тем~же продолжением.◊footnote*{Внимательный читатель
наверняка заметил странную форму ◊ic{(cdr (begin-cont-e* k))} в~методе
◊ic{resume}.
Конечно, мы могли~бы отбросить уже вычисленное выражение ещё
в~◊ic{evaluate-begin}: ◊ic{(make-begin-cont k (cdr~e*) r)}, и получить тот~же
результат.
Причина такого решения в~том, что если случится ошибка, то у~нас
будет на руках её источник.}


◊subsection[#:label "escape/actors/ssect:variables"]{Окружения}

Значения переменных хранятся в~окружениях.
Они тоже представляются объектами:

◊indexC{null-env}
◊indexC{full-env}
◊indexC{variable-env}
◊code:lisp{
(define-class null-env environment ())
(define-class full-env environment (others name))
(define-class variable-env full-env (value))
}

Нам потребуются два типа окружений: пустое начальное окружение ◊ic{null-env} и
окружения с~переменными ◊ic{variable-env}.
Последние хранят одну привязку имени
◊ic{name} к~значению ◊ic{value}, а также ссылку на остальные привязки этого
окружения в~поле ◊ic{others}.
То~есть это обычный А-список, разве что для
хранения каждой привязки используется объект с~тремя полями, а не~две точечных
пары.

Для нахождения значения переменной мы делаем следующее:

◊indexC{evaluate-variable}
◊code:lisp{
(define (evaluate-variable n r k)
  (lookup r n k) )

(define-method (lookup (r null-env) n k)
  (wrong "Unknown variable" n r k) )

(define-method (lookup (r full-env) n k)
  (lookup (full-env-others r) n k) )

(define-method (lookup (r variable-env) n k)
  (if (eqv? n (variable-env-name r))
      (resume k (variable-env-value r))
      (lookup (variable-env-others r) n k) ) )
}

Обобщённая функция ◊ic{lookup} проходит по окружению, пока не~найдёт подходящую
привязку: с~совпадающим именем и~хранящую значение переменной.
Найденное
значение передаётся исходному продолжению с~помощью ◊ic{resume}.

Изменение значения происходит похожим образом:

◊indexC{set"!-cont}
◊indexC{evaluate-set"!}
◊indexCS{resume}{◊ic{set"!-cont}}
◊indexCS{update"!}{◊ic{null-env}}
◊indexCS{update"!}{◊ic{full-env}}
◊indexCS{update"!}{◊ic{variable-env}}
◊code:lisp{
(define-class set!-cont continuation (n r))

(define (evaluate-set! n e r k)
  (evaluate e r (make-set!-cont k n r)) )

(define-method (resume (k set!-cont) v)
  (update! (set!-cont-r k) (set!-cont-n k) (set!-cont-k k) v) )

(define-method (update! (r null-env) n k v)
  (wrong "Unknown variable" n r k) )

(define-method (update! (r full-env) n k v)
  (update! (full-env-others r) n k v) )

(define-method (update! (r variable-env) n k v)
  (if (eqv? n (variable-env-name r))
      (begin (set-variable-env-value! r v)
             (resume k v) )
      (update! (variable-env-others r) n k v) ) )
}

Нам потребовалось вспомогательное продолжение, так как присваивание проходит
в~два этапа: сначала надо вычислить присваиваемое значение, потом присвоить его
переменной.
Класс ◊ic{set!-cont} представляет необходимые продолжения, его метод
◊ic{resume} лишь вызывает ◊ic{update!} для установки значения, после чего
продолжает дальнейшие вычисления.


◊subsection[#:label "escape/actors/ssect:functions"]{Функции}

Создать функцию легко, с~этим справится ◊ic{make-function}:

◊indexC{function}
◊indexC{evaluate-lambda}
◊code:lisp{
(define-class function value (variables body env))

(define (evaluate-lambda n* e* r k)
  (resume k (make-function n* e* r)) )
}

Чуть сложнее будет вызвать созданную функцию.
Обратите внимание на неявное
использование ◊ic{progn}/◊ic{begin} для тела функций.

◊indexCS{invoke}{◊ic{function}}
◊code:lisp{
(define-method (invoke (f function) v* r k)
  (let ((env (extend-env (function-env f)
                         (function-variables f)
                         v* )))
    (evaluate-begin (function-body f) env k) ) )
}

Может показаться странным, что функция принимает текущее окружение~◊ic{r}, но
никак не~использует его.
Это сделано по нескольким причинам.
Во-первых, обычно
при компиляции текущие окружение и продолжение считаются чем-то вроде
глобальных динамических переменных и передаются через жёстко заданные регистры,
которые никак не~выкинуть из реализации.
Во-вторых, некоторые функции (о~них
поговорим позже, когда будем рассматривать рефлексию) могут изменять текущее
окружение; например, отладочные функции по запросу пользователя могут изменять
значения произвольных переменных.

Следующая функция расширяет окружение переменных.
И~выполняет проверку
согласованности количества имён и связываемых с~ними значений.

◊indexC{extend-env}
◊code:lisp{
(define (extend-env env names values)
  (cond ((and (pair? names) (pair? values))
         (make-variable-env
          (extend-env env (cdr names) (cdr values))
          (car names)
          (car values) ) )
        ((and (null? names) (null? values)) env)
        ((symbol? names) (make-variable-env env names values))
        (else (wrong "Arity mismatch")) ) )
}

Осталось только определить собственно применение функций.
Здесь надо помнить
о~том, что функция применяется к~списку аргументов.

◊indexC{evfun-cont}◊indexC{apply-cont}
◊indexC{argument-cont}◊indexC{gather-cont}
◊indexC{evaluate-application}
◊indexCS{resume}{◊ic{evfun-cont}}
◊indexC{no-more-arguments}
◊indexC{evaluate-arguments}
◊indexCS{resume}{◊ic{argument-cont}}
◊indexCS{resume}{◊ic{gather-cont}}
◊indexCS{resume}{◊ic{apply-cont}}
◊code:lisp{
(define-class evfun-cont    continuation (e* r))
(define-class apply-cont    continuation (f  r))
(define-class argument-cont continuation (e* r))
(define-class gather-cont   continuation (v))

(define (evaluate-application e e* r k)
  (evaluate e r (make-evfun-cont k e* r)) )

(define-method (resume (k evfun-cont) f)
  (evaluate-arguments (evfun-cont-e* k)
                      (evfun-cont-r k)
                      (make-apply-cont (evfun-cont-k k) f
                                       (evfun-cont-r k) ) ) )
(define no-more-arguments '())

(define (evaluate-arguments e* r k)
  (if (pair? e*)
      (evaluate (car e*) r (make-argument-cont k e* r))
      (resume k no-more-arguments) ) )

(define-method (resume (k argument-cont) v)
  (evaluate-arguments (cdr (argument-cont-e* k))
                      (argument-cont-r k)
                      (make-gather-cont (argument-cont-k k) v) ) )

(define-method (resume (k gather-cont) v*)
  (resume (gather-cont-k k) (cons (gather-cont-v k) v*)) )

(define-method (resume (k apply-cont) v)
  (invoke (apply-cont-f k) v
          (apply-cont-r k)
          (apply-cont-k k) ) )
}

На первый взгляд, здесь всё слишком сложно, но только на первый.
Вычисления
проводятся слева направо, так что первой вычисляется сама функция с~продолжением
◊ic{evfun-cont}.
Это продолжение должно вычислить аргументы функции и передать
их продолжению, которое применит функцию к~списку значений аргументов.
В~процессе вычисления аргументов мы обращаемся к~продолжениям ◊ic{gather-cont},
которые последовательно собирают вычисленные аргументы в~список.

◊indexR{продолжения (continuations)!иллюстрация стека}
Давайте рассмотрим на примере, что происходит при вычислении ◊ic{(cons
foo~bar)}.
Пусть переменная ◊ic{foo} имеет значение~◊${33}, а ◊ic{bar}
равна~◊${-77}.
Стек продолжений показан справа, а вычисляемое выражение слева.
◊ii{k}~— это текущее продолжение, ◊ii{r} — текущее окружение.
Функция-значение переменной ◊ic{cons} записывается как ◊ii{cons}.

{◊def◊EV{◊ii{evaluate}} ◊def◊RE{◊ii{resume}} ◊def◊IV{◊ii{invoke}}
 ◊def◊EA{◊ii{evaluate-arguments}}
 ◊def◊EC{◊icc{evfun-cont}}
 ◊def◊PC{◊icc{apply-cont}}
 ◊def◊GC{◊icc{gather-cont}}
 ◊def◊AC{◊icc{argument-cont}}
 ◊def◊iv#1{◊textsf{#1}}
 ◊def◊X{◊kern0.75em}
%
◊begin{eval-stack}
  {◊EV} (cons foo bar) ◊ii{r} ◊-                                        ◊ii{k}◊◊
  {◊EV} cons ◊ii{r}           ◊-                 {◊EC} (foo bar) ◊ii{r} ◊ii{k}◊◊
  {◊RE} ◊ii{cons}             ◊-                 {◊EC} (foo bar) ◊ii{r} ◊ii{k}◊◊
  {◊EA} (foo bar) ◊ii{r}      ◊-                        {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊EV} foo ◊ii{r}            ◊- {◊AC} (foo bar) ◊ii{r} {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊RE} ◊iv{33}               ◊- {◊AC} (foo bar) ◊ii{r} {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊EA} (bar) ◊ii{r}         ◊-           {◊GC} ◊iv{33} {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊EV} bar ◊ii{r}      ◊-{◊AC} () ◊ii{r} {◊GC} ◊iv{33} {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊RE} ◊iv{--77}      ◊- {◊AC} () ◊ii{r} {◊GC} ◊iv{33} {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊EA} () ◊ii{r}      ◊- {◊GC} ◊iv{--77} {◊GC} ◊iv{33} {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊RE} ◊iv{(◊,)}       ◊-{◊GC} ◊iv{--77} {◊GC} ◊iv{33} {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊RE} ◊iv{(--77)}        ◊-             {◊GC} ◊iv{33} {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊RE} ◊iv{(33◊X--77)}      ◊-                         {◊PC} ◊ii{cons} ◊ii{k}◊◊
  {◊IV} ◊ii{cons} ◊iv{(33◊X--77)}◊-                                     ◊ii{k}
◊end{eval-stack}}


◊section[#:label "escape/sect:init"]{Инициализация интерпретатора}

Перед погружением в~сокровенные тайны устройства управляющих форм, давайте
сначала подготовим наш интерпретатор к~запуску.
Этот раздел похож на
раздел~◊ref{basics/sect:global-environment}.
◊seePage[basics/sect:global-environment] Неплохо было~бы вначале научить наш
интерпретатор нескольким полезным вещам вроде ◊ic{car}, поэтому объявим
пару макросов, которые помогут нам наполнить его глобальное окружение.

◊indexC{definitial}
◊indexC{defprimitive}
◊indexC{primitive}
◊indexC{r.init}
◊indexC{cons}
◊indexC{car}
◊code:lisp{
(define-syntax definitial
  (syntax-rules ()
    ((definitial name)
     (definitial name 'void) )
    ((definitial name value)
     (begin (set! r.init (make-variable-env r.init 'name value))
            'name ) ) ) )

(define-class primitive value (name address))

(define-syntax defprimitive
  (syntax-rules ()
    ((defprimitive name value arity)
     (definitial name
       (make-primitive
        'name (lambda (v* r k)
                (if (= arity (length v*))
                    (resume k (apply value v*))
                    (wrong "Incorrect arity" 'name v*) ) ) ) ) ) ) )

(define r.init (make-null-env))

(defprimitive cons cons 2)
(defprimitive car car 1)
}

Создаваемые примитивные функции должны вызываться той~же функцией ◊ic{invoke},
которая обрабатывает обычные функции.
Каждый примитив имеет два поля.
Первое из
них служит для упрощения отладки: оно хранит имя примитива.
Естественно, это
лишь подсказка, так как ничто не~мешает в~дальнейшем связать один и тот~же
примитив с~разными именами.◊footnote*{Эта подсказка позволяет также копировать
примитивы по значению: выражение ◊ic{(begin (set!~foo~car) (set!~car~3) foo)}
возвращает ◊ic{#<car>}~— собственное имя примитива, связанного с~глобальной
переменной.} Второе поле хранит «адрес» примитива, ссылку на соответствующую
функцию языка реализации интерпретатора.
В~итоге примитивы вызываются с~помощью
◊ic{invoke} следующим образом:

◊indexCS{invoke}{◊ic{primitive}}
◊code:lisp{
(define-method (invoke (f primitive) v* r k)
  ((primitive-address f) v* r k) )
}

Для запуска нашего прекрасного интерпретатора остаётся лишь определить начальное
продолжение-заглушку.
Это продолжение будет печатать на экран всё, что ему
передают.

◊indexC{bottom-cont}
◊indexCS{resume}{◊ic{bottom-cont}}
◊indexC{chapter3-interpreter}
◊code:lisp{
(define-class bottom-cont continuation (f))

(define-method (resume (k bottom-cont) v)
  ((bottom-cont-f k) v) )

(define (chapter3-interpreter)
  (define (toplevel)
    (evaluate (read)
              r.init
              (make-bottom-cont 'void display) )
    (toplevel) )
  (toplevel) )
}

Заметьте, что мы могли~бы легко написать похожий интерпретатор на истинно
объектно-ориентированном языке, например на Smalltalk~◊cite{gr83}, получив
заодно доступ к~его хвалёному отладчику и среде разработки.
Для полного счастья
останется только добавить те несколько строчек, что открывают гору маленьких
окошек с~контекстными подсказками.


◊section[#:label "escape/sect:implementation"]{Реализация управляющих~форм}

Начнём с~самой мощной формы~— ◊ic{call/cc}.
Парадоксально, но факт: это самая
простая форма, если смотреть на количество кода.
Благодаря используемому нами
объектному подходу и явному присутствию продолжений в~интерпретаторе,
преобразование их в~полноценные объекты языка становится тривиальным.


◊subsection{◊texorpdfstring%
{Реализация ◊protect◊ic{call/cc}}%
{Реализация call/cc}}%
◊label{escape/implementation/ssect:call/cc}

◊indexCS{call/cc}{реализация}
Функция ◊ic{call/cc} берёт текущее продолжение~◊ii{k}, превращает его в~объект,
понятный ◊ic{invoke}, и применяет к~нему свой аргумент~— унарную функцию.
Следующий код чуть~ли не~буквально записывает это определение:

◊indexC{call/cc}
◊code:lisp{
(definitial call/cc
  (make-primitive
   'call/cc
   (lambda (v* r k)
     (if (= 1 (length v*))
         (invoke (car v*) (list k) r k)
         (wrong "Incorrect arity" 'call/cc v*) ) ) ) )
}

Хоть тут и немного строчек, всё~же стоит кое-что объяснить.
◊ic{call/cc} это
функция, но мы определяем её с~помощью ◊ic{defprimitive}, так как это
единственный способ для функции добраться до~◊ic{k}.
Переменная ◊ic{call/cc}
(это всё~же ◊Lisp1) связывается с~объектом класса ◊ic{primitive}.
Для вызова
объектов этого класса необходим «адрес» функции, которому у~нас соответствуют
функции языка определения вида ◊ic{(lambda (v*~r~k) ...)}.
После проверки на
арность первый аргумент ◊ic{call/cc} применяется к~захваченному продолжению.
Само продолжение мы никак не~трогаем, оно остаётся объектом языка определения.
Так как сохранённые «сырые» продолжения могут быть впоследствии переданы
◊ic{invoke} напрямую, то её надо научить обращаться с~ними:

◊indexCS{invoke}{◊ic{continuation}}
◊code:lisp{
(define-method (invoke (f continuation) v* r k)
  (if (= 1 (length v*))
      (resume f (car v*))
      (wrong "Continuations expect one argument" v* r k) ) )
}


◊subsection{◊texorpdfstring{Реализация ◊protect◊ic{catch}}{Реализация catch}}%
◊label{escape/implementation/ssect:catch}

◊indexCS{catch}{реализация}
◊indexCS{throw}{реализация}
Форма ◊ic{catch} по-своему интересна, так как требует разительно иного подхода,
нежели форма~◊ic{block}, которую мы рассмотрим чуть позже.
Как обычно, начнём
с~добавления анализа ◊ic{catch} и~◊ic{throw} в~◊ic{evaluate}:

◊code:lisp{
...
((catch) (evaluate-catch (cadr e) (cddr e) r k))
((throw) (evaluate-throw (cadr e) (caddr e) r k))
...
}

Здесь решено сделать ◊ic{throw} специальной формой, а не~функцией.
В~первую
очередь с~целью походить на {◊CommonLisp}.
Далее определим правила обработки
формы ◊ic{catch}:

◊indexC{catch-cont}
◊indexC{labeled-cont}
◊indexC{evaluate-catch}
◊indexCS{resume}{◊ic{catch-cont}}
◊code:lisp{
(define-class catch-cont   continuation (body r))
(define-class labeled-cont continuation (tag))

(define (evaluate-catch tag body r k)
  (evaluate tag r (make-catch-cont k body r)) )

(define-method (resume (k catch-cont) v)
  (evaluate-begin (catch-cont-body k)
                  (catch-cont-r k)
                  (make-labeled-cont (catch-cont-k k) v) ) )
}

Как видите, ◊ic{catch} вычисляет первый аргумент (метку), связывает с~ней своё
продолжение, создавая таким образом помеченный блок, и, наконец, последовательно
вычисляет формы, составляющие её тело.
Когда продолжение этого блока получает
значение, оно просто перебрасывает его сохранённому продолжению самой формы
◊ic{catch}.
Форма ◊ic{throw} чуть более сложная:

◊indexC{throw-cont}
◊indexC{throwing-cont}
◊indexC{evaluate-throw}
◊indexCS{resume}{◊ic{throw-cont}}
◊indexC{catch-lookup}
◊indexCS{resume}{◊ic{throwing-cont}}
◊indexC{eqv"?}
◊code:lisp{
(define-class throw-cont    continuation (form r))
(define-class throwing-cont continuation (tag cont))

(define (evaluate-throw tag form r k)
  (evaluate tag r (make-throw-cont k form r)) )

(define-method (resume (k throw-cont) tag)
  (catch-lookup k tag k) )

(define-generic (catch-lookup (k) tag kk)
  (wrong "Not a continuation" k tag kk) )

(define-method (catch-lookup (k continuation) tag kk)
  (catch-lookup (continuation-k k) tag kk) )

(define-method (catch-lookup (k bottom-cont) tag kk)
  (wrong "No associated catch" k tag kk) )

(define-method (catch-lookup (k labeled-cont) tag kk)
  (if (eqv? tag (labeled-cont-tag k))  ; внимание на компаратор
      (evaluate (throw-cont-form kk)
                (throw-cont-r kk)
                (make-throwing-cont kk tag k) )
      (catch-lookup (labeled-cont-k k) tag kk) ) )

(define-method (resume (k throwing-cont) v)
  (resume (throwing-cont-cont k) v) )
}

◊indexR{переходы (escapes)!вложенные}
Форма ◊ic{throw} вычисляет первый аргумент и пытается найти продолжение
с~совпадающей меткой.
Если в~процессе поиска она добирается до начального
продолжения, то сигнализирует об~ошибке.
Если~же нет, то вычисляется второй
аргумент ◊ic{throw} и его значение передаётся найденному продолжению.
Но
передаётся оно по-хитрому: через ◊ic{throwing-cont}.
Дело в~том, что в~процессе
вычисления этого значения тоже может возникнуть переход.
Если~бы продолжением
данного вычисления было продолжение, сохранённое в~метке внешней формы
◊ic{throw}, то вложенная форма ◊ic{throw} начинала~бы поиски ◊ic{catch} так, как
будто~бы переход на внешнюю метку уже произошёл.
Но это не~так, так что поиск
следует вести от текущей формы ◊ic{throw}, потому и создаётся специальное
промежуточное продолжение.
В~итоге, когда мы пишем:

◊code:lisp{
(catch 2
  (* 7 (catch 1
         (* 3 (catch 2
                (throw 1 (throw 2 5)) )) )) )
}

◊noindent
то получаем ◊ic{(*~7~3~5)}, а не~◊ic{5}.

Кроме того, реализация ◊ic{throw} как специальной формы позволяет отлавливать
больше ошибок.

◊code:lisp{
(catch 2 (* 7 (throw 1 (throw 2 3))))
}

◊noindent
Эта форма гарантированно вернёт не~◊ic{3}, а ошибку ◊ic{"No~associated catch"},
так как действительно нет ◊ic{catch} с~меткой~◊ic{1} и не~важно, что она
вроде~бы как не~используется.


◊subsection{◊texorpdfstring{Реализация ◊protect◊ic{block}}{Реализация block}}%
◊label{escape/implementation/ssect:block}

◊indexCS{block}{реализация}
◊indexCS{return-from}{реализация}
Для реализации лексических меток переходов необходимо решить две проблемы.
Первая: гарантировать динамическое время жизни продолжений.
Вторая: обеспечить
лексическую видимость меток.
Для решения второй задачи мы, естественно,
воспользуемся лексическими окружениями, где лексическая область видимости есть
«из~коробки».
Над первой~же придётся немного поработать самостоятельно.
Чтобы
не~было путаницы, у~◊ic{block} будет личный класс окружений для хранения
привязок меток к~продолжениям.

Начинаем как обычно: добавляем распознавание формы ◊ic{block} в~◊ic{evaluate} и
описываем необходимые функции-обработчики.

◊indexC{block-cont}
◊indexC{block-env}
◊indexC{evaluate-block}
◊indexCS{resume}{◊ic{block-cont}}
◊code:lisp{
(define-class block-cont continuation (label))
(define-class block-env full-env (cont))

(define (evaluate-block label body r k)
  (let ((k (make-block-cont k label)))
    (evaluate-begin body
                    (make-block-env r label k)
                    k ) ) )

(define-method (resume (k block-cont) v)
  (resume (block-cont-k k) v) )
}

С~нормальным поведением закончили, переходим к~◊ic{return-from}.
Сначала
добавляем её в~◊ic{evaluate}:

◊code:lisp{
...
((block)       (evaluate-block (cadr e) (cddr e) r k))
((return-from) (evaluate-return-from (cadr e) (caddr e) r k))
...
}

◊noindent
Затем описываем обработку:

◊indexC{return-from-cont}
◊indexC{evaluate-return-from}
◊indexCS{resume}{◊ic{return-from-cont}}
◊indexC{block-lookup}
◊indexC{unwind}
◊indexCS{unwind}{◊ic{continuation}}
◊indexCS{unwind}{◊ic{bottom-cont}}
◊code:lisp{
(define-class return-from-cont continuation (r label))

(define (evaluate-return-from label form r k)
  (evaluate form r (make-return-from-cont k r label)) )

(define-method (resume (k return-from-cont) v)
  (block-lookup (return-from-cont-r k)
                (return-from-cont-label k)
                (return-from-cont-k k)
                v ) )

(define-generic (block-lookup (r) n k v)
  (wrong "Not an environment" r n k v) )

(define-method (block-lookup (r block-env) n k v)
  (if (eq? n (block-env-name r))
      (unwind k v (block-env-cont r))
      (block-lookup (block-env-others r) n k v) ) )

(define-method (block-lookup (r full-env) n k v)
  (block-lookup (variable-env-others r) n k v) )

(define-method (block-lookup (r null-env) n k v)
  (wrong "Unknown block label" n r k v) )

(define-generic (unwind (k) v ktarget))

(define-method (unwind (k continuation) v ktarget)
  (if (eq? k ktarget)
      (resume k v)
      (unwind (continuation-k k) v ktarget) ) )

(define-method (unwind (k bottom-cont) v ktarget)
  (wrong "Obsolete continuation" v) )
}

После вычисления необходимого значения функция ◊ic{block-lookup} отправляется
на поиски продолжения, связанного с~меткой ◊ic{tag} в~лексическом окружении
формы ◊ic{return-from}.
Если такое продолжение существует, то дальше с~помощью
◊ic{unwind} она убеждается в~том, что оно является частью текущего продолжения.

Поиск именованного блока, хранящего нужное продолжение, реализуется обобщённой
функцией ◊ic{block-lookup}.
Она обучена пропускать ненужные окружения с~обычными
переменными, останавливаясь только на экземплярах ◊ic{block-env}, хранящих
нужные нам ◊ic{block-cont}.
Аналогично и ◊ic{lookup} пропускает экземпляры
◊ic{block-env}, останавливаясь лишь на ◊ic{variable-env}.
Именно с~этой целью
данные классы наследуются от общего предка: ◊ic{full-env}.
Это позволяет
безболезненно добавлять новые классы окружений, которые не~будут мешать уже
существующим.

Наконец, обобщённая функция ◊ic{unwind} передаёт вычисленное значение найденному
продолжению, но только если оно ещё актуально~— то~есть доступно из текущего
продолжения.


◊subsection{◊texorpdfstring%
{Реализация ◊protect◊ic{unwind-protect}}%
{Реализация unwind-protect}}%
◊label{escape/implementation/ssect:unwind-protect}

◊indexCS{unwind-protect}{реализация}
Форма ◊ic{unwind-protect} является самой сложной для реализации; нам понадобится
изменить определения форм ◊ic{catch} и ◊ic{block}, чтобы они вели себя
правильно, когда находятся внутри ◊ic{unwind-protect}.
Это хороший пример
возможности, чьё введение требует переработки всего, что уже написано до этого.
Но отсутствие ◊ic{unwind-protect} приводит к~другим сложностям в~будущем, так
что оно того стоит.

Начнём с~определения поведения самой формы ◊ic{unwind-protect} (которая, как мы
уже говорили, мало чем отличается от~◊ic{prog1}):

◊indexC{unwind-protect-cont}
◊indexC{protect-return-cont}
◊indexC{evaluate-unwind-protect}
◊indexCS{resume}{◊ic{unwind-protect-cont}}
◊indexCS{resume}{◊ic{protect-return-cont}}
◊code:lisp{
(define-class unwind-protect-cont continuation (cleanup r))
(define-class protect-return-cont continuation (value))

(define (evaluate-unwind-protect form cleanup r k)
  (evaluate form r
            (make-unwind-protect-cont k cleanup r) ) )

(define-method (resume (k unwind-protect-cont) v)
  (evaluate-begin (unwind-protect-cont-cleanup k)
                  (unwind-protect-cont-r k)
                  (make-protect-return-cont
                   (unwind-protect-cont-k k) v ) ) )

(define-method (resume (k protect-return-cont) v)
  (resume (protect-return-cont-k k) (protect-return-cont-value k)) )
}

Далее необходимо доработать ◊ic{catch} и ◊ic{block}, чтобы они выполняли
действия, предписанные ◊ic{unwind-protect}, даже в~случае выхода из них
с~помощью ◊ic{throw} или ◊ic{return-from}.
Для ◊ic{catch} необходимо изменить
обработку ◊ic{throwing-cont}:

◊indexCS{resume}{◊ic{throwing-cont}}
◊code:lisp{
(define-method (resume (k throwing-cont) v)
  (unwind (throwing-cont-k k) v (throwing-cont-cont k)) )
}

◊noindent
И~научить ◊ic{unwind} выполнять сохранённые действия в~процессе обхода стека:

◊indexC{unwind-cont}
◊indexCS{unwind}{◊ic{unwind-protect-cont}}
◊indexCS{resume}{◊ic{unwind-cont}}
◊code:lisp{
(define-class unwind-cont continuation (value target))

(define-method (unwind (k unwind-protect-cont) v target)
  (evaluate-begin (unwind-protect-cont-cleanup k)
                  (unwind-protect-cont-r k)
                  (make-unwind-cont
                   (unwind-protect-cont-k k) v target ) ) )

(define-method (resume (k unwind-cont) v)
  (unwind (unwind-cont-k k)
          (unwind-cont-value k)
          (unwind-cont-target k) ) )
}

◊indexR{раскрутка стека (unwinding)}
Теперь, чтобы передать значение при переходе, нам недостаточно просто его отдать
нужному продолжению.
Нам необходимо подняться по стеку продолжений с~помощью
◊ic{unwind} (◊term{раскрутить} стек) от текущего до целевого продолжения,
выполняя по пути соответствующую уборку.
Продолжения форм-уборщиков имеют тип
◊ic{unwind-cont}.
Их обработка с~помощью ◊ic{resume} вызывает продолжение уборки
до достижения цели на~случай вложенных форм ◊ic{unwind-protect}, а также
устанавливает правильное продолжение на случай переходов внутри самих
форм-уборщиков (тот самый процесс отбрасывания продолжений, который
рассматривался на странице~◊pageref{escape/forms/protection/p:discard}).

Что касается ◊ic{block}, то тут даже делать ничего не~надо.
Как вы помните,
◊ic{block-lookup} уже вызывает ◊ic{unwind} для раскрутки стека с~целью проверки
актуальности перехода:

◊code:lisp{
(define-method (block-lookup (r block-env) n k v)
  (if (eq? n (block-env-name r))
      (unwind k v (block-env-cont r))
      (block-lookup (block-env-others r) n k v) ) )
}

◊noindent
Так что остаётся только сказать спасибо обобщённым функциям.

◊indexCS{block}{и~◊ic{unwind-protect}}
Может показаться, что с~появлением ◊ic{unwind-protect} форма ◊ic{block}
перестала быть быстрее ◊ic{catch}, ведь они обе вынуждены пользоваться медленной
◊ic{unwind}.
В~общем случае, конечно, да, но в~частностях, коих большинство, это
не~так: ◊ic{unwind-protect} является специальной формой, так что она не~может
быть спутана с~обычной функцией, её всегда надо использовать явно.
А~если
◊ic{return-from} прямо видит метку соответствующего~◊ic{block} (то~есть когда
между ними нет ◊ic{lambda}- или ◊ic{unwind-protect}-форм), то ◊ic{unwind} будет
работать так~же быстро, как и раньше.

◊bigskip

◊indexCS{unwind-protect}{ограничения ◊CommonLisp}
В~{◊CommonLisp} (CLtL2~◊cite{ste90}) присутствует ещё одно интересное
ограничение, касающееся переходов из форм-уборщиков.
Эти переходы не~могут вести
внутрь той формы, из которой в~теле ◊ic{unwind-protect} был вызван выход.
Введено такое ограничение с~целью недопущения бесконечных циклов из переходов,
любые попытки выбраться из которых пресекаются ◊ic{unwind-protect}.
◊seeEx[escape/ex:eternal] Следовательно, следующая программа выдаст ошибку, так
как форма-уборщик хочет прыгнуть ближе, чем прыжок на~◊ic{1}, который уже
в~процессе.

◊code:lisp{
(catch 1                  |◊dialect{◊CommonLisp}|
  (catch 2
    (unwind-protect (throw 1 'foo)
      (throw 2 'bar) ) ) )         |◊is| |◊ii{ошибка!}|
}


◊section{◊texorpdfstring%
{Сравнение ◊protect◊ic{call/cc}~и~◊protect◊ic{catch}}%
{Сравнение call/cc и catch}}%
◊label{escape/sect:comparing}

Благодаря объектам, продолжения можно представлять связным списком блоков.
Некоторые из этих блоков доступны прямо в~лексическом окружении; до других
необходимо пробираться, проходя через несколько промежуточных продолжений;
третьи вызывают выполнение определённых действий, когда через них проходят.

◊indexR{продолжения (continuations)!время жизни!динамическое}
В~языках вроде Лиспа, где есть продолжения с~динамическим временем жизни, стек
вызовов и продолжения являются синонимами.
Когда мы пишем ◊ic{(evaluate ec r
(make-if-cont k et ef r))}, мы явно кладём в~стек блок кода, который будет
обрабатывать значение, которое вернёт условие ◊ic{if}-формы.
И~наоборот, когда
мы пишем ◊ic{(evaluate-begin (cdr (begin-cont-e*~k)) (begin-cont-r~k)
(begin-cont-k~k))}, то это значит, что текущий блок~◊ic{k} надо выбросить и
поставить на его место ◊ic{(begin-cont-k k)}.
Можно легко убедиться в~том, что
такие блоки действительно выбрасываются, в~стеке не~остаются недовыполненные
куски продолжений.
Таким образом, когда мы выходим из блока, все продолжения,
указывающие на него и, возможно, сохранённые в~других блоках, становятся
недействительными.
Обычно продолжения неявно хранятся в~стеке или даже
в~нескольких стеках, согласованных между собой, а переходы между ними
компилируются в~примитивы языка~Си: ◊ic{setjmp}/◊ic{longjmp}.
◊seePage[cc/sect:call/cc]

◊indexC{let/cc}
В~диалекте {◊EuLisp}~◊cite{pe92} есть специальная форма ◊ic{let/cc} со~следующим
синтаксисом:

◊code:lisp{
(let/cc |◊ii{переменная}| |◊ii{формы}|...)  |◊dialect{◊EuLisp}|
}

◊phantomlabel{escape/comparing/par:bind-exit}
◊indexC{bind-exit}
В~диалекте Dylan~◊cite{app92b} тоже есть подобная форма:

◊code:lisp{
(bind-exit (|◊ii{переменная}|) |◊ii{формы}|...)  |◊dialect{Dylan}|
}

◊noindent
Эта форма связывает текущее продолжение с~◊ii{переменной}, имеющей область
видимости, ограниченную телом ◊ic{let/cc} или~◊ic{bind-exit}.
В~этом случае
продолжение несомненно является полноценным объектом, имеющим интерфейс унарной
функции.
Но его ◊emph{полезное} время жизни динамическое, его можно использовать
лишь во~время вычисления тела формы ◊ic{let/cc} или ◊ic{bind-exit}.
Точнее, само
продолжение, хранящееся в~◊ii{переменной}, имеет неограниченное время жизни, но
становится бесполезным при выходе из связывающей формы.
Это характерная для
{◊EuLisp} и Dylan черта, но её нет как в~Scheme (где продолжения истинно
неограниченны), так и в~{◊CommonLisp} (где они вообще объекты второго класса).
Тем не~менее, такое поведение можно проэмулировать в~Scheme:

◊code:lisp{
(define-syntax let/cc
  (syntax-rules ()
    ((let/cc variable . body)
     (block variable
       (let ((variable (lambda (x) (return-from variable x))))
         . body ) ) ) ) )
}

◊indexR{продолжения (continuations)!варианты представления}
В~мире Scheme продолжения больше нельзя считать неявной частью стека, так как
они могут храниться во~внешних структурах данных.
Поэтому приходится применять
другую модель: древовидную, которую иногда называют ◊term{стек-кактус} или
◊term{спагетти-стек}.
Наиболее простой способ её реализовать: вообще
не~пользоваться аппаратным стеком, размещая все фреймы в~куче.

Такой подход унифицирует выделение памяти под структуры данных и, по
мнению~◊cite{as94}, облегчает портирование.
Тем не~менее, он приводит
к~фрагментации, что вынуждает явно хранить ссылки между продолжениями.
(Хотя
в~◊cite{mb93} приведено несколько вариантов решения этих проблем.) Как правило,
ради эффективности в~аппаратный стек стараются поместить максимум данных о~ходе
исполнения программы, так что каноническая реализация ◊ic{call/cc} делает снимки
стека и сохраняет в~куче именно их; таким образом, продолжения~— это как раз
такие снимки стека.
Конечно, существуют и другие варианты реализации,
рассмотренные, например, в~◊cite{cho88, hdb90}, где используются разделяемые
копии, отложенное копирование, частичное копирование {◊itd} Естественно,
каждый из этих вариантов даёт свои преимущества, но за определённую плату.

Форма ◊ic{call/cc} больше похожа на ◊ic{block}, нежели на~◊ic{catch}.
Оба типа
продолжений имеют лексическую область видимости, они различаются только временем
жизни.
В~некоторых диалектах, вроде~◊cite{im89}, есть урезанный вариант
◊ic{call/cc}.
Называется он ◊ic{call/ep} (от ◊term{call with exit procedure});
эта ◊emph{процедура выхода} хорошо видна в~◊ic{block}/◊ic{return-from}, равно
как и в~◊ic{let/cc}.
Интерфейс у~◊ic{call/ep} такой~же, как и~у~◊ic{call/cc}:

◊indexC{call/ep}
◊code:lisp{
(call/ep (lambda (exit) ...))
}

◊indexR{объекты!второго класса}
Переменная ◊ic{exit} унарной функции-аргумента связывается с~продолжением формы
◊ic{call/ep} на время вычисления тела этой функции.
Схожесть с~◊ic{block}
налицо, разве что мы используем обычное окружение переменных, а не~отдельное
окружение лексических меток.
Основное их отличие в~том, что ◊ic{call/ep} делает
продолжение полноценным объектом, который можно использовать так~же, как любой
другой объект вроде чисел, замыканий или списков.
Имея ◊ic{block}, мы тоже можем
создать функционально аналогичный объект, написав ◊ic{(lambda (x) (return-from
◊ii{метка} x))}.
Но все возможные места выхода из ◊ic{block} известны статически
(это соответствующие формы ◊ic{return-from}), тогда как в~◊ic{call/ep} совсем
по-другому: например, по выражению ◊ic{(call/ep foo)} нельзя понять, может~ли
произойти переход или нет.
Единственный способ это узнать~— проанализировать
◊ic{foo}, но эта функция может быть определена в~совершенно другом месте, а то и
вовсе генерироваться динамически.
Следовательно, функция ◊ic{call/ep} более
сложна для компилятора, чем специальная форма ◊ic{block}, но вместе с~тем имеет
и~больше возможностей.

Продолжая сравнивать ◊ic{call/ep} и~◊ic{block}, мы замечаем больше отличий.
Например, для формы ◊ic{call/ep}, в~которой аргумент записан в~виде явной
◊ic{lambda}-формы, можно не~создавать замыкание.
Следовательно, эффективный
компилятор должен отделять случай ◊ic{(call/ep (lambda~...))} от остальных.
Это
похоже на специальные формы, так как они тоже трактуются по-особенному.
В~Scheme
принято использовать функции как основной инструмент построения абстракций,
тогда как специальные формы являются чем-то вроде подсказок компилятору.
Они
часто одинаково мощны, вопрос лишь в~балансе сложности~— кому важнее
облегчить жизнь: пользователю или, наоборот, разработчику языка.

◊bigskip

Подводя итог, если вам нужна мощь за адекватную цену, то ◊ic{call/cc} к~вашим
услугам, так как она позволяет реализовать все мыслимые управляющие конструкции:
переходы, сопрограммы, частичные продолжения и~так~далее.
Если~же вам нужны
только «нормальные» вещи (а~Лисп уже не~раз показывал, что можно писать
удивительные программы и~без~◊ic{call/cc}), то используйте управляющие формы
{◊CommonLisp}, простые и компилирующиеся в~эффективный машинный~код.


◊section[#:label "escape/sect:pr-cont"]{Продолжения в~программировании}

◊indexE{CPS}
◊indexR{стиль передачи продолжений (CPS)}
◊indexR{продолжения (continuations)|seealso{стиль передачи продолжений (CPS)}}
Существует стиль программирования, называемый «◊term{стилем передачи
продолжений}» (◊english{continuation passing style}, CPS).
В~нём во~главу угла
ставится явное указание не~только того, что возвращать в~качестве результата
функции, но и~кому.
После завершения вычислений функция не~возвращает результат
абстрактному получателю куда-то «наверх», а применяет конкретного получателя,
представленного продолжением, к~результату.
В~общем, если у~нас есть вычисление
◊ic{(foo (bar))}, то оно выворачивается наизнанку, преобразуясь в~следующий вид:
◊ic{(new-bar foo)}, где ◊ic{foo} и является продолжением, которому ◊ic{new-bar}
передаст результат вычислений.
Давайте рассмотрим данное преобразование
на~примере многострадального факториала.
Пусть мы хотим вычислить~◊${n(n!)}:

◊indexC{fact}
◊code:lisp{
(define (fact n k)
  (if (= n 0) (k 1)
      (fact (- n 1) (lambda (r) (k (* n r)))) ) )

(fact n (lambda (r) (* n r))) |◊is| |◊${n(n!)}|
}

Факториал теперь принимает дополнительный аргумент~◊ic{k}: получателя
вычисленного факториала.
Если результат равен единице, то к~ней просто
применяется~◊ic{k}.
Если~же результат сразу сказать нельзя, то следует ожидаемый
рекурсивный вызов.
Проблема состоит в~том, что хорошо было~бы сначала умножить
факториал~◊${(◊ic{n} - 1)} на~◊ic{n} и только потом уже передавать произведение
получателю, а форма ◊ic{(k (*~n (fact (-~n~1) k)))} делает всё наоборот! Поэтому
и мы всё сделаем шиворот-навыворот: пусть получатель сам умножает результат
на~◊ic{n}.
Настоящий получатель оборачивается в~функцию: ◊ic{(lambda (r) (k
(*~n~r)))}, и передаётся следующему рекурсивному вызову.

Такое определение факториала даёт возможность вычислять различные величины
с~помощью одного и того~же определения.
Например, обычный факториал: ◊ic{(fact
◊ii{n} (lambda (x) x))}, или удвоенный: ◊ic{(fact ◊ii{n} (lambda (x) (*~2~x)))},
или что-то более сложное.


◊subsection[#:label "escape/pr-cont/ssect:multiple"]{Составные значения}

◊indexR{возвращаемые значения!множественные}
◊indexR{множественные значения}
Продолжения очень удобно использовать для обработки составных величин.
Существуют вычисления, результатом которых является не~одна величина, а
несколько.
Например, в~{◊CommonLisp} целочисленное деление (◊ic{truncate})
одновременно возвращает частное и остаток.
Пусть у~нас тоже есть подобная
функция~— назовём её ◊ic{divide}, — которая принимает два числа и
продолжение, вычисляет частное и остаток от деления, а затем применяет
переданное продолжение к~этим величинам.
Например, вот так можно проверить
правильность выполнения деления этой функцией:

◊code:lisp{
(let* ((p (read)) (q (read)))
  (divide p q (lambda (quotient remainder)
                (= p (+ (* quotient q) remainder)) )) )
}

Менее тривиальный пример~— вычисление коэффициентов~Безу.◊footnote*{Фух!
Наконец-то мне удалось опубликовать эту функцию! Она с~1981~года валяется
у~меня без дела.} Соотношение Безу утверждает, что для любых целых чисел ◊${n}
и~◊${p} можно найти такую пару целых ◊${u} и~◊${v}, что ◊${un + vp = ◊NOD(n, p)}.
Для
вычисления коэффициентов ◊${u} и~◊${v} можно использовать расширенный алгоритм
Евклида.

◊indexC{bezout}
◊code:lisp{
(define (bezout n p k)  ; пусть ◊${n > p}
  (divide
   n p (lambda (q r)
         (if (= r 0)
             (k 0 1)    ; т.◊,к.
◊${0 ◊cdot qp + 1 ◊cdot p = p}
             (bezout
              p r (lambda (u v)
                    (k v (- u (* v q))) ) ) ) ) ) )
}

Функция ◊ic{bezout} использует ◊ic{divide}, чтобы сохранить в~◊ic{q} и~◊ic{r}
частное и остаток от деления ◊ic{n} на~◊ic{p}.
Если ◊${n} делится нацело на~◊${p},
то очевидно, что их наибольший общий делитель равен~◊${p} и есть тривиальное
решение: ◊${0}~и~◊${1}.
Если остаток не~равен нулю, то◊textdots◊ попробуйте доказать
правильность этого алгоритма самостоятельно; для этого не~надо быть экспертом
в~теории чисел, достаточно знать свойства~НОД.
А~здесь мы ограничимся простой
проверкой:

◊code:lisp{
(bezout 1991 1960 list) |◊is| (-569 578)
}


◊subsection[#:label "escape/pr-cont/ssect:tail-recusion"]{Хвостовая рекурсия}

В~примере с~вычислением факториала с~помощью продолжений вызов ◊ic{fact} в~конце
концов приводил к~ещё одному вызову ◊ic{fact}.
Если мы проследим за вычислением
◊ic{(fact~3~list)}, то, отбрасывая очевидные шаги, получим следующую картину:

◊code:lisp{
(fact 3 list)
|◊eq| (fact 2 (lambda (r) (k (* n r))))|◊begin{where}
                                        ◊- n {◊is} 3
                                        ◊- k {◊eq} list
                                        ◊end{where}|
|◊eq| (fact 1 (lambda (r) (k (* n r))))|◊begin{where}
                                ◊- n {◊is} 2
                                ◊- k {◊is} (lambda (r) (k (* n r)))◊begin{where}
                                                                  ◊- n {◊is} 3
                                                                  ◊- k {◊eq} list
                                                                  ◊end{where}
                                        ◊end{where}|
|◊eq| (k (* n 1))|◊begin{where}
                  ◊- n {◊is} 2
                  ◊- k {◊is} (lambda (r) (k (* n r)))◊begin{where}
                                                    ◊- n {◊is} 3
                                                    ◊- k {◊eq} list
                                                    ◊end{where}
                  ◊end{where}|
|◊eq| (k (* n 2))|◊begin{where}
                  ◊- n {◊is} 3
                  ◊- k {◊eq} list
                  ◊end{where}|
|◊is| (6)
}

◊indexR{рекурсия!хвостовая}
◊indexR{хвостовые вызовы!рекурсивные}
◊indexR{вызов!хвостовой}
Когда ◊ic{fact} вызывает ◊ic{fact}, вторая функция вычисляется с~тем~же
продолжением, что и первая.
Такое явление называется ◊term{хвостовой рекурсией}
— почему рекурсия, понятно, а хвостовая, потому что этот вызов выполняется
в~«хвосте» вычислений: сразу~же после него следует выход из функции.
Хвостовая
рекурсия~— это частный случай хвостового вызова.
Хвостовой вызов происходит
тогда, когда текущее вычисление может быть полностью заменено вызываемым.
То~есть вызов происходит из ◊term{хвостовой позиции}, если он выполняется
с~◊emph{неизменным продолжением}.

В~примере с~вычислением коэффициентов Безу функция ◊ic{bezout} вызывает
◊ic{divide} из хвостовой позиции.
Функция ◊ic{divide} вызывает своё продолжение
из хвостовой позиции.
Это продолжение рекурсивно вызывает ◊ic{bezout} опять-таки
из хвостовой позиции.

Но в~классическом факториале ◊ic{(*~n (fact (-~n~1)))} рекурсивный вызов
◊ic{fact} происходит не~из хвостовой позиции.
Он ◊emph{завёрнут} в~продолжение,
так как значение~◊ic{(fact (-~n~1))} ещё ожидается для умножения на~◊ic{n};
вызов тут не~является последней необходимой операцией, всё вычисление нельзя
свести к~нему.

Хвостовые вызовы позволяют отбрасывать ненужные окружения и фреймы стека, так
как при таких вызовах они больше никогда не~будут использоваться.
Следовательно,
их можно не~сохранять, экономя таким образом драгоценную стековую память.
Подобные оптимизации были детально изучены французским лисп-сообществом, что
позволило существенно ускорить интерпретацию ◊cite{gre77,cha80,sj87};
см.~также~◊cite{han90}.

◊bigskip

◊indexCS{evaluate-begin}{хвостовая рекурсия}
Оптимизация хвостовой рекурсии~— это очень желанное свойство интерпретатора;
не~только для пользователя, но и для самого интерпретатора.
Самое очевидное
место, где она была~бы полезной,~— это форма ◊ic{begin}.
До сих пор она
определялась следующим образом:

◊code:lisp{
(define (evaluate-begin e* r k)
  (if (pair? e)
      (if (pair? (cdr e*))
          (evaluate (car e*) r (make-begin-cont k e* r))
          (evaluate (car e*) r k) )
      (resume k empty-begin-value) ) )

(define-method (resume (k begin-cont) v)
  (evaluate-begin (cdr (begin-cont-e* k))
                  (begin-cont-r k)
                  (begin-cont-k k) ) )
}

Заметьте, здесь каждый вызов является хвостовым.
Также здесь используется одна
небольшая оптимизация.
Можно определить эту форму проще:

◊code:lisp{
(define (evaluate-begin e* r k)
  (if (pair? e*)
      (evaluate (car e*) r (make-begin-cont k e* r))
      (resume k empty-begin-value) ) )

(define-method (resume (k begin-cont) v)
  (let ((e* (cdr (begin-cond-e* k))))
    (if (pair? e*)
        (evaluate-begin e* (begin-cont-r k) (begin-cont-k k))
        (resume (begin-cont-k k) v) ) ) )
}

Но первый вариант предпочтительнее, так как в~этом случае при вычислении
последнего оставшегося выражения мы не~тратим время на создание лишнего
продолжения ◊ic{(make-begin-cont k e* r)}, которое фактически равно~◊ic{k}, а
сразу~же переходим в~нужное продолжение.
Конечно, в~Лиспе есть сборка мусора, но
это не~означает, что можно мусорить ненужными объектами на каждом шагу.
Это
небольшая, но важная оптимизация, ведь каждый ◊ic{begin} когда-нибудь
заканчивается!

◊indexCS{evaluate-arguments}{хвостовая рекурсия}
Аналогично можно оптимизировать и вычисление аргументов функции, переписав его
следующим образом:

◊code:lisp{
(define-class no-more-argument-cont continuation ())

(define (evaluate-arguments e* r k)
  (if (pair? e*)
      (if (pair? (cdr e*))
          (evaluate (car e*) r (make-argument-cont k e* r))
          (evaluate (car e*) r (make-no-more-argument-cont k)) )
      (resume k no-more-arguments) ) )

(define-method (resume (k make-no-more-argument-cont) v)
  (resume (no-more-argument-cont-k k) (list v)) )
}

Это новое продолжение, хранящее список из последнего вычисленного значения,
избавляет нас от необходимости передавать окружение~◊ic{r} целиком.
Данный приём
впервые использован Митчеллом~Уондом и Дэниелом~Фридманом в~◊cite{wan80b}.


◊section[#:label "escape/sect:partial"]{Частичные продолжения}

◊indexR{продолжения (continuations)!частичные продолжения}
Среди прочих вопросов, поднимаемых продолжениями, есть ещё один довольно
интересный: что именно случается с~отбрасываемым при переходе кодом? Другими
словами, с~тем куском продолжения (или~стека), который находится между
положениями до прыжка и после.
Мы говорили, что такой ◊term{срез} стека
не~сохраняется при переходе.
Но он вовсе не~является бесполезным: ведь если~бы
через него не~перешагнули, то он~бы принял какое-то значение, выполнил
определённые действия и передал~бы полученное значение своему продолжению.
То~есть вёл~бы себя как обычная функция.
Во~многих работах, вроде
◊cite{ffdm87,ff87,fel88,df90,hd90,qs91,mq94}, приводятся способы сохранения и
приёмы использования этих срезов~— ◊term{частичных продолжений}
(◊english{partial/delimited continuations}).

Рассмотрим следующий простой пример:

◊code:lisp{
(+ 1 (call/cc (lambda (k) (set! foo k) 2))) |◊is| 3
(foo 3)                                     |◊is| 4
}

◊noindent
Какое именно продолжение хранится в~◊ic{foo}? Казалось~бы ◊${◊lambda u . 1 + u},
но чему тогда равно ◊ic{(foo~(foo~4))}?

◊code:lisp{
(foo (foo 4))                               |◊is| 5
}

◊indexR{композициональность!продолжений}
◊indexR{продолжения (continuations)!композициональность}
Получается~◊ic{5}, а не~ожидаемое значение~◊ic{6}, которое~бы получилось при
правильной композиции функций.
Дело в~том, что вызов продолжения означает
отбрасывание всех последующих вычислений ради продолжения других вычислений.
Таким образом, вызов продолжения внутри ◊ic{foo} приводит к~вычислению значения
$◊lambda u.
1 + u◊${ при }u = 4$, которое становится значением всего выражения, и
второй вызов ◊ic{foo} вообще не~происходит~— он не~нужен, ведь значение
выражения уже вычислено и передано продолжению! Именно в~этом проблема: мы
захватили обычное продолжение, а не~частичное.
Обычные продолжения
◊term{активируются} и полностью заменяют стек собой, а ◊emph{не~вызываются}
как функции.

Возможно, так будет понятнее.
В~◊ic{foo} мы сохранили ◊ic{(+~1~[])}.
Это всё,
что ещё осталось вычислить.
Так как аргументы передаются по значению, то
вычисление аргумента-продолжения в~◊ic{(foo (foo 4))} фактически завершает
вычисления, отбрасывает ◊ic{(foo~[])} и возвращает значение формы ◊ic{(+~1~4)},
которое, очевидно, равно~◊ic{5}.

◊indexR{продолжения (continuations)!и интерактивная сессия}
◊indexR{интерактивная сессия (REPL)!продолжения}
◊indexE{REPL!продолжения}
Частичные продолжения представляют собой лишь часть оставшихся вычислений, тогда
как обычные продолжения~— это ◊emph{все} оставшиеся вычисления.
В~статьях ◊cite{fwfd88,df90,hd90,qs91} приводятся способы захвата частичных и,
следовательно, поддающихся композиции продолжений.
Предположим, теперь
с~◊ic{foo} связано продолжение ◊ic{[(+~1~[])]}, где внешние квадратные скобки
означают, что оно ведёт себя как функция.
Тогда ◊ic{(foo (foo~4))} будет
эквивалентно уже ◊ic{(foo [(+~1~[4])])}, что превращается в~◊ic{(+~1~5)},
которое в~итоге даёт~◊ic{6}.
Захваченное продолжение ◊ic{[(+~1~[])]} определяет
не~все последующие вычисления, которые когда-либо произойдут, а только их часть
вплоть до момента возврата значения.
Для интерактивной сессии продолжением
обычных продолжений является ◊term{главный цикл} (он~же ◊ic{toplevel}), именно
ему продолжения передают своё значение, а он выводит его на экран, читает
следующее выражение из входного потока, вычисляет его и~так~далее.
Продолжение
частичных продолжений неизвестно, именно поэтому они конечны и ведут себя как
обычные функции~— ведь функции тоже не~знают, кому они вернут значение.

Давайте взглянем на наш пример с~◊ic{(set! foo~k)} с~другой стороны.
Оставим всё
по-прежнему, но объединим эти два выражения в~явную последовательность:

◊code:lisp{
(begin (+ 1 (call/cc (lambda (k) (set! foo k) 2)))
       (foo 3) )
}

Бабах! Мы получили бесконечный цикл, так как ◊ic{foo} оказывается теперь
связанной с~◊ic{(begin (+~1~[]) (foo~3))}, что приводит к~рекурсии.
Как видим,
главный цикл~— это не~только последовательное вычисление выражений.
Если мы
хотим правильно его проэмулировать, то вдобавок необходимо изменять продолжение
каждого вычисляемого в~главном цикле выражения:

◊code:lisp{
(let (foo sequel print?)
  (define-syntax toplevel
    (syntax-rules ()
      ((toplevel e) (toplevel-eval (lambda () e))) ) )
  (define (toplevel-eval thunk)
    (call/cc (lambda (k)
               (set! print? #t)
               (set! sequel k)
               (let ((v (thunk)))
                 (when print? (display v) (set! print? #f))
                 (sequel v) ) )) )
  (toplevel (+ 1 (call/cc (lambda (k) (set! foo k) 2))))
  (toplevel (foo 3))
  (toplevel (foo (foo 4))) )
}

Каждый раз, когда мы хотим вычислить выражение с~помощью ◊ic{toplevel}, его
продолжение~— ◊emph{продолжение} работы ◊ic{toplevel} — сохраняется
в~переменной ◊ic{sequel}.
Любое продолжение, захватываемое внутри ◊ic{thunk},
теперь будет ограничено текущей вычисляемой формой.
Аналогичным образом применяя
присваивание, можно сохранить любой срез стека в~виде частичного продолжения.
Как видим, все продолжения с~неограниченным временем жизни для своего создания
требуют побочных эффектов.

◊indexR{присваивание!роль для продолжений}
Частичные продолжения явно указывают, когда необходимо остановить вычисления.
Этот эффект может быть полезен в~некоторых случаях, а также интересен сам по
себе.
Мы вполне можем даже переписать нашу ◊ic{call/cc} так, чтобы она
захватывала именно частичные продолжения вплоть до ◊ic{toplevel}.
Естественно,
кроме них потребуются также и переходы на тот случай, когда мы действительно
не~заинтересованы в~сохранении срезов стека.
Но, с~другой стороны, частичные
продолжения в~реальности используются довольно редко; сложно привести пример
программы, где частичные продолжения были~бы действительно полезны, но при этом
не~усложняли~бы её сильнее обычных.
Тем не~менее, они важны как ещё один пример
управляющей формы, которую можно реализовать на~Scheme с~помощью ◊ic{call/cc}
и~присваивания.


◊section[#:label "escape/sect:conclusions"]{Заключение}

Продолжения вездесущи.
Если вы понимаете продолжения, вы одновременно овладели
ещё одним стилем программирования, получили широчайшие возможности управления
ходом вычислений и знаете, во~что вам обойдётся это управление.
Продолжения
тесно связаны с~потоком исполнения, так как они динамически определяют всё, что
ещё осталось сделать.
Поэтому они так важны и полезны для обработки исключений.

Интерпретатор, определённый в~этой главе, довольно мощный, но легко понятный
только по частям.
Это обычное дело для объектно-ориентированного стиля: есть
много маленьких и простых кусочков, но не~так просто составить понимание цельной
картины того, как они работают вместе.
Интерпретатор модульный и легко
расширяется новыми возможностями.
Он не~особо быстрый, так как в~процессе работы
создаёт целую гору объектов, которые удаляются тут~же после использования.
Конечно, это является одной из задач компилятора: выяснить, какие из объектов
действительно стоит создавать и сохранять.


◊section[#:label "escape/sect:exercises"]{Упражнения}

◊begin{exercise}◊label{escape/ex:cc-cc}
Что вернёт ◊ic{(call/cc call/cc)}? Зависит~ли ответ от порядка вычислений?
◊end{exercise}


◊begin{exercise}◊label{escape/ex:cc-cc-cc-cc}
А~что вернёт ◊ic{((call/cc call/cc) (call/cc call/cc))}?
◊end{exercise}


◊begin{exercise}◊label{escape/ex:tagbody}
◊indexC{tagbody}◊indexC{go}
Реализуйте пару ◊ic{tagbody}/◊ic{go} с~помощью ◊ic{block}, ◊ic{catch} и
◊ic{labels}.
Напомним синтаксис этой формы из~{◊CommonLisp}:

◊code:lisp{
(tagbody
          |◊ii{выражения◊sub{0}}|...
  |◊hbox to 0pt{◊ii{метка◊sub{1}}}|        |◊ii{выражения◊sub{1}}|...
          ...
  |◊hbox to 0pt{◊ii{метка◊sub{i}}}|        |◊ii{выражения◊sub{i}}|...
          ...
)
}

Все ◊ii{выражения◊sub{i}} (и~только они) могут содержать безусловные переходы
◊ic{(go~◊ii{метка})} и возвраты ◊ic{(return~◊ii{значение})}.
Если ◊ic{return}
не~будет, то форма ◊ic{tagbody} возвращает~◊ic{nil}.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:arity-optimize}
Вы скорее всего заметили, что функции при вызове проверяют фактическую арность:
количество переданных им аргументов.
Измените механизм создания функций так,
чтобы правильная арность рассчитывалась только один раз.
Можете считать, что
функции бывают только фиксированной арности.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:apply}
Определите функцию ◊ic{apply} для интерпретатора из этой главы.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:dotted}
Реализуйте поддержку функций переменной арности для интерпретатора из этой
главы.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:evaluate}
Измените функцию запуска интерпретатора так, чтобы она вызывала ◊ic{evaluate}
только единожды.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:cc-value}
Способ реализации продолжений из
раздела~◊ref{escape/implementation/ssect:call/cc} отделяет продолжения от других
значений.
Поэтому мы вынуждены реализовывать метод ◊ic{invoke} лично для класса
продолжений, представляемых функциями языка определения.
Переопределите
◊ic{call/cc} так, чтобы она возвращала объекты определяемого языка, являющиеся
экземплярами класса-наследника ◊ic{value}, соответствующего продолжениям.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:eternal}
◊indexR{бесконечный цикл}
Напишите на {◊CommonLisp} функцию ◊ic{eternal-return}, принимающую замыкание и
вызывающую его в~бесконечном цикле.
Этот цикл должен быть истинно бесконечным:
перекройте абсолютно все выходы из него.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:crazy-cc}
Рассмотрим следующую хитроумную функцию (спасибо за неё Алану~Бодену):

◊indexR{коробки}
◊indexC{make-box}
◊code:lisp{
(define (make-box value)
  (let ((box
         (call/cc
          (lambda (exit)
            (letrec
             ((behavior
               (call/cc
                (lambda (store)
                  (exit (lambda (msg . new)
                          (call/cc
                           (lambda (caller)
                             (case msg
                               ((get) (store (cons (car behavior)
                                                   caller )))
                               ((set)
                                (store
                                 (cons (car new)
                                       caller ) ) ) ) ) ) )) ) ) ))
             ((cdr behavior) (car behavior)) ) ) ) ))
    (box 'set value)
    box ) )
}

Предположим, в~◊ic{box1} лежит значение ◊ic{(make-box~33)}, тогда что получится
в~результате следующих вычислений?

◊code:lisp{
(box1 'get)
(begin (box1 'set 44) (box1 'get))
}
◊end{exercise}


◊begin{exercise}◊label{escape/ex:generic-evaluate}
Среди всех наших функций только ◊ic{evaluate} не~является обобщённой.
Можно
создать класс программ, от которого будут наследоваться подклассы программ
с~различным синтаксисом.
Правда, в~этом случае мы не~сможем хранить программы
как S-выражения, они должны быть объектами.
Соответственно, функция
◊ic{evaluate} уже должна быть обобщённой.
Это позволит легко вводить новые
специальные формы (возможно, даже прямо из определяемого языка).
Воплотите эту
идею в~жизнь.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:throw}
Реализуйте оператор ◊ic{throw} как функцию, а не~специальную форму.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:cps-speed}
Сравните скорость выполнения обычного кода и переписанного в~стиле передачи
продолжений.
◊end{exercise}


◊begin{exercise}◊label{escape/ex:the-current-cc}
◊indexC{the-current-continuation}
Реализуйте ◊ic{call/cc} с~помощью функции ◊ic{the-current-continuation}, которая
определяется следующим образом:

◊code:lisp{
(define (the-current-continuation)
  (call/cc (lambda (k) k)) )
}
◊end{exercise}


◊section*[#:label "escape/sect:recommended-reading"]{Рекомендуемая литература}

Годный, нетривиальный пример использования продолжений приведён в
◊cite{wan80a}.
Также стоит почитать~◊cite{hfw84} об~эмуляции сопрограмм.
В~◊cite{dr87} прекрасно рассказано о~развитии понимания важности рефлексии
для управляющих форм.
