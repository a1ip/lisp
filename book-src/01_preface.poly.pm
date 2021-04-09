#lang pollen

◊chapter*[#:label "chapter:to_the_reader"]{К~читателю}

◊initial{Несмотря на то,} что литературы на тему Лиспа достаточно и она легкодоступна, эта книга имеет свою нишу.
Программирование требует понимания фундаментальных основ языка;
для Лиспа и Scheme ими являются нетривиальные вещи вроде функций высшего порядка, объектов, продолжений, и~тому подобного.
Их~незнание и непонимание преграждает вам путь в~будущее:
сегодня что-то считается сложным, а завтра становится нормой для образованного человека.

Для объяснения природы данных сущностей, их происхождения и разновидностей нам придётся серьёзно углубиться в~детали.
Ходит поговорка, что лисперы знают ценность всего, но не~ведают подлинной цены.
Данная книга также направлена на сокращение этой пропасти в~понимании языка
с~помощью детального изучения его семантики, а~также реализации различных возможностей Лиспа,
которые были изобретены за его более чем тридцатилетнюю историю.

Лисп — это приятный язык, на котором многие фундаментальные и нетривиальные вещи выражаются простым образом.
Вместе с~ML, своим строго типизированным собратом (почти) без побочных эффектов,
Лисп является типичным представителем семейства аппликативных языков программирования.
Изучение концепций, на которых это семейство основано, без сомнения будет полезно для студентов и учёных-информатиков наших и будущих лет.
Основанные на идее ◊term{функции}, — идее, которая веками оттачивалась и уточнялась математикой, —
аппликативные языки присутствуют практически везде, где присутствуют вычисления,
проявляясь в~различных формах:
начиная перенаправлением потоков в~◊(UNIX),
заканчивая языком расширений редактора~Emacs и многими другими скриптовыми языками.
Использование таких инструментов без понимания основного их механизма — комбинации —
подобно попыткам выразить мысль с~помощью отдельных слов вместо цельного предложения.
Для выживания может быть достаточно нескольких заученных фраз, но для полноценной жизни требуется вся мощь языка.


◊section*[#:label "pref/sect:audience"]{Аудитория}

Книга предназначена для широкой аудитории специалистов:

◊itemize{
  ◊item{
    для выпускников вузов и студентов,
    которые изучают приёмы реализации языков программирования;
    аппликативных или нет, интерпретацию или компиляцию — не~важно;
  }
  ◊item{
    для программистов на Лиспе или Scheme,
    желающих чётче понимать нюансы и стоимость используемых ими конструкций,
    дабы писать более эффективные и переносимые программы;
  }
  ◊item{
    для всех любителей аппликативных языков,
    которые найдут в~этой книге множество интересных размышлений на свою любимую~тему.
  }
}


◊section*[#:label "pref/sect:philosophy"]{Философия}

Данная книга основана на курсе лекций, читаемом в~магистратуре Университета Пьера и Марии~Кюри;
некоторые части курса также преподаются в~Политехнической школе.

Темы, рассматриваемые здесь, обычно следуют за вводным курсом аппликативных языков вроде Лиспа, Scheme или~ML,
так как подобные курсы чаще всего заканчиваются детальным разбором изучаемого языка.
Цель этой книги — как можно шире покрыть тему семантики аппликативных языков и разработки их интерпретаторов и компиляторов.
Здесь приведено двенадцать интерпретаторов и два компилятора (в~байт-код и в~Си).
Не~обходится стороной и объектно-ориентированная модель (рассматриваемая на примере ◊(Meroon)).
Также, в~отличие от многих других книг,
эта не~пренебрегает такими существенными для семейства Лиспов вещами
как рефлексия, интроспекция, динамическая кодогенерация и, конечно~же, макросы.

Отчасти эта книга вдохновлена двумя работами:
«◊english{Anatomy~of~Lisp}»~◊cite{all78},
рассматривающей подходы к~реализации Лиспа в~семидесятых годах,
и~«◊english{Operating~System Design: The~XINU Approach}»~◊cite{com84},
где приводится весь необходимый код без сокрытия деталей работы операционной системы,
что полностью убеждает читателя в~верности изложения.

В~таком~же духе — точности, а не~лаконичности — написана и эта книга,
главным вопросом которой есть семантика аппликативных языков в~общем и Scheme в~частности.
Исследуя множество реализаций, рассматривая их различные аспекты,
мы узнаем с~максимальной точностью, как строится любая подобная система.
Мы~рассмотрим большую часть проблемных вопросов, вызывающих расколы в~сообществе;
каждая из этих проблем будет изучена, варианты её решения — реализованы, сравнены и проанализированы.
«И~пусть никто не~уйдёт обиженным» на недостаток информации.
Более того, благодаря подобному фундаменту знаний, вы сможете самостоятельно экспериментировать с~рассматриваемыми концепциями.

Естественно, в~вашем распоряжении будет полный код всех программ, приведённых в~этой книге.
(Подробности в~разделе~◊ref{pref/sect:source}.)


◊section*[#:label "pref/sect:structure"]{Структура}

Книга разделена на две~части.
Первая часть начинается реализацией наивного интерпретатора Лиспа и рассматривает в~основном семантику Scheme.
Здесь нас интересует точность повествования,
поэтому мы будем раз за разом уточнять и переопределять различными способами
пространства имён (◊(Lisp1), ◊(Lisp2), и~т.~д.),
продолжения (и~связанные с~ними управляющие конструкции),
присваивание и изменяемые структуры данных.
Мы заметим, что по мере того, как определяемый язык обрастает возможностями,
его определение становится всё более простым, приближаясь ◊nobr{к~◊${\lambda}-исчислению}.
Полученное таким образом описание языка мы превратим в~его денотационный, строго математический эквивалент.

Более шести лет практики преподавания убедили меня в~том,
что именно такой подход постепенного уточнения языка необходим для мягкого знакомства
с~темой исследования языков вообще и денотационной семантикой вычислений в~частности —
темой, которую мы не~можем себе позволить обойти стороной.

Вторая часть книги следует иным путём.
Преследуя цель сделать наивную реализацию денотационного интерпретатора более эффективной,
мы коснёмся темы ускорения интерпретации (заранее вычисляя неизменные величины),
а потом реализуем эту предварительную обработку (с~помощью предкомпиляции) для нашего компилятора в~байт-код.
В~этой части подготовка программы к~исполнению и собственно исполнение чётко отделены,
поэтому здесь будут рассматриваться такие темы как динамические вычисления (◊ic{eval}),
рефлексия (окружения как объекты первого класса, самоинтерпретация, «башня» интерпретаторов),
семантика макросов.
Далее мы реализуем транслятор Scheme в~код на языке~Си.

Завершается книга реализацией объектно-ориентированной системы,
которая существенно поможет нам в~реализации некоторых интерпретаторов и компиляторов.

Как известно, повторенье — мать ученья.
Все приведённые интерпретаторы намеренно написаны в~различных стилях:
наивном, объектно-ориентированном, основанном на замыканиях, денотационном, и~т.~д.
Это позволит рассмотреть множество приёмов, используемых при реализации аппликативных языков.
Также это подтолкнёт вас на размышления о~различиях между ними.
Понимание этих различий
(см.~таблицу~◊ref{pref/table:signatures} с~подсказками)
является истинным пониманием языка и его реализаций.
Лисп — это не~одна из таких реализаций, это ◊emph{семейство} диалектов,
каждый из которых имеет свой уникальный набор черт, которые мы будем рассматривать.

◊table[#:label "pref/table:signatures"]{
◊caption{Прототипы интерпретаторов и компиляторов.}
Глава | Прототип
------+:------------------------------
   1  | ◊ic{(eval exp env)}
   2  | ◊ic{(eval exp env fenv)}
      | ◊ic{(eval exp env fenv denv)}
      | ◊ic{(eval exp env denv)}
   3  | ◊ic{(eval exp env cont)}
   4  | ◊ic{(eval e r s k)}
   5  | ◊ic{((meaning e) r s k)}
   6  | ◊ic{((meaning e r) sr k)}
      | ◊ic{((meaning e r tail?) k)}
      | ◊ic{((meaning e r tail?))}
   7  | ◊ic{(run (meaning e r tail?))}
  10  | ◊ic{(->C (meaning e r))}
}

Главы более-менее независимы, занимают примерно по~50~страниц;
каждая глава имеет список упражнений, ответы к~которым можно найти в~конце книги.
Список литературы содержит не~только исторически важные книги,
позволяющие отследить развитие Лиспа с~1960~года,
но и современные~труды.


◊section*[#:label "pref/sect:prereqs"]{Предварительные знания}

Хоть я и надеюсь, что книга будет увлекательной и содержательной, но она не~обязательно будет лёгкой для чтения.
Некоторые описанные здесь вещи можно постичь, только прикладывая усилия, соответствующие их сложности.
Говоря языком куртуазных романов,
некоторые предметы воздыханий открывают свою истинную красоту и обаяние лишь когда мы учтиво, но непреклонно штурмуем~их;
если их богатый и непростой внутренний мир не~будет под постоянной осадой, они так и останутся неприступными.

Изучение сущности языков программирования требует владения инструментами вроде ◊nobr{◊${\lambda}-исчисления} и денотационной семантики.
Хотя повествование и будет мягко, последовательно и логично переходить от одной темы к~следующей,
это не~сможет избавить вас ото всех необходимых усилий.

Вам потребуются некоторые предварительные знания о~Лиспе или Scheme;
в~частности, знание примерно тридцати базовых функций и способность понимать рекурсию без чрезмерного умственного напряжения.
Основным языком этой книги выбран Scheme
(см.~раздел~◊ref{pref/sect:scheme-summary}),
а также объектно-ориентированное расширение ◊(Meroon).
Данное расширение поможет нам в~рассмотрении некоторых проблем представления и реализации структур данных.

Все приведённые в~книге программы были протестированы и действительно работают в~интерпретаторе Scheme.
А~для тех, кто усвоит материал этой книги, не~будет составлять особого труда портировать их куда~угодно!


◊section*[#:label "pref/sect:thanks"]{Благодарности}

Я~должен поблагодарить организации, которые обеспечили меня оборудованием
(Apple~Mac~SE/30, затем Sony~NEWS~3260, впоследствии разнообразными PC и PowerBook)
и~вообще сделали эту книгу возможной:
Политехническую школу,
Государственный институт исследований в~области информатики и~автоматики~(INRIA),
Национальный центр научных исследований~(CNRS).

Также я хотел~бы поблагодарить тех, кто помогал мне всем, чем мог, в~создании этой книги.
В~особом долгу я перед Софи~Англад, Жози~Бирон, Кэтлин~Коллэвей, Жеромом~Шейёксом,
Жаном-Мари~Жеффруа, Кристианом~Жюльеном, Жан-Жаком~Лакрампом, Мишелем~Леметром,
Люком~Моро, Жаном-Франсуа~Перро, Дэниелом~Риббенсом, Бернардом~Серпеттом,
Мануэлем~Серрано, Пьером~Ве, а~также перед моей музой, Клэр~Н.
◊trnote{
  Sophie~Anglade, Josy~Byron, Kathleen~Callaway, Jérôme~Chaillox, Jean-Marie Geffroy,
  Christian~Jullien, Jean-Jacques~Lacrampe, Michel~Lemaître, Luc~Moreau, Jean-François~Perrot,
  Daniel~Ribbens, Bernard~Serpette, Manuel~Serrano, Pierre~Weis, Claire~N.
}

Конечно~же, все ошибки, которые, к~сожалению, неизбежно присутствуют в~тексте, являются моими~собственными.


◊section*[#:label "pref/sect:notation"]{Нотация}

Фрагменты программ будут набраны
◊textcd{таким шрифтом, который несомненно напомнит вам о~старых добрых печатных машинках}.
Некоторые слова в~коде также будут набраны ◊textit{курсивом} для обозначения понятий,
подразумеваемых на месте этих слов.

◊indexC[#:sort-as "->" #:label "is"]{◊(is)}
◊indexC[#:sort-as "==" #:label "eq"]{◊(eq)}
Знак ◊(is) читается: «имеет значение», а знак ◊(eq) обозначает эквивалентность, «имеет то~же значение, что~и».
При разборе вычисления выражений после вертикальной черты мы будем записывать окружение, в~котором проводятся вычисления.
Вот пример, иллюстрирующий эти соглашения:

◊code:lisp{
(let ((a (+ b 1)))
  (let ((f (lambda () a)))
    (foo (f) a) ) )◊where{
                   | b ◊(is) 3
                   | foo ◊(eq) cons
                   }

◊(eq) (let ((f (lambda () a))) (foo (f) a))◊where{
                                           | a ◊(is) 4
                                           | b ◊(is) 3
                                           | foo ◊(eq) cons
                                           | f ◊(eq) (lambda () a)◊where{
                                                                  | a ◊(is) 4
                                                                  }
                                           }
◊(eq) (foo (f) a)◊where{
                 | a ◊(is) 4
                 | b ◊(is) 3
                 | foo ◊(eq) cons
                 | f ◊(eq) (lambda () a)◊where{
                                        | a ◊(is) 4
                                        }
                 }
◊(is) (4 . 4)
}

Все имена переменных и сообщения об~ошибках в~приводимых программах
мы будем записывать на английском — «родном языке» Scheme.

Мы будем использовать несколько нестандартных функций вроде ◊ic{gensym},
которая генерирует символы, гарантированно не~встречавшиеся ранее в~тексте программы.
В~десятой главе также будут применяться функции ◊ic{format} и ◊ic{pp} для форматированного вывода (pretty-printing).
Эти функции есть в~большинстве реализаций Лиспа и~Scheme.

Некоторые выражения имеют смысл только для какого-то из диалектов Лиспа вроде
◊(CommonLisp), ◊(Dylan), ◊(EuLisp), ◊(ISLisp), ◊(LeLisp),
◊footnote{◊(LeLisp) является торговой маркой INRIA.}
Scheme и~т.~д.
В~этом случае мы будем писать рядом название диалекта:

◊code:lisp[#:dialect (ISLisp)]{
(defdynamic fooncall
  (lambda (one :rest others)
    (funcall one others) ) )
}

Дабы было легче ориентироваться в~этой книге,
мы будем использовать обозначение ◊(seePage*) для перекрёстных ссылок на~страницы.
Похожая нотация будет использоваться при необходимости указать на упражнение: ◊(seeEx*).
Также в~книге есть предметный указатель со~ссылками на все определяемые функции.
◊seePage{chapter:index}


◊section*[#:label "pref/sect:scheme-summary"]{Краткий обзор Scheme}

Для изучения Scheme существует множество отличных книг, вроде ◊cite{as85}, ◊cite{dyb87}, ◊cite{sf89}.
Мы~же будем опираться на спецификацию, описанную в~документе
«Revised revised revised revised revised Report on Scheme»,
название которого часто сокращают до~◊(RnRS).~◊cite{kcr98}

Сейчас мы лишь набросаем основные характерные черты этого диалекта;
те~черты, которые потом будут подробно проанализированы по мере улучшения нашего понимания языка.

В~Scheme можно использовать символы, знаки,
◊trnote{
  Если возможны разночтения, то слово ◊term{знак} будет использоваться в~смысле «печатный символ» (◊english{character}),
  а~слово ◊term{символ} — в~привычном для Лиспа значении (◊english{symbol}).
}
строки, списки, числа, логические значения, векторы, порты,
и~функции (или процедуры, как их принято называть в~Scheme).

Каждый из этих типов данных имеет соответствующий предикат:
◊ic{symbol?}, ◊ic{char?}, ◊ic{string?}, ◊ic{pair?}, ◊ic{number?}, ◊ic{boolean?}, ◊ic{vector?}, ◊ic{procedure?}.

Помимо них в~наличии есть процедуры-аксессоры и модификаторы для тех типов, где это имеет смысл:
◊ic{string-ref}, ◊ic{string-set!}, ◊ic{vector-ref} и~◊ic{vector-set!}.

Для списков они называются ◊ic{car}, ◊ic{cdr}, ◊ic{set-car!} и~◊ic{set-cdr!}.

Функции ◊ic{car} и ◊ic{cdr} могут комбинироваться.
Например, для доступа ко~второму элементу списка используется~◊ic{cadr}.

Все значения этих типов могут быть непосредственно записаны в~программе.
С~символами и числами всё очевидно.
Перед знаками пишется префикс ◊ic{#\}, например: ◊ic{#\Z}, ◊ic{#\+}, ◊ic{#\space}.
Строки окружаются ◊ic{"}кавычками◊ic{"},
списки — ◊ic{(}круглыми скобками◊ic{)}.
Логические значения записываются как ◊ic{#t} и ◊ic{#f} соответственно.
Для записи векторов используется синтаксис ◊ic{#(do~re~mi)}.
Естественно, такие значения могут быть построены и динамически
с~помощью ◊ic{cons}, ◊ic{list}, ◊ic{string}, ◊ic{make-string}, ◊ic{vector}, ◊ic{make-vector}.
Также в~наличии есть функции приведения типов вроде ◊ic{string->symbol} и~◊ic{int->char}.

Ввод-вывод обеспечивают следующие функции:
◊ic{read} читает вводимые выражения,
◊ic{display} выводит их на экран,
а~◊ic{newline} переходит на следующую~строку.

◊(bigskip)

◊indexR{форма!концепция Scheme}
Программы на~Scheme представляются так называемыми~◊term{формами}.

◊indexC{begin}
Форма~◊ic{begin} позволяет сгруппировать формы и вычислить их последовательно;
например, ◊ic{(begin (display~1) (display~2) (newline))}.

◊indexC{if}
◊indexC{cond}
◊indexC{else}
◊indexE{Scheme!логические значения}
◊indexR{логические значения!в~Scheme}
Есть несколько форм ветвления.
Простейшей из них является ◊ii{if–then–else},
которая на~Scheme так и записывается: ◊ic{(if ◊ii{условие} ◊ii{тогда} ◊ii{иначе})}.
Если вариантов больше двух, то для этого случая в~Scheme есть формы ◊ic{cond} и~◊ic{case}.
Форма~◊ic{cond} содержит список утверждений,
каждое из которых начинается с~условия — выражения, возвращающего логическое значение, —
за~которым располагается последовательность других форм (следствие).
◊ic{cond}~последовательно вычисляет условия утверждений до тех пор,
пока одно из них не~вернёт истину (а~точнее: не~ложь, не~◊ic{#f});
затем вычисляется следствие данного утверждения,
и результат его вычисления становится результатом всей формы ◊ic{cond}.
Вот пример использования этой формы, который заодно показывает ключевое слово~◊ic{else}:

◊code:lisp{
(cond ((eq? x 'flip) 'flop)
      ((eq? x 'flop) 'flip)
      (else (list x "neither flip nor flop")) )
}

◊indexC{case}
Форма~◊ic{case} похожа на~◊ic{cond},
но она принимает первым параметром форму,
на основе значения которой производится выбор между вариантами.
Каждый из вариантов в~начале содержит список значений, которые подходят для него.
Как только найден подходящий вариант, он вычисляется
и этот результат становится результатом всей формы~◊ic{case}.
Аналогично, в~конце может стоять универсальный вариант~◊ic{else}.
Вот так можно переписать предыдущий пример с~помощью~◊ic{case}:

◊code:lisp{
(case x
  ((flip) 'flop)
  ((flop) 'flip)
  (else (list x "neither flip nor flop")) )
}

◊indexC{lambda}
◊indexC{let}
◊indexC{let*}
◊indexC{letrec}
◊indexC{set!}
◊indexC{quote}
Функции определяются формой~◊ic{lambda}.
За~словом~◊ic{lambda} следует список аргументов,
а после него — последовательность выражений, которые описывают собственно вычисление функции.
Формы~◊ic{let}, ◊ic{let*} и~◊ic{letrec} определяют локальные переменные
(они~отличаются тонкостями вычисления значений определяемых переменных).
Значения переменных в~дальнейшем можно изменять с~помощью формы~◊ic{set!}.
Для записи литералов используется форма~◊ic{quote}.

◊indexC{define}
◊indexC{define!синтаксис}
◊indexR{синтаксис!define@◊ic{define}}
С~помощью формы~◊ic{define} можно вводить глобальные определения.
У~неё есть особые возможности, которые мы будем использовать.
В~частности, возможность использовать её в~локальном контексте подобно~◊ic{let},
а~также вариант синтаксиса этой формы, позволяющий удобнее определять функции.
Вот, что имеется в~виду:

◊code:lisp{
(define (rev l)
  (define nil '())
  (define (reverse l r)
    (if (pair? l) (reverse (cdr l) (cons (car l) r)) r))
  (reverse l nil) )
}

◊noindent{Без синтаксического сахара этот пример выглядит так:}

◊code:lisp{
(define rev
  (lambda (l)
    (letrec ((reverse (lambda (l r)
                        (if (pair? l) (reverse (cdr l)
                                               (cons (car l) r))
                            r) )))
      (reverse l '()) ) ) )
}

На~этом мы заканчиваем наш краткий обзор~Scheme.


◊section*[#:label "pref/sect:source"]{Исходный~код}

Программы (интерпретируемые и скомпилированные), приведённые в~этой книге,
объектную систему, и тесты для них можно забрать по следующему адресу:

◊quote{◊url{http://pagesperso-systeme.lip6.fr/Christian.Queinnec/Books/LiSP-2ndEdition-2006Dec11.tgz}}
◊; TODO: зеркало на GitHub

Электронный адрес автора книги:
◊email{Christian.Queinnec@lip6.fr}
◊; TODO: он разве не менялся? адрес?


◊section*[#:label "pref/sect:reading"]{Рекомендуемая литература}

Так~как подразумевается, что вы уже знаете Scheme, мы будем ссылаться на традиционные~◊cite{as85,sf89}.

Чтобы получить от книги больше, имеет смысл поглядывать в~другие руководства:
◊(CommonLisp)~◊cite{ste90},
◊(Dylan)~◊cite{app92b},
◊(EuLisp)~◊cite{pe92},
◊(ISLisp)~◊cite{iso94},
◊(LeLisp)~◊cite{cdd+91},
Oaklisp~◊cite{lp88},
Scheme~◊cite{kcr98},
T~◊cite{ram84},
Talk~◊cite{ilo94}.

Наконец, для лучшего понимания языков программирования в~целом будет полезной книга~◊cite{bg94}.
◊trnote{
  Кроме того, лично я хотел~бы посоветовать замечательную книгу
  ◊textit{Franklyn~Turbak and David~Gifford with Mark~A.~Sheldon.}
  Design~Concepts in Programming Languages. — The~MIT~Press,~2008.
}

◊; - неразрвные пробелы перед тире
◊; - даже если тире - это первый символ в строке
◊; - тонкие пробелы вокруг тире (особенно после точки)
◊; - запрет переносов "из-за", "какого-то", и прочих комбинаций даже без nobr
◊; - правильные пробелы перед сносками после пунктуации (\footnote vs. \footnote*)
