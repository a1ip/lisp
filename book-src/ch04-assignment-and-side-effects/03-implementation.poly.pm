#lang pollen

◊; TODO: довольно тупое название
◊section[#:label "assignment/sect:implementation"]{Реализация}

◊indexR{обмен сообщениями}
◊indexR{замыкания (closures)}
◊indexR{сообщения}
В~этой главе интерпретатор особенный — основной структурой данных здесь являются замыкания.
Все объекты будут представляться ◊ic{lambda}-формами, которые отправляют сообщения другим формам
и~разбирают входящие сообщения с~помощью уже знакомой вам идиомы ◊nobr{◊ic{(lambda (msg) (case msg ...))}}.
Некоторые сообщения будут универсальными для всех объектов.
Например, сообщение ◊ic{boolify} запрашивает у~объекта его булев эквивалент (то~есть ◊ic{#t}~или~◊ic{#f} для~нужд~◊ic{if}-форм),
а~в~ответ на~сообщение ◊ic{type} объект возвращает свой~тип.

Главной задачей нового интерпретатора является определение побочных эффектов.
Формально, переменная ссылается на~привязку, соответствующую значению этой переменной.
Говоря простым языком, переменная указывает на~коробку~(адрес), где находится её~значение.
Память — это всего лишь функция, которая вынимает значения из~коробок.
А~окружение — это функция, которая находит в~куче нужную коробку.
Звучит просто и понятно, но~реализация оказывается не~настолько простой.

◊indexR{вычисления!контекст}
◊indexR{контекст вычислений}
Память должна быть доступна отовсюду.
Можно было~бы сделать её глобальной переменной, однако такое решение не~вполне элегантно,
ведь вы знаете, сколько проблем и неоднозначностей таит в~себе глобальное окружение.
Другой подход — использовать локальные переменные:
то~есть передавать память как аргумент в~каждую функцию интерпретатора,
а~она передаст память другим функциями, возможно, немного изменив перед~этим.
При таком подходе вычисления описывается четвёркой из ◊term{выражения}, ◊term{окружения}, ◊term{продолжения} и~◊term{памяти}.
В~программе будем их коротко называть ◊ic{e},~◊ic{r},~◊ic{k},~◊ic{s}.

◊indexR{соглашения именования}
◊indexE{e@◊ic{e} (выражения)}
◊indexE{r@◊ic{r} (лексическое окружение)}
◊indexE{k@◊ic{k} (продолжения)}
◊indexE{v@◊ic{v} (значения)}
◊indexE{f@◊ic{f} (функции)}
◊indexE{n@◊ic{n} (идентификаторы)}
◊indexE{s@◊ic{s} (память)}
◊indexE{a@◊ic{a} (адреса)}
Как~обычно, функция ◊ic{evaluate} проводит синтаксический анализ выражения и вызывает соответствующую функцию-вычислитель.
Не~будем нарушать установленную в~предыдущих главах традицию именования сущностей, лишь расширим список новыми~типами:

◊; TODO: форматирование таблицы
◊table{
  ◊tr{◊td{◊ic{e}, ◊ic{et}, ◊ic{ec}, ◊ic{ef}} ◊td{выражения, формы}}
  ◊tr{◊td{◊ic{r}}                            ◊td{окружения}       }
  ◊tr{◊td{◊ic{k}, ◊ic{kk}}                   ◊td{продолжения}     }
  ◊tr{◊td{◊ic{v}, ◊ic{void}}                 ◊td{значения}        }
  ◊tr{◊td{◊ic{f}}                            ◊td{функции}         }
  ◊tr{◊td{◊ic{n}}                            ◊td{идентификаторы}  }
  ◊tr{◊td{◊ic{s}, ◊ic{ss}, ◊ic{sss}}         ◊td{память}          }
  ◊tr{◊td{◊ic{a}, ◊ic{aa}}                   ◊td{адреса (коробки)}}
}

При~таком разнообразии аргументов в~них легко запутаться.
Отныне мы будем всегда перечислять аргументы в~следующем порядке:
◊ic{e},~◊ic{r},~◊ic{s}, и~наконец~◊ic{k}.

Итак, ядро интерпретатора:

◊indexC{evaluate}
◊code:lisp{
(define (evaluate e r s k)
  (if (atom? e)
      (if (symbol? e) (evaluate-variable e r s k)
          (evaluate-quote e r s k) )
      (case (car e)
        ((quote)  (evaluate-quote       (cadr e) r s k))
        ((if)     (evaluate-if          (cadr e) (caddr e) (cadddr e) r s k))
        ((begin)  (evaluate-begin       (cdr e) r s k))
        ((set!)   (evaluate-set!        (cadr e) (caddr e) r s k))
        ((lambda) (evaluate-lambda      (cadr e) (cddr e) r s k))
        (else     (evaluate-application (car e) (cdr e) r s k)) ) ) )
}
