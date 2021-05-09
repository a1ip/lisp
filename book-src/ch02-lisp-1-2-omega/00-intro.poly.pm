#lang pollen

◊chapter[#:label "chapter:lisp1-2-omega" #:alt "Lisp, 1, 2, ..., ω"]{Lisp, 1, 2, ◊(dots), ◊${\omega}}

◊initial{Функции занимают} центральное место в~Лиспе,
поэтому их эффективная реализация критически важна.
Теме функций было посвящено довольно много исследований, изобретено порядочно подходов к~реализации,
но этот вопрос настолько глубокий, что эксперименты и поиск новых подходов продолжается до сих~пор.
В~этой главе речь пойдёт о~различных вариантах понимания функций.
Мы~поговорим о~том, что называется ◊(Lisp1) и~◊(Lisp2),
в~чём разница между ними, что~такое отдельные пространства имён.
Заканчивается глава рассмотрением рекурсии и способов её реализации с~учётом изученных~вопросов.

◊(bigskip)

Программы имеют дело с~множеством типов объектов, среди которых функции занимают особое место.
Они создаются специальной формой ◊ic{lambda} и~поддерживают как минимум одну операцию: применение функции к~аргументам.
С~одной стороны это очень простой тип программных объектов,
с~другой стороны функции обладают невероятной гибкостью.
Благодаря этому функции являются прекрасным строительным блоком, инкапсулирующим поведение;
функция может делать только то, для чего она запрограммирована.
К~примеру, с~помощью функций можно представлять объекты, имеющие поля и методы ◊cite{ar88}.
В~Scheme очень популярно моделировать и строить программы вокруг функций.

◊phantomlabel{lisp1-2-omega/par:apval}
◊indexC{APVAL}
◊indexC{EXPR}
◊indexC{MACRO}
Попытки сделать вызовы функции более эффективными привели к~множеству (часто несовместимых) вариаций языка.
Изначально ◊(LISP)~1.5 ◊cite{mae+62} не~считал функции типом данных.
Реализация была такова, что переменная, функция и макрос могли одновременно носить одно и то~же имя,
так как хранились в~различных ячейках
(◊ic{APVAL}, ◊ic{EXPR} и ◊ic{MACRO}◊footnote{
  ◊ic{APVAL},~◊english{◊term{A~Permanent VALue}}, для~глобальных переменных;
  ◊ic{EXPR},~◊english{◊term{EXPRession}}, для~глобальных функций;
  ◊ic{MACRO}~для~макросов.
})
списка свойств соответствующего символа.

◊indexC{lambda!как ключевое слово}
Maclisp выделял именованные функции в~отдельную категорию,
а~его потомок ◊(CommonLisp)~◊cite{ste90} лишь недавно получил поддержку функций как объектов первого класса.
В~◊(CommonLisp) ◊ic{lambda} — это ключевое слово со~значением: «Следующий текст определяет анонимную функцию».
◊ic{lambda}-формы являются не~выражением в~полном смысле этого слова, а~скорее особенным синтаксисом.
Они не~имеют собственного значения и могут находиться лишь в~определённых местах:
как первый элемент формы вызова или как первый аргумент специальной формы~◊ic{function}.

◊indexR{объекты!первого класса}
◊indexR{объекты!полноценные}
◊indexR{первый класс (объектов)}
◊indexR{первый класс (объектов)|see{полноценные объекты}}
◊indexR{полноценные объекты}
Scheme~же с~самого начала — с~первой версии, выпущенной в~1975~году —
считает функции такими~же значениями, как и все остальные объекты в~программе.
Объекты ◊term{первого класса} (или ◊term{полноценные} объекты) являются значениями —
функции могут принимать их как аргументы и возвращать как результат вычислений,
объекты могут находиться в~списке, массиве, переменной, и~т.~д.
Подобный ◊emph{функциональный} подход широко распространён в~классе языков вроде~ML,
он~же будет использоваться и~здесь.
