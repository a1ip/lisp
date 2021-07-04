#lang pollen

◊section*[#:label "lisp1-2-omega/sect:conclusions"]{Заключение}

В~этой главе мы прошлись по наиболее заметным из вопросов,
на которые сообщество Лиспа за последние несколько десятков лет так и не~смогло дать однозначного ответа.
Рассмотрев причины данных разногласий, мы поняли, что они вовсе не~такие уж и существенные.
Большая часть из них связана с~неоднозначностью толкования смысла формы ◊ic{lambda},
а~также различными способами применения функций.
Хотя идея функции достаточно хорошо проработана в~математике,
в~функциональных~(!) языках вроде Лиспа это отнюдь не~так.
Различные мнения по таким вопросам — это часть культуры и истории Лиспа.
Подобно изучению истории родного народа, осознание и принятие таких различий облегчает понимание причин тех или иных решений в~дизайне языка,
а~также улучшает стиль программирования в~целом.

Кроме того, мы показали важность понятия связывания.
В~◊Lisp-1 переменная (имя) ассоциируется с~уникальной привязкой (возможно глобальной),
которая в~свою очередь ассоциируется с~каким-либо значением.
Так как привязка уникальна, то мы говорим о~значении переменной, а~не~о~значении привязки этой переменной.
Если рассматривать привязки как абстрактный тип данных, то можно сказать, что
объекты этого типа создаются связывающими формами,
их значение определяется вычислением,
изменяются они присваиванием,
и~могут быть захвачены при создании замыкания,
если тело замыкания ссылается на переменную, которая ассоциирована с~данной привязкой.

Привязки не~являются полноценными объектами языка.
Они не~существуют в~отрыве от переменных и используются только косвенно, посредством переменных.
Также привязки имеют неограниченное время жизни; на~самом деле, именно этим они и~полезны.

◊indexR{форма!связывающая}
◊indexR{связывающие формы}
◊indexR{область видимости!лексическая}
Бок~о~бок со~связывающими формами следует идея областей видимости.
Область видимости переменной — это пространство в~тексте программы, где можно обращаться к~данной переменной.
Область видимости переменных, создаваемых формой ◊ic{lambda}, ограничена телом этой формы.
Поэтому такая область видимости называется текстуальной или лексической.

Присваивание вносит множество неоднозначностей в~идею связывания,
мы изучим этот вопрос подробнее в~следующих главах.
