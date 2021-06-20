#lang pollen

◊chapter[#:label "chapter:basics"]{Основы интерпретации}

◊initial{В этой главе} описывается базовый интерпретатор, идеи которого проходят красной нитью через большую часть книги.
Он~намеренно сделан простым и более близким к~Scheme, чем к~Лиспу,
что позволит нам в~дальнейшем описывать Лисп в~терминах Scheme.
Мы~коснёмся следующих тем в~этой вводной главе:
сути~интерпретации;
известной пары функций ◊ic{eval}~и~◊ic{apply};
свойств окружений и функций.
В~общем, познакомимся с~вопросами, которые будем изучать подробнее в~следующих главах,
надеясь, что вас не~отпугнёт пропасть незнания по обе стороны моста, которым мы~пойдём.

◊(bigskip)

Интерпретатор и его варианты будут написаны на Scheme без использования каких-либо существенных особенностей этого диалекта.

В~книгах по Лиспу редко когда отказываются от нарциссического соблазна описать Лисп с~помощью Лиспа.
Начало традиции положило первое руководство по ◊|LISP-1.5|~◊cite{mae+62}
и впоследствии такой подход широко распространился.
Вот лишь малая часть существующих примеров:
◊cite{rib69}, ◊cite{gre77}, ◊cite{que82}, ◊cite{cay83}, ◊cite{cha80},  ◊cite{sj93},
◊cite{rey72}, ◊cite{gor75}, ◊cite{ss75},  ◊cite{all78}, ◊cite{mcc78b}, ◊cite{lak80},
◊cite{hen80}, ◊cite{bm82} , ◊cite{cli84}, ◊cite{fw84},  ◊cite{drs84},  ◊cite{as85},
◊cite{r3r86}, ◊cite{mas86}, ◊cite{dyb87}, ◊cite{wh89},  ◊cite{kes88},  ◊cite{lf88},
◊cite{dil88}, ◊cite{kam90}.

Эти интерпретаторы довольно сильно разнятся:
как~языками, которые они реализуют и используют для реализации,
так~и, что более важно, целями, которые они преследуют.
Интерпретатор из~◊cite{lak80} показывает, как объекты и концепции компьютерной графики естественным образом реализуются на~Лиспе;
а~интерпретатор, описываемый в~◊cite{bm82}, создан для явного замера сложности интерпретируемых программ.

◊indexR{язык!реализации}
◊indexR{язык!реализуемый}
Язык, ◊emph{используемый} для реализации, тоже играет немалую роль.
Если в~нём есть присваивание и доступ к~памяти (◊ic{set-car!} и ◊ic{set-cdr!}),
это даёт бо́льшую свободу реализации и делает исходный код интерпретатора более компактным.
Мы~получаем возможность описать язык в~терминах, которые близки к~машинным инструкциям.
Несмотря на то, что такое описание в~целом непростым для понимания,
каждая отдельная строка является очень простой и не~возникает никаких сомнений в~том, что именно она делает.
Даже если подобное описание занимает больше места, чем высокоуровневое,
оно даёт более точное понимание смысла происходящего при интерпретации — для нас важно именно~это.

◊figure[#:label "basics/fig:richness-plot"]{
◊caption{Уровни сложности.}
◊; TODO: ◊input{figures/fig1.1}
}

На~рисунке~◊ref{basics/fig:richness-plot} приведено сравнение уровней сложности
определяющего~(по~оси~◊${x}) и определяемого~(по~оси~◊${y}) языков для некоторых из~интерпретаторов.
Здесь хорошо виден ход развития человеческих знаний со~временем:
всё более сложные проблемы решаются с~использованием всё более ограниченных возможностей.
Эта книга соответствует вектору, который начинается использованием высокоуровневого Лиспа для реализации Scheme,
а~заканчивается реализацией высокоуровневого Лиспа с~помощью одного лишь~◊${\lambda}-исчисления.
