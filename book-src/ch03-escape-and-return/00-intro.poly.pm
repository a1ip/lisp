#lang pollen

◊chapter[#:label "chapter:escape"]{Переходы~и~возвраты: продолжения}

◊initial{Каждое вычисление} в~конечном счёте приводит к~возврату результата сущности, называемой ◊term{продолжением}.
Эта глава посвящена идее продолжений и её историческим предпосылкам.
Мы также создадим ещё один интерпретатор, явно оперирующий продолжениями.
В~процессе мы рассмотрим различные варианты реализации продолжений в~Лиспе и Scheme,
а~также своеобразный «стиль передачи продолжений».
Одним из отличий Лиспа от других языков является большое количество механизмов управления ходом вычислений.
Это в~некотором смысле превращает данную главу в~каталог,
◊cite{moz87}
где представлена тысяча~и~одна управляющая конструкция.
С~другой стороны, мы не~будем чересчур вдаваться в~подробности о~продолжениях;
по~крайней мере, о~том, как физически реализуется их захват и сохранение.
Наш интерпретатор будет использовать объекты для представления продолжений в~виде ◊term{стека~вызовов}.

◊(bigskip)

◊indexR{переходы (escapes)}
Интерпретаторам, построенным нами ранее, было необходимо только окружение, чтобы вычислить значение переданного выражения.
К~сожалению, они не~в~состоянии проводить вычисления, в~которых есть ◊term{переходы} (◊english{escapes}) —
полезная управляющая конструкция, позволяющая покинуть текущий контекст исполнения, чтобы перейти в~другой, более подходящий.
Обычно они используются для обработки исключительных ситуаций,
когда мы указываем, куда следует перейти для обработки события или ошибки, прервавшей нормальный ход вычислений.

◊indexC{prog}
◊indexC{goto}
История переходов в~Лиспе восходит ко~временам ◊LISP-1.5 и формы~◊ic{prog}.
Сейчас эта форма считается устаревшей,
но раньше на неё возлагались большие надежды по переманиванию программистов на~Алголе в~ряды лисперов,
так как считалось, что для них было более привычным использование ◊ic{goto}.
Вместо этого оказалось, что данная форма тлетворным образом влияет на самих лисперов,
распространяет еретические идеи, сталкивая праведников с~пути хвостовой рекурсии.
◊footnote{Например, сравните стили изложения первого и третьего изданий~◊cite{wh89}.}
Тем не~менее, форма ◊ic{prog} достойна рассмотрения, потому как обладает несколькими интересными свойствами.
Например, вот так с~её помощью записывается факториал:

◊indexC{fact}
◊code:lisp[#:dialect CommonLisp]{
(defun fact (n)
  (prog (r)
            (setq r 1)
       loop (cond ((= n 1) (return r)))
            (setq r (* n r))
            (setq n (- n 1))
            (go loop) ) )
}

Специальная форма ◊ic{prog} сначала объявляет все используемые локальные переменные (в~данном случае это~◊ic{r}).
Далее следуют инструкции (представляемые списками) и метки (представляемые символами).
Инструкции последовательно вычисляются, как в~◊ic{progn}.
Результатом вычисления формы ◊ic{prog} по умолчанию является ◊ic{nil}.
Внутри ◊ic{prog} можно использовать специальные инструкции.
Безусловные переходы выполняются с~помощью ◊ic{go} (которая принимает символ — имя метки),
а~вернуть определённое значение из ◊ic{prog} можно с~помощью ◊ic{return}.
В~◊LISP-1.5 существовало лишь одно ограничение:
формы ◊ic{go} и ◊ic{return} могли появляться только на первом уровне вложенности или внутри ◊ic{cond} на том~же первом уровне.

Форма ◊ic{return} позволяет выйти из ◊ic{prog}, забрав с~собой результат вычислений.
Ограничение ◊LISP-1.5 допускало лишь простые переходы;
в~более поздних версиях это ограничение было снято, что позволило реализовать более изощрённые варианты поведения.
Переходы стали обычным способом обработки ошибок.
Если происходила ошибка, то выполнение переходило из ошибочного контекста исполнения в~безопасный для обработки возникшей ситуации.
Теперь можно переписать факториал следующим образом, поместив ◊ic{return} глубже:

◊code:lisp[#:dialect CommonLisp]{
(defun fact2 (n)
  (prog (r)
            (setq r 1)
       loop (setq r (* (cond ((= n 1) (return r))
                             ('else n) )
                       r ))
            (setq n (- n 1))
            (go loop) ) )
}

◊indexR{управляющие конструкции}
Если рассматривать формы ◊ic{prog} и ◊ic{return} как управляющие конструкции,
то становится ясно, что они влияют на последовательность вычислений подобно функциям:
выполнение функции начинается переходом к~её телу и заканчивается возвратом результата в~то место, откуда функция была вызвана.
Только в~нашем случае внутри формы ◊ic{prog} известно, куда требуется вернуть значение — она сама связывает ◊ic{return} с~этим местом.
Для перехода не~важно, откуда мы уходим, но необходимо знать, куда мы хотим попасть.

Если такой ◊emph{прыжок} эффективно реализован, то~это порождает жизнеспособную парадигму программирования.
Например, пусть стоит задача проверить вхождение элемента в~двоичное дерево.
В~лоб эта задача решается примерно таким способом:

◊; TODO: ◊indexC после ! не должно превращаться в идентификтор? или должно?
◊indexC{find-symbol!обычная}
◊code:lisp{
(define (find-symbol id tree)
  (if (pair? tree)
      (or (find-symbol id (car tree))
          (find-symbol id (cdr tree)) )
      (eq? tree id) ) )
}

Допустим, мы ищем ◊ic{foo} в~следующем дереве:

◊code:lisp{
(((a . b) . (foo . c)) . (d . e))
}

Так как поиск идёт слева направо и в~глубину, то после того, как нужный символ будет найден,
нам ещё предстоит подниматься обратно по вложенным~◊ic{or}, неся с~собой вожделенную~◊ic{#t},
которая в~конце концов станет результатом вычислений.
Вот как это происходит:

◊; TODO: стрелки
◊code:lisp{
(find-symbol 'foo '(((a . b) . (foo . c)) . (d . e)))
≡ (or (find-symbol 'foo '((a . b) . (foo . c)))
      (find-symbol 'foo '(d . e)) )
≡ (or (or (find-symbol 'foo '(a . b))
          (find-symbol 'foo '(foo . c)) )
       (find-symbol 'foo '(d . e)) )
≡ (or (or (or (find-symbol 'foo 'a)
              (find-symbol 'foo 'b) )
          (find-symbol 'foo '(foo . c)) )
      (find-symbol 'foo '(d . e)) )
≡ (or (or (find-symbol 'foo 'b)
          (find-symbol 'foo '(foo . c)) )
      (find-symbol 'foo '(d . e)) )
≡ (or (find-symbol 'foo '(foo . c))
      (find-symbol 'foo '(d . e)) )
≡ (or (or (find-symbol 'foo 'foo)
          (find-symbol 'foo 'c) )
      (find-symbol 'foo '(d . e)) )
≡ (or (or #t
          (find-symbol 'foo 'c) )
      (find-symbol 'foo '(d . e)) )
≡ (or #t
      (find-symbol 'foo '(d . e)) )
≡ #t
}

Как раз здесь~бы не~помешал эффективно реализованный переход сразу к~последней строке.
Как только мы находим нужный символ, то могли бы сразу вернуть результат,
а~не~продираться обратно через вложенные ◊ic{or} или заглядывать в~другие ветки.

◊indexR{исключения}
Другим примером может быть обработка исключительных ситуаций.
Некоторые программы постоянно выполняют некоторые действия в~цикле.
Цикл продолжает выполняться до тех пор, пока не~возникает исключительная ситуация,
для обработки которой необходимо немедленно прервать весь цикл.
Нечто подобное реализует функция ◊ic{better-map}, рассматриваемая чуть позже.
◊seePage{escape/forms/catch-vs-block/p:better-map}

◊indexR{продолжения (continuations)}
Размышляя над природой сущности, представляющей точку входа в~функцию,
можно прийти к~выводу, что понятие вычислений подразумевает не~только выражение, которое необходимо вычислить,
и~окружение, в~котором будут проходить вычисления,
но также и цель вычислений — нечто, куда необходимо вернуть полученный результат.
Это нечто называется ◊term{продолжением} (◊english{continuation}).
То,~что программа продолжит делать, получив результат вычислений.

У~любого вычисления есть продолжение.
Например, в~выражении ◊nobr{◊ic{(+ 3 (* 2 4))}} продолжением подвыражения ◊nobr{◊ic{(* 2 4)}} будет сложение,
где первый аргумент это~◊ic{3}, а второй ожидается в~результате вычислений.
Здесь можно заметить параллели и представить продолжения в~более привычной форме — как функции.
Ведь продолжения тоже представляют некоторые вычисления и, как и функции, тоже требуют, чтобы сначала были вычислены все необходимые параметры.
Для предыдущего примера продолжением ◊nobr{◊ic{(* 2 4)}} будет функция ◊nobr{◊ic{(lambda (◊ii{x}) (+ 3 ◊ii{x}))}},
подчёркивающая тот факт, что вычисление ожидает второй аргумент для сложения.

Продолжения можно записывать и проще, в~духе ◊${\lambda}-исчисления.
Мы будем записывать предыдущее продолжение как ◊nobr{◊ic{(+ 3 [])}},
где ◊ic{[]} означает место, куда необходимо подставить результат вычислений.

Действительно, у~любой формы есть продолжение.
Вычисление условного выражения в~формах ветвления проводится для продолжения,
которое ожидает это значение, чтобы выбрать ту или иную ветку условной формы.
В~выражении ◊nobr{◊ic{(if (foo) 1 2)}} продолжением вызова ◊ic{(foo)}
является ◊nobr{◊ic{(lambda (◊ii{x}) (if ◊ii{x} 1 2))}} или ◊nobr{◊ic{(if [] 1~2)}}.

Переходы, исключения и тому подобные механизмы — это лишь частные случаи манипуляции продолжениями.
Имея это в~виду, давайте рассмотрим в~деталях различные варианты использования продолжений,
которые были придуманы за последние тридцать с~лишним~лет.
