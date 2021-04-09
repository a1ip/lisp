◊subsubsection{Улучшенное окружение}

Хорошо, попробуем улучшить наше определение следующим образом:

◊begin{code:lisp}
(define (make-function variables body env)
  (lambda (values)
    (eprogn body (extend |◊ii{env.global}| variables values)) ) )
◊end{code:lisp}

Замечательно, теперь наши функции имеют доступ к~глобальному окружению и всем
его функциям. А~что если мы попробуем определить взаимно рекурсивные функции?
Также, какой результат даст программа слева (справа она~же с~раскрытыми
макросами)?

{◊def◊E{◊hbox to 0pt{◊kern0.3em$◊equals$}}
◊begin{code:lisp}
(let ((a 1))            ((lambda (a)
  (let ((b (+ 2 a)))       ((lambda (b)
    (list a b) ) )   |◊E|         (list a b) )
                            (+ 2 a) ) )
                         1 )
◊end{code:lisp}}

Давайте рассмотрим по шагам, как вычисляется это выражение:

◊begin{code:lisp}
((lambda (a) ((lambda (b) (list a b)) (+ 2 a))) 1)|◊begin{where}
                                                   ◊- ◊ii{env.global}
                                                   ◊end{where}|
|◊equals| ((lambda (b) (list a b)) (+ 2 a))|◊begin{where}
                                            ◊- a {◊is} 1
                                            ◊- ◊ii{env.global}
                                            ◊end{where}|
|◊equals| (list a b)|◊begin{where}
                     ◊- b {◊is} 3
                     ◊- ◊ii{env.global}
                     ◊end{where}|
◊end{code:lisp}

Тело внутренней функции ◊ic{(lambda (b) (list a~b))} выполняется в~окружении,
полученном расширением глобального окружения переменной~◊ic{b}. Всё верно. Но
в~этом окружении нет необходимой переменной~◊ic{a}!


◊subsubsection{Улучшенное окружение (вторая~попытка)}

Так как нам надо видеть переменную~◊ic{a} во~внутренней функции, то достаточно
будет передать ◊ic{invoke} текущее окружение, а она в~свою очередь передаст его
вызываемой функции. Чтобы реализовать эту идею, надо немного подправить
◊ic{evaluate} и ◊ic{invoke}; чтобы не~путать эти определения с~предыдущими,
пусть они начинаются на~◊ic{d.}:

◊indexC{d.evaluate}
◊indexC{d.invoke}
◊indexC{d.make-function}
◊begin{code:lisp}
(define (d.evaluate e env)
  (if (atom? e) ...
      (case (car e)
        ...
        ((lambda) (d.make-function (cadr e) (cddr e) env))
        (else     (d.invoke (d.evaluate (car e) env)
                            (evlis (cdr e) env)
                            env )) ) ) )

(define (d.invoke fn args env)
  (if (procedure? fn)
      (fn args env)
      (wrong "Not a function" fn) ) )

(define (d.make-function variables body |◊ii{def.env}|)
  (lambda (values |◊ii{current.env}|)
    (eprogn body (extend |◊ii{current.env}| variables values)) ) )
◊end{code:lisp}

В~этом определении стоит заметить, что передача окружения определения ◊ic{env}
через переменную~◊ii{def.env} бессмысленна, так как при вызове используется лишь
текущее окружение ◊ii{current.env}.

◊indexR{стек!вызовов}
Давайте теперь ещё раз рассмотрим пример, приведённый выше. Сейчас переменные
не~пропадают:

◊begin{code:lisp}
((lambda (a) ((lambda (b) (list a b)) (+ 2 a))) 1)|◊begin{where}
                                                   ◊- ◊ii{env.global}
                                                   ◊end{where}|
|◊equals| ((lambda (b) (list a b)) (+ 2 a))|◊begin{where}
                                            ◊- a {◊is} 1
                                            ◊- ◊ii{env.global}
                                            ◊end{where}|
|◊equals| (list a b)|◊begin{where}
                     ◊- b {◊is} 3
                     ◊- a {◊is} 1
                     ◊- ◊ii{env.global}
                     ◊end{where}|
◊end{code:lisp}

Заодно мы явно видим ◊emph{стек вызовов}: каждая связывающая форма сначала
укладывает свои новые переменные поверх текущего окружения, а потом убирает их
оттуда после окончания вычислений.


◊subsubsection{Исправляем проблему}

Но даже при таком определении всё ещё есть проблемы. Рассмотрим следующий
пример:

◊begin{code:lisp}
(((lambda (a)
     (lambda (b) (list a b)) )
  1 )
 2 )
◊end{code:lisp}

Функция~◊ic{(lambda (b) (list a~b))} создаётся в~окружении, где ◊ic{a} связана
со~значением~◊ic{1}, но в~момент вызова в~окружении будет присутствовать
только~◊ic{b}. Таким образом, мы опять потеряли переменную~◊ic{a}.

Без сомнения, вы заметили, что в~определении ◊ic{d.make-function} присутствуют
два окружения: окружение определения ◊ii{def.env} и окружение исполнения
◊ii{current.env}. В~жизни функции есть два важных события: её создание и
её~вызов(ы). Очевидно, что создаётся функция только однажды, а вызываться может
несколько раз; или вообще никогда не~вызываться. Следовательно,
единственное◊footnote{На~самом деле, здесь можно использовать любое необходимое
окружение. См.~про форму~◊ic{closure} на
странице~◊pageref{assignement/assignement/para:closure}.} окружение, которое мы
однозначно можем связать с~функцией, — это окружение, в~котором она была
создана. Вернёмся к~исходным определениям функций ◊ic{evaluate} и ◊ic{invoke},
но в~этот раз функцию~◊ic{make-function} запишем следующим образом:

