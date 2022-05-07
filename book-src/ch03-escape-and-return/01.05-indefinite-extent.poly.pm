#lang pollen

◊subsection[#:label "escape/forms/ssect:immortal"]{Метки с~неограниченным временем~жизни}

◊indexR{переходы (escapes)!неограниченные}
◊indexR{оператор~◊${J}}
◊indexE{J, оператор@◊${J}, оператор}
В~рамках переосмысления Лиспа, примерно в~1975~году диалект Scheme предложил дать продолжениям неограниченное время жизни.
Это открыло поистине поразительные возможности, буквально выходящие за пределы форм ◊ic{catch} и~◊ic{block}.
Позже, в~соответствии с~догматом о~минимальном количестве специальных форм,
были предприняты попытки выразить захват продолжений с~помощью функций,
а~сами продолжения сделать полноценными значениями в~языке.
Предложенный Питером~Лэндином оператор~◊${J} ◊seeCite{lan65} превратился в~функцию~◊ic{call/cc}.

◊indexC{call/cc!определение}
◊indexR{продолжения (continuations)!захват}
Мы постараемся объяснить синтаксис ◊ic{call/cc} настолько просто, насколько это возможно.
Во-первых, она захватывает продолжения — это форма, где доступно продолжение её~вызова,~◊${k}:

◊code:lisp{
◊cont{◊${k}}(...)
}

◊noindent
Далее, это должна быть функция.
Назовём её ◊ic{call/cc}:

◊code:lisp{
◊cont{◊${k}}(call/cc ...)
}

◊noindent
Теперь, когда мы захватили~◊${k}, его нужно как-то использовать.
Передавать~◊${k} самому себе~же будет неудобно по~ряду причин, здесь требуется другой подход.
Значение~◊${k} будет участвовать в~вычислениях,
так что давайте эти вычисления завернём в~унарную функцию
◊footnote{
  В~Scheme достаточно, чтобы функция могла принять как минимум один аргумент.
  То~есть с~◊nobr{◊ic{(call/cc list)}} нет никаких проблем.
}
и~передадим её ◊ic{call/cc}:

◊code:lisp{
◊cont{◊${k}}(call/cc (lambda (k) ...))
}

◊indexR{полноценные объекты!продолжения}
◊indexR{продолжения (continuations)!как полноценные объекты}
◊indexR{продолжения (continuations)!как замыкания}
◊indexR{реификация}
◊noindent
Функция ◊ic{call/cc} ◊term{реифицирует} продолжение~◊${k} в~полноценный объект (◊english{reified contination}), который становится значением переменной~◊ic{k}.
Scheme представляет продолжения в~виде функций — они неотличимы от замыканий, создаваемых формой~◊ic{lambda}.
Достаточно вызвать функцию~◊ic{k}, чтобы перейти к~продолжению формы~◊ic{call/cc}:

◊code:lisp{
◊cont{◊${k}}(call/cc (lambda (k) (+ 1 (k 2)))) ⟹ 2
}

◊indexC{continue}
Справедливо будет заметить, что функции вызываются, а~продолжения продолжаются.
Альтернативный подход мог~бы представлять продолжения отдельным типом данных, отличным от функций.
Тогда, естественно, их нельзя будет вызывать как функции —
потребуется специальный синтаксис продолжения: скажем, форма~◊ic{continue}.
Пример выше записывался~бы тогда так:

◊code:lisp{
◊cont{◊${k}}(call/cc (lambda (k) (+ 1 (continue k 2)))) ⟹ 2
}

При необходимости продолжение всё~ещё легко превращается в~функцию:
◊ic{(lambda~(v) (continue~k~v))}.
Просто некоторым людям нравится использовать развёрнутую форму со~специальным синтаксисом —
так использование продолжений становится более заметным.

Вот~и~всё.
Осталось только запомнить полное имя этой функции: ◊ic{call-with-current-continuation}.
Теперь давайте перепишем пример с~двоичным деревом используя ◊ic{call/cc}:

◊indexC{find-symbol!с~переходами}
◊code:lisp{
(define (find-symbol id tree)
  (call/cc
   (lambda (exit)
     (define (find tree)
       (if (pair? tree)
           (or (find (car tree))
               (find (cdr tree)) )
           (if (eq? tree id) (exit #t) #f) ) )
     (find tree) ) ) )
}

Функция ◊ic{find-symbol} захватывает продолжение своего вызова с~помощью ◊ic{call/cc},
превращает его в~унарную функцию, которая связывается с~переменной ◊ic{exit}.
Как только мы находим нужный символ, рекурсивный поиск прерывается вызовом функции ◊ic{exit},
которая не~возвращает никакого значения — она выполняет переход сразу к~вычислениям,
продолжающимся после вызова ◊ic{find-symbol}.

◊phantomlabel{escape/forms/immortal/par:reincarnate}
◊indexR{продолжения (continuations)!время жизни!неограниченное}
◊indexR{присваивание!роль для продолжений}
В~примере выше неограниченность времени жизни продолжений не~очевидна,
потому что они используются исключительно внутри самой~же формы ◊ic{call/cc},
то~есть обладают динамическим временем жизни.
Рассмотрим другой пример:

◊indexC{fact}
◊code:lisp{
(define (fact n)
  (let ((r 1) (k 'void))
    (call/cc (lambda (c) (set! k c) 'void))
    (set! r (* r n))
    (set! n (- n 1))
    (if (= n 1) r (k 'recurse)) ) )
}

◊noindent
Здесь реифицированное продолжение~◊${k} сохраняется в~переменной~◊ic{k}:

◊; TODO: разинца между =, ≡, → -- унифицируй использование
◊; красивое отображение формул с коде, может всё же ◊ii{k}?
◊code:lisp{
◊${k} = (lambda (◊ii{u})
      (set! r (* r n))
      (set! n (- n 1))
      (if (= n 1) r (k 'recurse)) )◊where{
                                   | r → 1
                                   | k ≡ ◊${k}
                                   | n
                                   }
}

Это~же продолжение~◊${k} связано с~переменной~◊ic{k} внутри самого себя.
Рекурсия, как мы знаем, всегда означает какой-нибудь цикл.
В~данном случае ◊ic{k}~вызывается до тех пор, пока ◊ic{n} не~достигнет желаемого значения.
Вся эта конструкция, естественно, вычисляет факториал.

В~этом примере продолжение~◊${k} используется вне создавшей его формы ◊ic{call/cc}
и продолжает существовать, пока жива переменная~◊ic{k}.
Кстати, с~помощью небольшой хитрости можно избавиться от избыточных переменных и аргументов:

◊code:lisp{
(define (fact n)
  (let ((r 1))
    (let (k (call/cc (lambda (c) c)))
      (set! r (* r n))
      (set! n (- n 1))
      (if (= n 1) r (k k)) ) ) )
}

◊indexR{самоприменение}
◊noindent
Для сохранения значения~◊ic{k} необходимо самоприменение~◊ic{(k~k)},
так как продолжением~◊ic{k} является связывание переменной~◊ic{k} с~соответствующим значением.
Это продолжение можно записать следующим образом:

◊code:lisp{
(lambda (◊ii{u})
  (let ((k ◊ii{u}))
    (set! r (* r n))
    (set! n (- n 1))
    (if (= n 1) r (k k)) ) )◊where{
                            | r → 1
                            | n
                            }
}

◊indexR{продолжения (continuations)!сложность реализации}
◊indexR{стек!и продолжения}
Неограниченное время жизни продолжений усложняет их реализацию и в~общем случае увеличивает стоимость использования продолжений.
◊seeCite{cho88,hdb90,mat92}
Дело в~том, что теперь вычисления уже нельзя представлять в~виде стека — здесь требуется дерево.
Если продолжения имеют исключительно динамическое время жизни, то это просто переходы выше по~стеку.
С~помощью таких продолжений можно отбросить часть текущих вычислений, вернув значение чуть быстрее.
В~этом случае легко понять, когда вычисление каждой формы начинается и заканчивается:
начинается при входе в~форму, а~заканчивается с~последним выражением или~же с~первым встреченным переходом.

◊indexR{возвращаемые значения!многократно}
◊indexR{продолжения (continuations)!множественные возвраты}
Если~же продолжения живут неограниченно долго, то всё значительно усложняется.
Вспомните форму ◊nobr{◊ic{(call/cc ...)}} в~примере с~факториалом:
она фактически возвращает несколько значений.
◊footnote{
  В~том смысле, что она возвращает результат несколько~раз,
  а~не~два и более значений в~виде результата,
  как это позволяет форма~◊ic{values} в~◊|CommonLisp| и~Scheme.
}
Теперь уже нельзя считать, что выполнение функции окончено, когда она возвращает значение или прерывается.

◊indexR{память!и~◊ic{call/cc}}
◊ic{call/cc} могущественна и в~некотором смысле повелевает временем.
Если заранее подготовиться и «сохраниться», то с~помощью продолжения программа может вернуться в~прошлое.
При этом сохраняется весь накопленный опыт (память),
так~что после прыжка вычисления пойдут уже другим путём,
а~не~застрянут в~бесконечном цикле перерождений, совершая одни и те~же действия раз~за~разом.

◊indexC{goto}
Форма~◊ic{call/cc} похожа на~расширенную версию оператора~◊ic{goto} (◊english{considered harmful}).
Она позволяет переходить к~сохранённому продолжению из буквально любого места в~программе.
Однако ◊ic{call/cc} несколько более ограничена,
так как с~помощью неё можно лишь ◊emph{вернуться} к~ранее выполненным вычислениям,
но~нельзя осуществлять произвольные переходы вперёд по~коду.

Вначале бывает нелегко научиться пользоваться ◊ic{call/cc},
так как и~её аргумент, и~продолжения — это невнятные унарные функции.
В~таком случае вам может помочь понимание ◊ic{call/cc} как~макроса:

◊; TODO: сделай так, чтобы в текте программ → заменялось на ◊${\to}, ≡ на ◊${\equiv}, и т.д.
◊; то есть чтобы они показывались красивым математическим шрифтом, а не тем, что там в моноширинном
◊code:lisp{
◊cont{◊${k}}(call/cc ◊${\varphi}) → ◊cont{◊${k}}(◊${\varphi} ◊${k})
}

◊noindent
где ◊${k} является продолжением вызова ◊ic{call/cc}, а~◊${\varphi} — это унарная функция.
Вызов ◊ic{call/cc} лишь превращает~◊${k} в~полноценный объект языка, который можно передать как аргумент.
Заметьте, что продолжением вызова ◊${\varphi} является всё так~же~◊${k},
поэтому для того, чтобы просто вернуть результат, не~обязательно пользоваться переданным продолжением:

◊code:lisp{
(call/cc (lambda (k) 1515)) ⟹ 1515
}

Некоторых людей подобные вольности расстраивают:
если вмешиваешься в~ход вычислений, то~будь добр иди до~конца и управляй вычислениями вручную.
В~некоторых языках ◊ic{call/cc} изымает захватываемое продолжение~◊${k} из вычислений:
◊${k}~больше не~является своим собственным продолжением,
и~для передачи значения последующим вычислениям их необходимо явно продолжить:

◊code:lisp{
(call/cc (lambda (k) (k 1615))) ⟹ 1615
}

◊indexR{продолжения (continuations)!терминальное продолжение}
◊indexR{терминальное продолжение}
Если этого не~сделать, то продолжением формы ◊ic{call/cc} будет что-то вроде чёрной дыры:
◊nobr{◊${\lambda u.\bullet}},
которая поглощает все вычисления вместе с~передаваемым значением, полностью уничтожая информацию.
Как только вы пересекаете этот горизонт событий, само понятие «последующих вычислений» теряет смысл.
Их больше не~существует, равно как и~вас, вашей клавиатуры, и~текста, который вы сейчас читаете.
Я~не хочу исчезнуть, поэтому не~забывайте вызывать свои продолжения, хорошо?
