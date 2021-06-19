% -*- coding: utf-8 -*-

◊section{Заключение}◊label{lisp1-2-omega/sect:conclusions}

В~этой главе мы прошлись по наиболее заметным из вопросов, на которые сообщество
Лиспа за последние несколько десятков лет так и не~смогло дать однозначного
ответа.
Рассмотрев причины данных разногласий, мы поняли, что они вовсе не~такие
серьёзные по своей сути.
Большая часть из них связана с~неоднозначностью
толкования смысла формы ◊ic{lambda} и различными способами применения функций.
Хотя идея функции достаточно хорошо проработана в~математике, но
в~функциональных~(!) языках вроде Лиспа это отнюдь не~так.
Различные мнения по
таким вопросам — это часть истории Лиспа.
Подобно изучению истории родного
народа, их знание облегчает понимание причин тех или иных решений в~дизайне
языка, а также улучшает стиль программирования в~общем.

Также данная глава демонстрирует существенную важность понятия связывания.
В~◊Lisp1 переменная (имя) ассоциируется с~уникальной привязкой (возможно
глобальной), которая в~свою очередь ассоциируется с~каким-либо значением.
Так
как привязка уникальна, то мы говорим о~значении переменной, а не~о~значении
привязки этой переменной.
Если рассматривать привязки как абстрактный тип
данных, то можно сказать, что объекты этого типа создаются связывающими формами,
их значение определяется вычислением, изменяются они присваиванием, и могут быть
захвачены при создании замыкания, если тело замыкания ссылается на переменную,
которая ассоциирована с~данной привязкой.

Привязки не~являются полноценными объектами.
Они не~существуют в~отрыве от
переменных и могут быть изменены только косвенно.
Собственно, привязки полезны
именно потому, что они крепко-накрепко связаны со~своими переменными.

◊indexR{форма!связывающая}
◊indexR{связывающие формы}
◊indexR{область видимости!лексическая}
Бок~о~бок со~связывающими формами следует идея областей видимости.
Область
видимости переменной — это пространство в~тексте программы, где можно
обращаться к~данной переменной.
Область видимости переменных, создаваемых
формой ◊ic{lambda}, ограничена телом данной формы.
Поэтому она называется
текстуальной или лексической.

Присваивание вносит множество неоднозначностей в~идею связывания, мы изучим этот
вопрос подробнее в~следующих главах.


◊section{Упражнения}◊label{lisp1-2-omega/sect:exercises}

◊begin{exercise}◊label{lisp1-2-omega/ex:funcall}
Следующее выражение записано на {◊CommonLisp}.
Как бы вы его перевели на~Scheme?

◊begin{code:lisp}
(funcall (function funcall) (function funcall) (function cons) 1 2)
◊end{code:lisp}
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:lexical}
Что вернёт данная программа на псевдо-{◊CommonLisp} из этой главы?
О~чём она вам напоминает?

◊begin{code:lisp}
(defun test (p)
  (function bar) )

(let ((f (test #f)))
  (defun bar (x) (cdr x))
  (funcall f '(1 .
2)) )
◊end{code:lisp}
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:innovations}
Реализуйте в~вашем интерпретаторе первые две инновации из
раздела~◊ref{lisp1-2-omega/sect:extensions}
◊seePage[lisp1-2-omega/sect:extensions].
Речь идёт о~трактовке чисел и
списков как функций.
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:assoc-with-comparator}
Можно научить функцию ◊ic{assoc/de} явно принимать компаратор (вроде ◊ic{eq?},
◊ic{equal?} {◊itp}) через аргумент, а не~задавать его внутри.
Сделайте это.
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:dynamic}
Используя ◊ic{bind/de} и ◊ic{assoc/de}, напишите макросы, эмулирующие
специальные формы ◊ic{dynamic-let}, ◊ic{dynamic} и~◊ic{dynamic-set!}.
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:write-put/get-prop}
◊indexC{putprop}◊indexC{getprop}
Напишите функции ◊ic{getprop} и ◊ic{putprop}, которые реализуют списки свойств.
Любой символ имеет личный список свойств в~виде пар «ключ — значение»;
добавление в~этот список осуществляет функция~◊ic{putprop}, поиск значения по
ключу осуществляет функция~◊ic{getprop}.
Также, естественно, должно выполняться
утверждение

◊begin{code:lisp}
(begin (putprop 'symbol 'key 'value)
       (getprop 'symbol 'key) )      |◊is| value
◊end{code:lisp}
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:label}
Определите специальную форму ◊ic{label} на ◊Lisp1.
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:labels}
Определите специальную форму ◊ic{labels} на ◊Lisp2.
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:orderless-letrec}
◊indexC{letrec}
Придумайте, как реализовать ◊ic{letrec} с~помощью ◊ic{let} и ◊ic{set!} так,
чтобы порядок вычисления значений"=инициализаторов был неопределённым.
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:fixn}
◊indexR{комбинаторы!неподвижной точки!универсальный}
У~нашего комбинатора неподвижной точки на Scheme обнаружился недостаток: он
поддерживает только унарные функции.
Реализуйте ◊ic{fix2}, работающий
с~бинарными функциями.
Затем ◊ic{fixN}, поддерживающий функции любой арности.
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:nfixn}
Далее напишите функцию ◊ic{NfixN}, возвращающую неподвижные точки для списка
функционалов произвольной арности.
Её можно использовать, например, следующим
образом:

◊begin{code:lisp}
(let ((odd-and-even
       (NfixN (list (lambda (odd? even?)    ; ◊ic{odd?}
                      (lambda (n)
                        (if (= n 0) #f (even? (- n 1))) ) )
                    (lambda (odd? even?)    ; ◊ic{even?}
                      (lambda (n)
                        (if (= n 0) #t (odd? (- n 1))) ) ) )) ))
  (set! odd? (car odd-and-even))
  (set! even? (cadr odd-and-even)) )
◊end{code:lisp}
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:klop}
Рассмотрим функцию ◊ic{klop}.
Является~ли она комбинатором неподвижной точки?
Попробуйте доказать или опровергнуть, что ◊ic{(klop $f$)} тоже возвращает
неподвижную точку~$f$ подобно~◊ic{fix}.

◊indexC{klop}
◊begin{code:lisp}
(define klop
  (let ((r (lambda (s c h e m)
             (lambda (f)
               (f (lambda (n)
                    (((m e c h e s) f) n) )) ) )))
    (r r r r r r) ) )
◊end{code:lisp}
◊end{exercise}

◊begin{exercise}◊label{lisp1-2-omega/ex:hyper-fact}
◊indexC{fact}
Если функция ◊ic{hyper-fact} определена так:

◊begin{code:lisp}
(define (hyper-fact f)
  (lambda (n)
    (if (= n 0) 1
        (* n ((f f) (- n 1))) ) ) )
◊end{code:lisp}

◊noindent
то что вернёт ◊ic{((hyper-fact hyper-fact)~5)}?
◊end{exercise}

◊section*{Рекомендуемая литература}%
◊label{lisp1-2-omega/sect:recommended-reading}

Кроме упомянутой ранее работы по $◊lambda$"=исчислению ◊cite{ss78a} также имеет
смысл почитать про анализ функций в~◊cite{mos70} и сравнительный анализ ◊Lisp1
и ◊Lisp2 в~◊cite{gp88}.

В~◊cite{gor88} есть интересное введение в~$◊lambda$"=исчисление.

Комбинатор ◊comb{Y} разбирается подробнее в~◊cite{gab88}.