◊indexC{make-function}
◊begin{code:lisp}[label=basics/representing-functions/fixing/src:inject-current-env]
(define (make-function variables body |◊ii{env}|)
  (lambda (values)
    (eprogn body (extend |◊ii{env}| variables values)) ) )
◊end{code:lisp}

Теперь все приведённые примеры работают нормально. В~частности, пример выше
вычисляется следующим образом:

◊begin{code:lisp}
(((lambda (a) (lambda (b) (list a b))) 1) 2)|◊begin{where}
                                             ◊- ◊ii{env.global}
                                             ◊end{where}|
|◊equals| ((lambda (b) (list a b))|◊begin{where}
                                   ◊- a {◊is} 1
                                   ◊- ◊ii{env.global}
                                   ◊end{where}|
    2 )|◊begin{where}
        ◊- ◊ii{env.global}
        ◊end{where}|
|◊equals| (list a b)|◊begin{where}
                     ◊- b {◊is} 2
                     ◊- a {◊is} 1
                     ◊- ◊ii{env.global}
                     ◊end{where}|
◊end{code:lisp}

◊indexR{абстракция!замыкание}
◊indexR{абстракция!значение}
◊indexR{возвращаемые значения!абстракций}
◊indexR{замыкания (closures)}
Форма ◊ic{(lambda (b) (list a~b))} создаётся в~глобальном окружении, расширенном
переменной~◊ic{a}. Когда эта функция вызывается, она расширяет окружение своего
создания переменной~◊ic{b}, таким образом, тело функции будет вычисляться
в~окружении, где обе переменные ◊ic{a} и~◊ic{b} присутствуют. После того, как
функция вернёт результат, исполнение продолжается в~глобальном окружении. Мы
будем называть значение абстракции ◊term{замыканием} (closure), потому что при
создании этого значения тело функции становится замкнутым в~окружении своего
определения.

Стоит отметить, что сейчас ◊ic{make-function} сама использует замыкания языка
определения. Это не~является обязательным, как мы покажем далее в~третьей главе.
◊seePage[escape/actors/ssect:functions] Функция~◊ic{make-function} возвращает
замыкания, а это — характерная черта функциональных языков программирования.


◊subsection{Динамическая и~лексическая области~видимости}%
◊label{basics/representing-functions/ssect:dynamic-and-lexical-binding}

Из~этого разговора об~окружениях можно сделать два вывода. Во-первых, ясно,
что с~окружениями не~всё так просто. Любое вычисление всегда производится
в~каком"~то окружении, следовательно, необходимо эффективно реализовывать их
использование. В~третьей главе рассматриваются более сложные вещи вроде
раскрутки стека и соответствующей формы~◊ic{unwind-protect}, которые потребуют
от нас ещё более точного контроля над окружениями.

◊indexR{лексическое связывание}◊indexR{динамическое связывание}
◊indexR{связывание!лексическое}◊indexR{связывание!динамическое}
◊indexR{Лисп!лексический}◊indexR{Лисп!динамический}
Второй момент связан с~двумя рассмотренными в~предыдущем разделе вариантами,
которые являются примерами ◊term{лексического} и ◊term{динамического
связывания}◊footnote{В~объектно"=ориентированных языках под динамическим
связыванием обычно понимается механизм выбора метода объекта на основе его
реального типа во~время исполнения программы, в~противоположность статическому
связыванию, при котором метод выбирается компилятором исходя из типа переменной,
которая хранит рассматриваемый объект.} (также применяются термины лексическая и
динамическая область видимости). В~◊emph{лексическом} Лиспе функция выполняется
в~окружении своего определения, расширенном собственными переменными, тогда как
в~◊emph{динамическом} — расширяет текущее окружение, окружение своего вызова.

Сейчас в~моде лексическое связывание, но это не~значит, что у~динамического нет
будущего. С~одной стороны, именно динамическое связывание применяется
в~некоторых довольно популярных языках вроде ◊TeX~◊cite{knu84},
Emacs~Lisp◊trnote{Начиная с~Emacs~Lisp v.◊,24 и Perl~5, эти языки имеют и
лексические переменные.}~◊cite{llst93}, Perl~◊cite{ws91}.

С~другой стороны, сама идея динамической области видимости является важной
концепцией программирования. Она соответствует установке связей перед
выполнением вычислений и гарантированному автоматическому удалению этих связей
после завершения вычислений.

◊indexR{исключения}
◊indexR{поиск с возвратом}
Такую стратегию можно эффективно применять, например, в~искусственном
интеллекте. В~этом случае сначала выдвигается некая гипотеза, затем из неё
вырабатываются следствия. Как только система натыкается на противоречие, то
гипотезу следует отвергнуть и перейти к~следующей. Это называется ◊term{поиском
с~возвратом}. Если следствия гипотез хранятся без использования побочных
эффектов, например, в~А-списках, то отвержение гипотезы автоматически и без
проблем утилизирует и все её следствия. Но если для этого используются
глобальные переменные, массивы {◊itd}, то тогда за ненужной гипотезой
приходится долго убирать, вспоминая, каким~же было состояние памяти в~момент
формулировки гипотезы и какие его части можно откатить до старых значений, чтобы
ничего не~сломать! Динамическая область видимости позволяет гарантировать
существование переменной с~определённым значением на~время и только во~время
вычислений, независимо от того, будут они успешны или нет. Это свойство также
широко используется при обработке исключений.

◊indexR{область видимости}
◊term{Область видимости} переменной — это, можно сказать, географическое
понятие в~программе: местность, где переменная встречается и её можно
использовать. В~чистом Scheme (не~обременённом полезными, но не~абсолютно
необходимыми вещами вроде~◊ic{let}) есть только одна связывающая форма:
◊ic{lambda}. Это единственная форма, вводящая новые переменные и предоставляющая
им область видимости в~рамках определяемой функции. В~динамическом~же Лиспе
область видимости в~принципе не~может быть ограничена функцией. Рассмотрим
следующий пример:

◊begin{code:lisp}
(define (foo x) (list x y))
(define (bar y) (foo 1991))
◊end{code:lisp}

В~лексическом Лиспе переменная~◊ic{y} в~◊ic{foo}◊footnote{О~происхождении
◊emph{foo} см.~◊cite{ray91}.} — это всегда ссылка на глобальную
переменную~◊ic{y}, которая не~имеет никакого отношения к~◊ic{y} внутри~◊ic{bar}.
В~динамическом~же Лиспе переменная~◊ic{y} из ◊ic{bar} будет видима в~◊ic{foo}
внутри ◊ic{bar}, потому что в~момент вызова ◊ic{foo} переменная~◊ic{y} уже
находилась в~текущем окружении. Следовательно, если мы дадим глобальной ◊ic{y}
значение~◊ic{0}, то получим следующие результаты:

◊begin{code:lisp}
(define y 0)
(list (bar 100) (foo 3)) |◊is| ((1991 0) (3 0))   ; в~лексическом Лиспе
(list (bar 100) (foo 3)) |◊is| ((1991 100) (3 0)) ; в~динамическом Лиспе
◊end{code:lisp}

◊indexR{свободные переменные!и области видимости}
Заметьте, что в~динамическом Лиспе ◊ic{bar} понятия не~имеет о~том, что
в~◊ic{foo} используется её~же локальная переменная~◊ic{y}, а~◊ic{foo} не~знает
о~том, в~каком именно окружении следует искать значение своей свободной
переменной~◊ic{y}. Просто ◊ic{bar} при вызове положила в~текущее окружение
переменную~◊ic{y}, а внутренняя функция ◊ic{foo} нашла её в~своём
текущем окружении. Непосредственно перед выходом ◊ic{bar} уберёт свою~◊ic{y} из
окружения, и глобальная переменная~◊ic{y} снова станет видна.

Конечно, если не~использовать свободные переменные, то нет особой разницы между
динамической и лексической областями видимости.

Лексическое связывание получило своё имя потому, что в~данном случае достаточно
иметь только код функции, чтобы с~уверенностью отнести каждую используемую в~ней
переменную к~одному из двух классов: или переменная находится внутри связывающей
формы и является локальной, или~же это глобальная переменная. Это чрезвычайно
просто: достаточно взять исходный код, взять карандаш (или мышку) и поставить
его кончик на переменную, значение которой нас интересует, после чего следует
вести карандаш справа налево, снизу вверх до тех пор, пока не~встретим первую
связывающую форму. Динамическое~же связывание названо в~честь концепции
◊term{динамического времени жизни} переменных, которую мы будем рассматривать
позже. ◊seePage[escape/forms/ssect:dynamic]

Scheme поддерживает только лексические переменные. {◊CommonLisp} поддерживает
оба типа с~одинаковым синтаксисом. Синтаксис {◊EuLisp} и {◊ISLisp} разделяет эти
два типа переменных, и они находятся в~отдельных пространствах имён.
◊seePage[lisp1-2-omega/sect:namespaces]

◊indexR{область видимости!конфликт имён}
◊indexR{переменные!сокрытие имён}
◊indexR{сокрытие переменных}
◊indexR{сокрытие переменных|seealso{области видимости}}
Область видимости переменной может прерываться. Такое случается, когда одна
переменная ◊term{скрывает} другую из"~за того, что обе имеют одинаковое имя.
Лексические области видимости вкладываются друг в~друга, скрывая переменные
с~совпадающими именами из внешних областей. Этот известный «блокирующий»
порядок разрешения конфликтов унаследован от Алгола~60.

Под влиянием $◊lambda$"=исчисления, в~честь которого названа специальная
форма ◊ic{lambda}~◊cite{per79}, ◊LISP~1.0 был сделан динамическим, но вскоре
Джон~Маккарти осознал, что он ожидал получить от следующего выражения
◊ic{(2~3)}, а не~◊ic{(1~3)}:

◊begin{code:lisp}
(let ((a 1))
  ((let ((a 2)) (lambda (b) (list a b)))
   3 ) )
◊end{code:lisp}

◊indexCS{function}{для замыканий}
◊indexCS{lambda}{как ключевое слово}
Эта аномалия (не~осмелюсь назвать её ошибкой) была исправлена введением новой
специальной формы~◊ic{function}. Она принимала ◊ic{lambda}-форму и создавала
◊term{замыкание} — функцию, связанную с~окружением, в~котором она определена.
При вызове замыкания вместо текущего окружения расширялось окружение
определения, замкнутое внутри него. Вместе с~изменениями ◊ic{d.evaluate} и
◊ic{d.invoke}, форма~◊ic{function}◊footnote{Наша имитация не~совсем точна, так
как существует немало диалектов Лиспа (вроде CLtL1~◊cite{ste84}), где
◊ic{lambda} — это не~специальный оператор, а только ключевое слово-маркер
вроде ◊ic{else} внутри ◊ic{cond} и ◊ic{case}. В~этом случае ◊ic{d.evaluate}
может вообще не~знать ни~о~какой ◊ic{lambda}. Иногда даже накладываются
ограничения на положение ◊ic{lambda}-форм, разрешающие им находиться только
внутри ◊ic{function} и в~определениях функций.} выражается так:

◊indexC{d.invoke}◊indexC{d.make-function}◊indexC{d.make-closure}
◊begin{code:lisp}[label=basics/repr-func/dyn-and-lex-bind/src:closure-eval]
(define (d.evaluate e env)
  (if (atom? e) ...
      (case (car e)
        ...
        ((function)   ; Синтаксис: ◊ic{(function (lambda ◊ii{аргументы} ◊ii{тело}))}
         (let* ((f   (cadr e))
                (fun (d.make-function (cadr f) (cddr f) env)) )
           (d.make-closure fun env) ) )
        ((lambda) (d.make-function (cadr e) (cddr e) env))
        (else     (d.invoke (d.evaluate (car e) env)
                            (evlis (cdr e) env)
                            env )) ) ) )

(define (d.invoke fn args env)
  (if (procedure? fn)
      (fn args env)
      (wrong "Not a function" fn) ) )

(define (d.make-function variables body env)
  (lambda (values current.env)
    (eprogn body (extend current.env variables values)) ) )

(define (d.make-closure fun env)
  (lambda (values current.env)
    (fun values env) ) )
◊end{code:lisp}

◊indexR{переменные!специальные}
◊indexC{special}
Но это ещё не~конец всей истории. ◊ic{function} — это лишь костыль, на
который опиралась хромая реализация Лиспа. С~созданием первых компиляторов стало
ясно, что с~точки зрения производительности у~лексической области видимости есть
(ожидаемое при компиляции) преимущество: можно сгенерировать код для более-менее
прямого доступа к~любой переменной, а не~динамически отыскивать её значение
заново каждый раз. Тогда по умолчанию стали делать все переменные лексическими,
за исключением тех, которые были явно помечены как динамические или, как тогда
их называли, ◊term{специальные}. Выражение ◊ic{(declare (special~◊ii{x}))}
являлось командой компиляторам ◊LISP~1.5, ◊CommonLisp, Maclisp и~других,
говорившей, что переменная~◊ii{x} ведёт себя «особенно».

◊indexR{ссылочная прозрачность}
Эффективность была не~единственной причиной принятия такого решения. Другой
причиной была потеря ◊term{ссылочной прозрачности} (◊english{referential
transparency}). Ссылочная прозрачность — это свойство языка, заключающееся
в том, что замена в~программе любого выражения его эквивалентом никак не~изменит
поведение этой программы (оба варианта программы или вернут одно и то~же
значение, или вместе застрянут в~бесконечном цикле). Например:

◊begin{code:lisp}
(let ((x (lambda () 1))) (x)) |◊eq| ((let ((x (lambda () 1))) x)) |◊eq| 1
◊end{code:lisp}

В~общем случае ссылочная прозрачность теряется, если язык позволяет побочные
эффекты. Чтобы она сохранилась и при наличии побочных эффектов, необходимо
точнее определить понятие эквивалентных выражений. Scheme обладает ссылочной
прозрачностью, если не~использовать присваивания, функции с~побочными эффектами
и продолжения. ◊seeEx[escape/ex:crazy-cc] Это свойство желаемо и в~наших
программах, если мы хотим сделать их по-настоящему повторно используемыми, как
можно менее зависимыми от контекста использования.

◊indexR{переменные!безымянные}
◊indexR{альфа@$◊alpha$-конверсия}
Локальные переменные функций вроде ◊ic{(lambda (u) (+~u~u))} иногда называются
◊emph{безымянными}. Их имена ничего не~значат и могут быть абсолютно
произвольными. Функция ◊ic{(lambda (n347) (+~n347~n347))} — это та~же
самая◊footnote{В~терминах $◊lambda$"=исчисления подобная замена имён называется
$◊alpha$"=конверсией.} функция, что и ◊ic{(lambda (u) (+~u~u))}.

Мы ожидаем, что в~языке будет сохраняться этот инвариант. Но это невозможно
в~динамическом Лиспе. Рассмотрим следующий пример:

◊indexC{map}
◊begin{code:lisp}
(define (map fn l)  ; или ◊ic{mapcar}, как кому нравится
  (if (pair? l)
      (cons (fn (car l)) (map fn (cdr l)))
      '() ) )

(let ((l '(a b c)))
  (map (lambda (x) (list-ref l x))
       '(2 1 0)))
◊end{code:lisp}

(Функция~◊ic{(list-ref $◊ell$ ◊ii{n})} возвращает ◊ii{n}"~й~элемент
списка~$◊ell$.)

В~Scheme мы~бы получили ◊ic{(c b a)}, но в~динамическом Лиспе результатом будет
◊ic{(0 0 0)}! Причина: свободная переменная~◊ic{l} в~функции ◊ic{(lambda (x)
(list-ref l x))}, имя которой уже занято локальной переменной~◊ic{l}
в~◊ic{map}.

Это затруднение можно решить, просто изменив конфликтующие имена. Например,
достаточно будет переименовать какую-нибудь из двух~◊ic{l}. Например, ту,
которая внутри ◊ic{map}, потому что это более разумно. Но какое имя выбрать,
чтобы эта проблема не~возникла снова? Если приписывать спереди к~имени каждой
переменной номер паспорта программиста, а сзади — текущее ◊UNIX-время, то
это, конечно, значительно снизит вероятность коллизий, но читабельность программ
будет оставлять желать лучшего.

В~начале восьмидесятых годов сложилась довольно неприятная ситуация: студентов
учили Лиспу на примере интерпретаторов, но их понимание областей видимости
отличалось от понимания компиляторов. В~1975~году Scheme ◊cite{ss75} показал,
что интерпретатор и компилятор возможно примирить, поместив обоих в~мир, где все
переменные лексические. {◊CommonLisp} забил последний гвоздь в~гроб этой
проблемы, постановив, что ◊emph{хорошее} понимание — это понимание
компилятора, а для него удобнее лексические переменные. Интерпретатор должен
был подчиниться новым правилам. Растущий успех Scheme и других функциональных
языков, вроде~ML и компании, популяризовал новый подход сначала в~языках
программирования, а затем и в~умах людей.


◊subsection{Дальнее~и~ближнее связывание}%
◊label{basics/representing-functions/ssect:deep-or-shallow}

◊indexR{дальнее (deep) связывание}
◊indexR{связывание!дальнее (deep)}
◊indexCS{lookup}{стоимость}
Но не~всё так просто заканчивается. Разработчики языков нашли способы ускорить
поиск значений динамических переменных. Если окружения представлены
ассоциативными списками, то время на поиск значения переменной (стоимость вызова
◊ic{lookup}) линейно зависит от длины списка.◊footnote*{К~счастью, статистика
показывает, что переменные, располагающиеся ближе к~началу списка, используются
чаще тех, что находятся глубоко внутри. Кстати, ещё стоит отметить, что
лексические окружения в~среднем меньше по размеру, чем динамические, так как
последним необходимо хранить все переменные, участвующие в~вычислениях, включая
одноимённые ◊cite{bak92a}.} Такой подход называется ◊term{глубоким} или
◊term{дальним связыванием} (deep binding), так как значения динамических
переменных обычно располагаются на некотором удалении от текущего локального
окружения.

◊indexR{ближнее (shallow) связывание}
◊indexR{связывание!ближнее (shallow)}
◊indexE{Cval}
Существует и другой метод, называемый ◊term{поверхностным} или ◊term{ближним
связыванием} (shallow binding). Суть его в~том, что переменная напрямую связана
с~местом, где хранится её значение в~текущий момент, без привязки к~окружению.
Проще всего это реализовать, положив это значение в~специальное поле символа,
соответствующего этой переменной; это поле называют ◊ic{Cval} или ◊term{ячейкой
значения} (value cell). В~таком случае стоимость ◊ic{lookup} постоянна или около
того: требуется лишь одна косвенная адресация и, может быть, сдвиг. Так как
бесплатный сыр бывает только в~мышеловке, то стоит отметить, что вызов функции
при использовании этого метода выходит дороже, потому что требуется сначала
где"~то сохранить старые значения аргументов, затем записать новые значения
в~поля соответствующих символов. А~потом, что самое важное, после выхода из
функции старые значения в~символах необходимо восстановить обратно, а это может
помешать оптимизации хвостовой рекурсии. (Хотя есть варианты: ◊cite{sj93}.)

Изменив структуру окружений, мы сможем частично проэмулировать◊footnote{Здесь мы
не~реализуем присваивание переменным, захваченным замыканиями. Об~этом можно
почитать в~◊cite{bcsj86}.} ближнее связывание. Но с~оговорками: список
аргументов не~может быть точечным (так будет легче его разбирать) и мы не~будем
проверять арность функций. Новые функции будем обозначать префиксом ◊ic{s.},
чтобы не~путать их с~другими.

◊indexC{s.make-function}
◊indexC{s.lookup}
◊indexC{s.update"!}
◊begin{code:lisp}
(define (s.make-function variables body env)
  (lambda (values current.env)
    (let ((old-bindings
           (map (lambda (var val)
                  (let ((old-value (getprop var 'apval)))
                    (putprop var 'apval val)
                    (cons var old-value) ) )
                variables
                values ) ))
      (let ((result (eprogn body current.env)))
        (for-each (lambda (b) (putprop (car b) 'apval (cdr b)))
                  old-bindings )
        result ) ) ) )

(define (s.lookup id env)
  (getprop id 'apval) )

(define (s.update! id env value)
  (putprop id 'apval value) )
◊end{code:lisp}

◊indexC{putprop}◊indexC{getprop}
В~Scheme функции ◊ic{putprop} и ◊ic{getprop} не~входят в~стандарт, так как здесь
не~любят неэффективные глобальные побочные эффекты, но тем не~менее, даже
в~◊cite{as85} есть аналогичные ◊ic{put} и~◊ic{get}.
◊seeEx[lisp1-2-omega/ex:write-put/get-prop]

◊indexR{списки свойств}
◊indexR{символы!списки свойств}
◊indexE{P-список}
◊indexR{хеш-таблицы}
С~помощью этих функций мы эмулируем наличие у~символов поля,◊footnote*{Это поле
названо в~честь ◊ic{apval} из~◊cite{mae+62}. ◊seePage[lisp1-2-omega/par:apval]
Тогда значения полей действительно хранились в~наивных P"~списках.} где хранится
значение одноимённой переменной. Независимо от их настоящей реализации,%
◊footnote*{Эти функции проходят по списку свойств символа (его P"~списку,
от~property) до тех пор, пока не~найдут нужное. Скорость поиска, соответственно,
линейно зависит от длины списка, если только не~применяются хеш-таблицы.} будем
считать, что они выполняются за постоянное время.

Заметьте, что в~этой реализации абсолютно не~используется окружение определения
◊ic{env}. Поэтому для поддержки замыканий нам потребуется изменить реализацию
◊ic{make-closure}, так как она теперь не~имеет доступа к~окружению определения
(ввиду его отсутствия). При создании замыкания необходимо просмотреть тело
функции, выделить все свободные переменные и правильно их сохранить внутри
замыкания. Мы реализуем это позже.

◊indexE{rerooting}
Дальнее связывание облегчает смену окружений и многозадачность, теряя в~скорости
поиска переменных. Ближнее связывание ускоряет поиск переменных, но теряет
в~скорости вызова функций. Генри~Бейкеру ◊cite{bak78} удалось объединить эти два
подхода в~технику под названием ◊term{rerooting}.

Наконец, не~забывайте, что ближнее и дальнее связывание — это лишь способы
реализации, они никак не~влияют на само понятие связывания.


◊section{Глобальное окружение}◊label{basics/sect:global-environment}

◊indexR{библиотека!функций}
◊indexR{Лисп!примитивы}
Пустое глобальное окружение — это печально, поэтому большинство лисп-систем
предоставляют ◊emph{библиотеки} функций. Например, в~глобальном окружении
{◊CommonLisp} (CLtL1) около 700~функций, у~{◊LeLisp} их более~1500,
у~{◊ZetaLisp} — более~10◊,000. Без библиотек Лисп был~бы лишь прикладным
$◊lambda$"=исчислением, в~котором нельзя даже распечатать полученные результаты.
Библиотеки очень важны для конечного пользователя. Специальные формы — это
строительные кирпичики для разработчиков интерпретаторов, но для конечного
пользователя такими кирпичиками являются функции библиотек. По"~видимому, именно
отсутствие в~чистом Лиспе таких банальных вещей вроде библиотеки
тригонометрических функций прочно укоренило мысль о непригодности Лиспа для
«серьёзных программ». Как говорится в~◊cite{sla61}, возможность символьного
интегрирования или дифференцирования — это, конечно, замечательно, но кому
нужен язык, где нет даже синуса или тангенса?

Мы ожидаем, что все привычные функции вроде ◊ic{cons}, ◊ic{car} {◊itp} будут
доступны в~глобальном окружении. Также можно туда поместить несколько простых
констант вроде логических значений и пустого списка.

Для этого мы определим пару макросов. Исключительно для удобства, потому что мы
о~них ещё даже не~говорили.◊footnote*{Согласитесь, было~бы странным втискивать
всю книгу в~первую главу.} Макросы — это довольно сложная и важная вещь сами
по себе, так что им посвящена собственная глава. ◊seePage[chapter:macros]

Эти два макроса облегчат наполнение глобального окружения. Само глобальное
окружение является расширением начального окружения ◊ic{env.init}.

◊ForLayout{display}{◊begingroup
◊lstset{aboveskip=◊smallskipamount, belowskip=◊smallskipamount}}

◊indexC{env.global}
◊indexC{definitial}
◊indexC{defprimitive}
◊begin{code:lisp}
(define env.global env.init)
|◊ForLayout{display}{◊vskip-0.4◊baselineskip}|
(define-syntax definitial
  (syntax-rules ()
    ((definitial name)
     (begin (set! env.global (cons (cons 'name 'void) env.global))
            'name ) )
    ((definitial name value)
     (begin (set! env.global (cons (cons 'name value) env.global))
            'name ) ) ) )
|◊ForLayout{display}{◊vskip-0.4◊baselineskip}|
(define-syntax defprimitive
  (syntax-rules ()
    ((defprimitive name value arity)
     (definitial name
        (lambda (values)
          (if (= arity (length values))
              (apply value values)      ; Родная ◊ic{apply} Scheme
              (wrong "Incorrect arity" (list 'name values)|◊:|)|◊:|)|◊:|)|◊:|)|◊:|)|◊:|)|◊:|)
◊end{code:lisp}

◊indexC{the-false-value}
Несмотря на то, что стандарт Scheme этого не~требует, мы определим несколько
полезных констант. Заметим, что ◊ic{t} — это переменная в~определяемом Лиспе,
а ◊ic{◊#t} — это значение из определяющего Лиспа. Оно подходит, так как любое
значение, не~совпадающее с~◊ic{the-false-value}, является ◊term{истиной}.

◊begin{code:lisp}
(definitial t #t)
(definitial f the-false-value)
(definitial nil '())
◊end{code:lisp}

◊ForLayout{display}{◊endgroup}

◊indexR{синтаксис!для ◊protect◊ic{◊#t} и~◊ic{◊#f}}
◊indexR{логические значения}
Хотя это удобно — иметь глобальные переменные с~настоящими объектами для
данных сущностей, но есть и другое решение: особый синтаксис. Scheme использует
◊ic{◊#t} и ◊ic{◊#f}, подставляя вместо них логические ◊term{истину} и
◊term{ложь}. В~этом есть определённый смысл:

◊begin{enumerate}
  ◊item Они всегда видимы: ◊ic{◊#t} означает ◊term{истину} в~любом
        контексте, даже тогда, когда локальная переменная
        названа~◊ic{t}.

  ◊item Значение~◊ic{◊#t} невозможно изменить, но многие интерпретаторы
        позволят изменить значение глобальной переменной~◊ic{t}.
◊end{enumerate}

Например, выражение~◊ic{(if t 1 2)} вернёт~◊ic{2}, если оно вычисляется
в~следующем окружении: ◊ic{(let ((t ◊#f)) (if t 1 2))}.

◊indexC{eq?}
Существует много способов ввести такой синтаксис. Наиболее простой способ —
это вшить значения ◊ic{t} и~◊ic{f} в~вычислитель:

◊begin{code:lisp}
(define (evaluate e env)
  (if (atom? e)
      (cond ((eq? e 't) #t)
            ((eq? e 'f) #f)
            ...
            ((symbol? e) (lookup e env))
            ...
            (else (wrong "Cannot evaluate" exp)) )
      ... ) )
◊end{code:lisp}

◊indexR{инлайнинг!функций}
◊indexR{встраивание!функций}
◊indexR{функции!встраиваемые}
◊indexR{связывание!изменяемое}
◊indexR{связывание!неизменяемое}
Также мы могли~бы ввести понятия ◊term{изменяемого} и ◊term{неизменяемого}
связывания. Неизменяемые переменные отвергаются присваиванием. Ничто и никогда
не~сможет изменить значение неизменяемой переменной. Такая концепция существует,
хоть и не~всегда явно, во~многих системах. Например, существуют так называемые
◊term{инлайн-функции} (также известные как ◊term{подставляемые} или
◊term{встраиваемые}), вызов которых можно полностью заменить прямой подстановкой
их тела. ◊seePage[fast/fast/integrating/par:inlining]

Чтобы можно было спокойно подставить вместо ◊ic{(car~x)} код функции,
возвращающей левый элемент точечной пары~◊ic{x}, необходимо быть абсолютно
уверенным в~том, что значение глобальной переменной~◊ic{car} никогда не~менялось
и не~поменяется в~будущем. Посмотрите, какая беда случается, если это не~так:

◊begin{code:lisp}
(set! my-global (cons 'c 'd))
   |◊is| (c . d)
(set! my-test (lambda () (car my-global)))
   |◊is| #<MY-TEST procedure>
(begin (set! car cdr)
       (set! my-global (cons 'a 'b))
       (my-test) )
   |◊is| |◊ii{?????}|
◊end{code:lisp}

К~счастью, в~результате может получиться только ◊ic{a} или~◊ic{b}. Если
◊ic{my-test} использует значение~◊ic{car} на~момент определения, то мы
получим~◊ic{a}. Если~же ◊ic{my-test} будет использовать текущее
значение~◊ic{car}, то ответом будет~◊ic{b}. Полезным будет также сравнить в~этом
аспекте ◊ic{my-test} и ◊ic{my-global}: обычно первый вариант поведения ожидается
от ◊ic{my-test} при использовании компилятора, тогда как для ◊ic{my-global}
нормальным считается именно второй вариант.
◊seePage[lisp1-2-omega/recusion/simple/code:redefine]

◊indexC{foo}◊indexC{bar}◊indexC{fib}◊indexC{fact}
Также мы добавим несколько рабочих переменных◊footnote{К~сожалению, сейчас они
ещё и инициализируются. Эта ошибка будет исправлена позже.} в~глобальное
окружение, так как сейчас у~нас нет способа динамически создавать переменные.
По статистике, предлагаемые имена составляют приблизительно {96,037◊,◊%}
используемых при тестировании свеженаписанных интерпретаторов.

%◊ForLayout{display}{◊begingroup
%◊lstset{aboveskip=◊smallskipamount, belowskip=◊smallskipamount}}

◊begin{code:lisp}
(definitial foo)
(definitial bar)
(definitial fib)
(definitial fact)
◊end{code:lisp}

%◊ForLayout{display}{◊endgroup}

Наконец, определим несколько примитивных функций (не~все, потому что такие
полные списки — это хорошее снотворное). Главная сложность состоит
в~соединении механизмов вызова функций определяемого и определяющего языков.
Зная, что аргументы собираются нашим интерпретатором в~список, достаточно просто
применить
к~нему ◊ic{apply}.◊footnote*{Можно только порадоваться за наш выбор не~называть
◊ic{invoke} «◊ic{apply}».} Заметьте, что арность функций будет соблюдаться,
так как мы включили проверку в~определение макроса~◊ic{defprimitive}.

◊begin{code:lisp}
(defprimitive cons cons 2)
(defprimitive car car 1)
(defprimitive set-cdr! set-cdr! 2)
(defprimitive + + 2)
(defprimitive eq? eq? 2)
(defprimitive < < 2)
◊end{code:lisp}


◊section{Запускаем интерпретатор}◊label{basics/sect:starting-the-interpreter}

Нам осталось показать только одну вещь: дверь в~наш новый мир.

◊indexC{chapter1-scheme}
◊begin{code:lisp}
(define (chapter1-scheme)
  (define (toplevel)
    (display (evaluate (read) env.global))
    (toplevel) )
  (toplevel) )
◊end{code:lisp}

Поскольку наш интерпретатор ещё мал и неопытен, но подаёт большие надежды,
предлагаем вам в~качестве упражнения написать функцию, позволяющую из него
выйти.


◊section{Заключение}◊label{basics/sect:conclusions}

◊indexR{язык!и смысл программ}
Действительно~ли мы сейчас определили язык?

◊indexR{смысл программ}
◊indexR{программы!смысл}
Нет никаких сомнений в~том, что мы можем запустить ◊ic{evaluate}, передать ей
выражение, и она вскоре вернёт результат вычислений. Но сама функция
◊ic{evaluate} не~имеет никакого смысла без языка своего определения, а если
у~нас нет определения языка определения, то мы вообще ни~в~чём не~можем
быть уверены. Так как каждый лиспер является дальним родственником барона
Мюнхгаузена, то, наверное, будет достаточно взять в~качестве языка определения
тот, который мы только что определили. Следовательно, у~нас есть язык~$L$,
определённый функцией~◊ic{evaluate}, написанной на языке~$L$. Такой язык
является решением следующего уравнения относительно~$L$:
%
◊begin{equation*}
  ◊forall◊pi ◊in ◊Vset{Программы}◊colon
    L◊text{◊ic{(evaluate (quote $◊pi$) env.global)}} ◊equiv L◊pi
◊end{equation*}

Исполнение любой программы~$◊pi$, написанной на~$L$ (обозначается как~$L◊pi$),
должно вести себя так~же (то~есть давать тот~же результат или никогда
не~завершаться), как и выражение~◊ic{(evaluate (quote~$◊pi$) env.global)} на
том~же языке~$L$. Одним из занимательных следствий этого утверждения является
то, что ◊ic{evaluate} способна◊footnote{После того, как мы раскроем все
используемые макросы и сокращения вроде ◊ic{let}, ◊ic{case}, ◊ic{define}
{◊itd} Потом надо будет ещё поместить в~глобальное окружение функции
◊ic{evaluate}, ◊ic{evlis} и~др.} проинтерпретировать сама себя. Следовательно,
следующие выражения эквивалентны:

◊begin{code:lisp}
(evaluate (quote |$◊pi$|) env.global) |◊eq|
  |◊eq| (evaluate (quote (evaluate (quote |$◊pi$|) env.global)) env.global)
◊end{code:lisp}

Есть~ли ещё решения приведённого уравнения? Да, и их великое множество! Как мы
видели раньше, определение ◊ic{evaluate} вовсе не~обязательно указывает порядок
вычислений. Множество других свойств языка, используемого для определения,
бессознательно ◊emph{наследуются} определяемым языком. Мы, по~сути, ничего
не~можем о~них сказать, но все эти варианты претендуют на решение указанного
уравнения. Вместе с~многочисленными тривиальными решениями. Рассмотрим,
к~примеру, язык~$L_{2001}$, любая программа на котором возвращает~$2001$. Даже
такой язык удовлетворяет этому уравнению. Поэтому для определения настоящих
языков необходимы другие методы, их мы рассмотрим в~следующих главах.


◊section{Упражнения}◊label{basics/sect:exercises}

◊begin{exercise}◊label{basics/ex:tracer}
◊indexR{трассировка}
Модифицируйте функцию ◊ic{evaluate} так, чтобы она стала трассировщиком. Все
вызовы функций должны выводить на экран фактические аргументы и возвращаемый
результат. Легко представить себе дальнейшее развитие этого инструмента
в~пошаговый отладчик, вдобавок позволяющий изменять порядок выполнения
отлаживаемой программы.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:excess-recursion}
Если функции~◊ic{evlis} передаётся список из одного выражения, она делает
один лишний рекурсивный вызов. Придумайте способ, как избавиться от него.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:new-extend}
Предположим, новая функция~◊ic{extend} определена так:

◊indexC{extend}
◊begin{code:lisp}
(define (extend env names values)
  (cons (cons names values) env) )
◊end{code:lisp}

Определите соответствующие функции ◊ic{lookup} и ◊ic{update!}. Сравните их
с~ранее рассмотренными.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:racks}
◊indexR{ближнее (shallow) связывание}
◊indexR{связывание!ближнее (shallow)}
◊indexE{rack}
В~работе~◊cite{ss80} предлагается другой механизм ближнего связывания, названный
◊term{rack}. Символ связывается с~полем, хранящим не~единственное значение, а
стек значений. В~каждый момент времени значением переменной является находящаяся
на вершине стека величина. Перепишите функции ◊ic{s.make-function},
◊ic{s.lookup} и~◊ic{s.update!} для реализации этой идеи.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:liar-liar!}
◊indexR{представление!логических значений}
Если вы ещё не~заметили, то в~определение функции ◊ic{<} вкралась ошибка! Ведь
эта функция должна возвращать логические значения определяемого языка, а
не~определяющего. Исправьте это досадное недоразумение.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:def-list}
Определите функцию~◊ic{list}.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:def-call/cc}
Для обожающих продолжения: определите ◊ic{call/cc}.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:def-apply}
Определите функцию ◊ic{apply}.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:def-end}
Определите функцию~◊ic{end}, позволяющую выйти из интерпретатора, разработанного
в~этой главе.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:slowpoke}
◊indexR{уровни интерпретации}
◊indexR{интерпретация!уровневая}
Сравните скорость Scheme и ◊ic{evaluate}. Затем сравните скорость ◊ic{evaluate}
и ◊ic{evaluate}, интерпретируемой с~помощью ◊ic{evaluate}.
◊end{exercise}

◊begin{exercise}◊label{basics/ex:no-gensym}
Ранее мы смогли успешно определить ◊ic{begin} через ◊ic{lambda}
◊seePage[basics/forms/sequence/par:gensym-puzzle], но для этого нам
потребовалось использовать функцию ◊ic{gensym}, чтобы избежать коллизий имён
переменных. Переопределите ◊ic{begin} в~таком же духе, но без использования
◊ic{gensym}.
◊end{exercise}


◊section*{Рекомендуемая литература}

Все работы по интерпретаторам, приведённые в~начале этой главы, являются
довольно интересными, но если вы не~можете столько читать, то вот наиболее
стоящие из них:
◊begin{itemize}
  ◊item среди «$◊lambda$"~papers»:~◊cite{ss78a};

  ◊item самая короткая в~мире статья, которая содержит полный интерпретатор
        Лиспа:~◊cite{mcc78b};

  ◊item «нестрого формальное» описание интерпретации:~◊cite{rey72};

  ◊item местная книга Бытия:~◊cite{mae+62}.
◊end{itemize}
